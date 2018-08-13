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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

$remoteRepoRoot = $null
$remoteWorkingRoot = $null
$localRoot = $null

function GivenBranch {
    param(
        [string]
        $Name,

        [Switch]
        $InRemote,

        [Switch]
        $InLocal
    )

    if ( $InRemote ) {
        $repoRoot = $remoteWorkingRoot
    } else {
        $repoRoot = $localRoot
    }

    New-GitBranch -RepoRoot $repoRoot -Name $Name | Out-Null

    if ( $InRemote ) {
        Send-GitCommit -RepoRoot $repoRoot
    }
}

function GivenCommit {
    param(
        [Switch]
        $InRemote,

        [Switch]
        $InLocal,

        [string]
        $OnBranch
    )

    if ( $InRemote ) {
        $repoRoot = $remoteWorkingRoot
        $prefix = 'remote'
    } else {
        $repoRoot = $localRoot
        $prefix = 'local'
    }

    if ( $OnBranch ) {
        Update-GitRepository -RepoRoot $repoRoot -Revision $OnBranch | Out-Null
    }

    $filename = '{0}-{1}' -f $prefix, [IO.Path]::GetRandomFileName()
    Add-GitTestFile -RepoRoot $repoRoot -Path $filename | Out-Null
    Add-GitItem -RepoRoot $repoRoot -Path $filename
    Save-GitCommit -RepoRoot $repoRoot -Message $filename

    if ( $InRemote ) {
        Send-GitCommit -RepoRoot $remoteWorkingRoot | Out-Null
    }
}

function GivenLocalRepoIs {
    param(
        [Switch]
        $ClonedFromRemote,

        [Switch]
        $Standalone
    )

    $script:localRoot = Join-Path -Path $TestDrive -ChildPath ('Local.{0}' -f [IO.Path]::GetRandomFileName())
    if ( $ClonedFromRemote ) {
        Copy-GitRepository -Source $remoteRepoRoot -DestinationPath $localRoot
    } else {
        New-GitRepository -Path $localRoot
    }
}

function Init {
    param(
    )

    $script:remoteRepoRoot = Join-Path -Path $TestDrive -ChildPath 'Remote.Bare'
    New-GitRepository -Path $remoteRepoRoot -Bare

    $script:remoteWorkingRoot = Join-Path -Path $TestDrive.FullName -ChildPath 'Remote.Working'
    Copy-GitRepository -Source $remoteRepoRoot -DestinationPath $remoteWorkingRoot

    Add-GitTestFile -RepoRoot $remoteWorkingRoot -Path 'InitialCommit.txt'
    Add-GitItem -RepoRoot $remoteWorkingRoot -Path 'InitialCommit.txt'
    Save-GitCommit -RepoRoot $remoteWorkingRoot -Message 'Initial Commit'
    Send-GitCommit -RepoRoot $remoteWorkingRoot
}

function ThenNoErrorsWereThrown {
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenErrorWasThrown {
    param(
        [string]
        $ErrorMessage
    )

    It ('should throw an error: ''{0}''' -f $ErrorMessage) {
        $Global:Error | Should Match $ErrorMessage
    }
}

function ThenLocalHead {
    param(
        $CanonicalName,
        $Tracks
    )

    $repo = Get-GitRepository -RepoRoot $localRoot
    try {
        [LibGit2Sharp.Branch]$localHead = $repo.Branches | Where-Object { $_.CanonicalName -eq $CanonicalName }
        It ('should setup correct tracking branches') {
            $localHead | Should -Not -BeNullOrEmpty
            $localHead.IsTracking | Should -Be $true
            $localHead.TrackedBranch.CanonicalName | Should -Be $Tracks
        }
    } finally {
        $repo.Dispose()
    }
}

function ThenRemoteRevision {
    param(
        [string]
        $Revision,

        [Switch]
        $Exists,

        [Switch]
        $DoesNotExist
    )

    $commitExists = Test-GitCommit -RepoRoot $remoteRepoRoot -Revision $Revision
    if ( $Exists ) {
        It ('should push branch to remote') {
            $commitExists | Should -BeTrue
        }
    } else {
        It ('should not push other branches') {
            $commitExists | Should -BeFalse
        }
    }
}

function ThenPushResultIs {
    param(
        $PushStatus
    )

    It ('function returned status of ''{0}''' -f $script:pushResult) {
        $script:pushResult | Should Be $PushStatus
    }
}

function WhenSendingCommits {
    [CmdletBinding()]
    param(
        [Switch]
        $SetUpstream
    )

    $Global:Error.Clear()
    $script:pushResult = $null

    $script:pushResult = Send-GitCommit -RepoRoot $localRoot -SetUpstream:$SetUpstream #-ErrorAction SilentlyContinue
}

Describe 'Send-GitCommit.when pushing changes to a remote repository' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    $commit = GivenCommit -InLocal
    WhenSendingCommits
    ThenNoErrorsWereThrown
    ThenPushResultIs ([PowerGit.PushResult]::Ok)
    ThenRemoteRevision $commit.Sha -Exists
}

Describe 'Send-GitCommit.when there are no local changes to push to remote' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    WhenSendingCommits
    ThenNoErrorsWereThrown
    ThenPushResultIs ([PowerGit.PushResult]::Ok)
}

Describe 'Send-GitCommit.when remote repository has changes not contained locally' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    GivenCommit -InRemote
    GivenCommit -InLocal
    WhenSendingCommits -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'that you are trying to update on the remote contains commits that are not present locally.'
    ThenPushResultIs ([PowerGit.PushResult]::Rejected)
}

Describe 'Send-GitCommit.when no upstream remote is defined' {
    Init
    GivenLocalRepoIs -Standalone
    GivenCommit -InLocal
    WhenSendingCommits -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'A\ remote\ named\ "origin"\ does\ not\ exist\.'
    ThenPushResultIs ([PowerGit.PushResult]::Failed)
}

Describe 'Send-GitCommit.when changes on other branches' {
    Init
    GivenBranch 'develop' -InRemote
    GivenCommit -InRemote -OnBranch 'develop'
    GivenLocalRepoIs -ClonedFromRemote
    $masterCommit = GivenCommit -InLocal -OnBranch 'master'
    $developCommit = GivenCommit -InLocal -OnBranch 'develop'
    WhenSendingCommits
    ThenRemoteRevision $masterCommit.Sha -DoesNotExist
    ThenRemoteRevision $developCommit.Sha -Exists
}

Describe 'Send-GitCommit.when pushing a new branch' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    GivenBranch 'develop' -InLocal
    $commit = GivenCommit -InLocal
    WhenSendingCommits -SetUpstream
    ThenPushResultIs ([PowerGit.PushResult]::Ok)
    ThenRemoteRevision $commit.Sha -Exists
    ThenRemoteRevision 'develop' -Exists
    ThenLocalHead 'refs/heads/develop' -Tracks 'refs/remotes/origin/develop'
}

Describe 'Send-GitCommit.when pushing new commits on a branch' {
    Init
    GivenBranch 'develop' -InRemote
    GivenCommit -InRemote -OnBranch 'develop'
    GivenLocalRepoIs -ClonedFromRemote
    $commit = GivenCommit -InLocal -OnBranch 'develop'
    WhenSendingCommits
    ThenPushResultIs ([PowerGit.PushResult]::Ok)
    ThenRemoteRevision $commit.Sha -Exists
    ThenRemoteRevision 'develop' -Exists
}