# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

$commitOutput = $null
$repoRoot = $null

function Init {
    $Global:Error.Clear()
    $Script:commitOutput = $null
    $Script:repoRoot = $null
}

function GivenRepository {
    $Script:repoRoot = Join-Path -Path $TestDrive.FullName -ChildPath 'repo'
    New-GitRepository -Path $repoRoot | Out-Null
}

function GivenBranch {
    param(
        $Name
    )

    New-GitBranch -RepoRoot $repoRoot -Name $Name
}

function GivenCommit {
    param(
        [int]
        $NumberOfCommits = 1
    )

    1..$NumberOfCommits | ForEach-Object {
        $filePath = Join-Path -Path $repoRoot -ChildPath ([System.IO.Path]::GetRandomFileName())
        [Guid]::NewGuid() | Set-Content -Path $filePath -Force
        Add-GitItem -Path $filePath -RepoRoot $repoRoot | Out-Null
        Save-GitCommit -Message 'Get-GitCommit Tests' -RepoRoot $repoRoot | Out-Null
    }
}

function GivenHeadIs {
    param(
        $Revision
    )

    Update-GitRepository -RepoRoot $repoRoot -Revision $Revision
}

function AddMerge {
    try {
        # Temporary until we get merge functionality in this module
        $repo = Find-GitRepository -Path $repoRoot

        $testBranch = 'GitCommitTestBranch'
        New-GitBranch -RepoRoot $repoRoot -Name $testBranch

        GivenCommit -NumberOfCommits 1
        [LibGit2Sharp.Commands]::Checkout($repo, 'master', [LibGit2Sharp.CheckoutOptions]::new())

        $mergeOptions = [LibGit2Sharp.MergeOptions]::new()
        $mergeOptions.FastForwardStrategy = 'NoFastForward'
        $mergeSignature = [LibGit2Sharp.Signature]::new('test', 'email@example.com', ([System.DateTimeOffset]::Now))

        $repo.Merge($testBranch, $mergeSignature, $mergeOptions)
    } finally {
        $repo.Dispose()
    }
}

function AddTag {
    param(
        $Tag
    )

    New-GitTag -RepoRoot $repoRoot -Name $Tag
}

function WhenGettingCommit {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All,

        [Parameter(ParameterSetName = 'Lookup')]
        [string]
        $Revision,

        [Parameter(ParameterSetName = 'CommitFilter')]
        [string]
        $Since = 'HEAD',

        [Parameter(ParameterSetName = 'CommitFilter')]
        [string]
        $Until,

        [Parameter(ParameterSetName = 'CommitFilter')]
        [switch]
        $NoMerges
    )

    if ($PSCmdlet.ParameterSetName -eq 'All') {
        $Script:commitOutput = Get-GitCommit -RepoRoot $repoRoot -All
    } elseif ($PSCmdlet.ParameterSetName -eq 'Lookup') {
        $Script:commitOutput = Get-GitCommit -RepoRoot $repoRoot -Revision $Revision
    } elseif ($PSCmdlet.ParameterSetName -eq 'CommitFilter') {
        $Script:commitOutput = Get-GitCommit -RepoRoot $repoRoot -Since $Since -Until $Until -NoMerges:$NoMerges
    } else {
        Push-Location $repoRoot
        try {
            $Script:commitOutput = Get-GitCommit
        } finally {
            Pop-Location
        }
    }
}

function ThenCommitIsHeadCommit {
    It 'should return the current HEAD commit' {
        $commitOutput.Sha | Should -Be (Get-Content -Path (Join-Path -Path $repoRoot -ChildPath '.git\refs\heads\master'))
    }
}

function ThenNumberCommitsReturnedIs {
    param(
        [int]
        $NumberOfCommits
    )

    $commitsReturned = $commitOutput | Measure-Object | Select-Object -ExpandProperty 'Count'
    It 'should return the correct number of commits' {
        $commitsReturned | Should -Be $NumberOfCommits
    }
}

