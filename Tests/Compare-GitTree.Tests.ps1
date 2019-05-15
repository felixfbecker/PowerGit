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

[LibGit2Sharp.TreeChanges]$diffOutput = $null
[string]$repoRoot = $null

function Init {
    $Global:Error.Clear()
    $script:diffOutput = $null
    $script:repoRoot = $null
}

function GivenACommit {
    param(
        $ThatAdds,
        $ThatModifies
    )

    if ($ThatAdds) {
        Add-GitTestFile -RepoRoot $repoRoot -Path $ThatAdds
        Add-GitItem -RepoRoot $repoRoot -Path $ThatAdds
    }

    if ($ThatModifies) {
        [Guid]::NewGuid() | Select-Object -ExpandProperty Guid | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath $ThatModifies) -Force
    Add-GitItem -RepoRoot $repoRoot -Path $ThatModifies
}

Save-GitCommit -RepoRoot $repoRoot -Message 'Compare-GitTree tests commit'
}

function GivenARepository {
    $script:repoRoot = Join-Path -Path $testDir.FullName -ChildPath 'repo'
    New-GitRepository -Path $repoRoot | Out-Null

Add-GitTestFile -RepoRoot $repoRoot -Path 'InitialCommit.txt'
Add-GitItem -RepoRoot $repoRoot -Path 'InitialCommit.txt'
Save-GitCommit -RepoRoot $repoRoot -Message 'Initial Commit'
}

function GivenTag {
    param(
        $Tag
    )

    New-GitTag -RepoRoot $repoRoot -Name $Tag
}

function WhenGettingDiff {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'RepositoryRoot')]
        [switch]
        $GivenRepositoryRoot,

        [Parameter(Mandatory)]
        [string]
        $ReferenceRevision,

        [string]
        $DifferenceRevision
    )

    $DifferenceRevisionParam = @{ }
    if ($DifferenceRevision) {
        $DifferenceRevisionParam['DifferenceRevision'] = $DifferenceRevision
    }

    if ($GivenRepositoryRoot) {
        $script:diffOutput = Compare-GitTree -RepoRoot $repoRoot -ReferenceRevision $ReferenceRevision @DifferenceRevisionParam
    } else {
        Push-Location -Path $repoRoot
        try {
            $result = Compare-GitTree -ReferenceRevision $ReferenceRevision @DifferenceRevisionParam
            if ($result) {
                $script:diffOutput = $result
            }
        } finally {
            Pop-Location
        }
    }
}

function ThenDidNotDisposeRepoObject {
    It 'should not dispose the repository object' {
        Assert-MockCalled -CommandName 'Invoke-Command' -ModuleName 'PowerGit' -ParameterFilter { $ScriptBlock.ToString() -match 'Dispose' } -Times 0
    }
}

function ThenDiffCount {
    param(
        [int]
        $Added,
        [int]
        $Deleted,
        [int]
        $Modified,
        [int]
        $Renamed
    )

    It 'diff object should represent the correct amount of changes' {
        ($diffOutput.Added | Measure-Object).Count | Should -Be $Added
($diffOutput.Deleted | Measure-Object).Count | Should -Be $Deleted
($diffOutput.Modified | Measure-Object).Count | Should -Be $Modified
($diffOutput.Renamed | Measure-Object).Count | Should -Be $Renamed
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

function ThenReturned {
    param(
        [Parameter(Mandatory, ParameterSetName = 'Type')]
        $Type,
        [Parameter(Mandatory, ParameterSetName = 'Nothing')]
        [switch]
        $Nothing
    )

    if ($Nothing) {
        It 'should not return anything' {
            $diffOutput | Should -BeNullOrEmpty
    }
} else {
    It 'should return the correct object type' {
        , $diffOutput | Should -BeOfType $Type
}
}
}

Describe 'Compare-GitTree.when when a commit does not exist' {
    Init
    GivenARepository
    WhenGettingDiff -ReferenceRevision 'nonexistentcommit' -ErrorAction SilentlyContinue
    ThenReturned -Nothing
    ThenErrorMessage 'Revision ''nonexistentcommit'' not found in repository'
}

Describe 'Compare-GitTree.when getting diff between HEAD and its parent commit in the current directory repository' {
    Init
    GivenARepository
    GivenACommit -ThatAdds 'file1.txt'
    WhenGettingDiff -ReferenceRevision 'HEAD^'
    ThenReturned -Type [LibGit2Sharp.TreeChanges]
    ThenDiffCount -Added 1
    ThenNoErrorMessages
}

Describe 'Compare-GitTree.when getting diff between HEAD and its parent commit for the given repository path' {
    Init
    GivenARepository
    GivenACommit -ThatAdds 'file1.txt'
    WhenGettingDiff -GivenRepositoryRoot -ReferenceRevision 'HEAD^'
    ThenReturned -Type [LibGit2Sharp.TreeChanges]
    ThenDiffCount -Added 1
    ThenNoErrorMessages
}

Describe 'Compare-GitTree.when getting diff between two specific commits' {
    Init
    GivenARepository
    GivenACommit -ThatAdds 'file1.txt', 'file2.txt'
    GivenTag '1.0'
    GivenACommit -ThatModifies 'file2.txt'
    GivenACommit -ThatAdds 'file3.txt'
    GivenTag '2.0'
    GivenACommit -ThatAdds 'fileafter2.0.txt'
    WhenGettingDiff -ReferenceRevision '1.0' -DifferenceRevision '2.0'
    ThenReturned -Type [LibGit2Sharp.TreeChanges]
    ThenDiffCount -Added 1 -Modified 1
    ThenNoErrorMessages
}