function ThenReturned {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Type')]
        $Type,
        [Parameter(Mandatory = $true, ParameterSetName = 'Nothing')]
        [switch]
        $Nothing
    )

    if ($Nothing) {
        It 'should not return anything' {
            $commitOutput | Should -BeNullOrEmpty
        }
    } else {
        It 'should return the correct object type' {
            $commitOutput | Should -BeOfType $Type
        }
    }
}

function ThenErrorMessage {
    param(
        $Message
    )

    It ('should write error /{0}/' -f $Message) {
        $Global:Error[0] | Should -Match $Message
    }
}

function ThenNoErrorMessages {
    It 'should not write any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Get-GitCommit.when no parameters specified' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 2
    WhenGettingCommit
    ThenReturned -Type [PowerGit.CommitInfo]
    ThenNumberCommitsReturnedIs 2
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting all commits' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 5
    GivenHeadIs 'master'
    GivenBranch 'somebranch'
    GivenCommit -NumberOfCommits 5
    GivenHeadIs 'master'
    GivenBranch 'someotherbranch'
    GivenCommit -NumberOfCommits 5
    WhenGettingCommit -All
    ThenReturned -Type [PowerGit.CommitInfo]
    ThenNumberCommitsReturnedIs 15
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting specifically the current HEAD commit' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 3
    WhenGettingCommit -Revision 'HEAD'
    ThenReturned -Type [PowerGit.CommitInfo]
    ThenNumberCommitsReturnedIs 1
    ThenCommitIsHeadCommit
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting a commit that does not exist' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 1
    WhenGettingCommit -Revision 'nonexistentcommit' -ErrorAction SilentlyContinue
    ThenReturned -Nothing
    ThenErrorMessage 'Commit ''nonexistentcommit'' not found in repository'
}

Describe 'Get-GitCommit.when getting commit list with an invalid commit' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 1
    WhenGettingCommit -Since 'HEAD' -Until 'nonexistentcommit' -ErrorAction SilentlyContinue
    ThenReturned -Nothing
    ThenErrorMessage 'Commit ''nonexistentcommit'' not found in repository'
}

Describe 'Get-GitCommit.when Since and Until are the same commit' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 1
    AddTag '1.0'
    WhenGettingCommit -Since 'HEAD' -Until '1.0' -ErrorAction SilentlyContinue
    ThenReturned -Nothing
    ThenErrorMessage 'Commit reference ''HEAD'' and ''1.0'' refer to the same commit'
}

Describe 'Get-GitCommit.when getting all commits until a specific commit' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 1
    AddTag '1.0'
    GivenCommit -NumberOfCommits 3
    WhenGettingCommit -Until '1.0'
    ThenReturned -Type [PowerGit.CommitInfo]
    ThenNumberCommitsReturnedIs 3
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting list of commits between two specific commits' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 1
    AddTag '1.0'
    GivenCommit -NumberOfCommits 2
    AddMerge # Adds 2 commits (regular + merge commit)
    AddTag '2.0'
    GivenCommit -NumberOfCommits 1
    WhenGettingCommit -Since '2.0' -Until '1.0'
    ThenReturned -Type [PowerGit.CommitInfo]
    ThenNumberCommitsReturnedIs 4
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting list of commits with excluding merge commits' {
    Init
    GivenRepository
    GivenCommit -NumberOfCommits 1
    AddTag '1.0'
    GivenCommit -NumberOfCommits 2
    AddMerge # Adds 2 commits (regular + merge commit)
    AddTag '2.0'
    GivenCommit -NumberOfCommits 1
    WhenGettingCommit -Since '2.0' -Until '1.0' -NoMerges
    ThenReturned -Type [PowerGit.CommitInfo]
    ThenNumberCommitsReturnedIs 3
    ThenNoErrorMessages
}
