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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationCoreTest.ps1' -Resolve)

$serverWorkingDirectory = $null
$serverBareDirectory = $null
$clientDirectory = $null
[GitAutomationCore.CommitInfo]$lastCommit = $null
[GitAutomationCore.SendBranchResult]$result = $null

function GivenBranch {
    param(
        $BranchName
    )

    New-GitBranch -RepoRoot $clientDirectory -Name $BranchName
}

function GivenCheckedOut {
    param(
        $Revision
    )

    Update-GitRepository -RepoRoot $clientDirectory -Revision $Revision
}

function GivenConflicts {
    foreach ( $dir in @( $serverWorkingDirectory, $clientDirectory ) ) {
        $filePath = Join-Path -Path $dir -ChildPath 'first'
        [Guid]::NewGuid() | Set-Content -Path $filePath
        Add-GitItem -Path $filePath -RepoRoot $dir
        $script:lastCommit = Save-GitCommit -RepoRoot $dir -Message 'conflict first'
    }

    Send-GitCommit -RepoRoot $serverWorkingDirectory
}

function GivenNewCommitIn {
    param(
        $Directory,
        [Switch]
        $AndPushed
    )

    Push-Location -Path $Directory
    try {
        $filePath = [IO.Path]::GetRandomFileName()
        New-Item -Path $filePath -ItemType 'File'
        Add-GitItem -Path $filePath
        $script:lastCommit = Save-GitCommit -Message $filePath

        if ( $AndPushed ) {
            Send-GitCommit
        }
    } finally {
        Pop-Location
    }
}

function GivenNoUpstreamBranchFor {
    param(
        $BranchName
    )

    $repo = Get-GitRepository -RepoRoot $clientDirectory
    try {
        $branch = $repo.Branches | Where-Object { $_.FriendlyName -eq $BranchName }
        $repo.Branches.Update($branch, {
                param(
                    [LibGit2Sharp.BranchUpdater]
                    $Updater
                )

                $Updater.TrackedBranch = ''
                $Updater.Remote = ''
                $Updater.UpstreamBranch = ''
            })
    } finally {
        $repo.Dispose()
    }
}

function Init {
    Clear-Error

    $script:serverBareDirectory = Join-Path -Path $TestDrive.FullName -ChildPath 'Server'
    New-GitRepository -Path $serverBareDirectory -Bare

    $script:serverWorkingDirectory = Join-Path -Path $TestDrive.FullName -ChildPath 'Server.Working'
    Copy-GitRepository -Source $serverBareDirectory -DestinationPath $serverWorkingDirectory

    Push-Location -Path $serverWorkingDirectory
    try {
        '' | Set-Content -Path 'master'
        Add-GitItem 'master'
        $script:lastCommit = Save-GitCommit -Message 'first'
        Send-GitCommit
    } finally {
        Pop-Location
    }

    $script:clientDirectory = Join-Path -Path $TestDrive.FullName -ChildPath 'Client'
    Copy-GitRepository -Source $serverBareDirectory -DestinationPath $clientDirectory
}

function ThenErrorIs {
    param(
        $Pattern
    )

    It ('should write an error') {
        $Global:Error | Should -Match $Pattern
    }
}

function ThenHeadIsLastCommit {
    param(
        $BranchName = 'master'
    )

    $repo = Get-GitRepository -RepoRoot $clientDirectory
    try {
        It ('should not create new commit') {
            $repo.Branches[$BranchName].Tip.Sha | Should -Be $lastCommit.Sha
        }
    } finally {
        $repo.Dispose()
    }
}

function ThenHeadIsNewCommit {
    $repo = Get-GitRepository -RepoRoot $clientDirectory
    try {
        It ('should create new commit') {
            $head = $repo.Branches['master'].Tip
            $head.Sha | Should -Not -Be $lastCommit.Sha
            $head.Parents | Where-Object { $_.Sha -eq $lastCommit.Sha } | Should -Not -BeNullOrEmpty
        }
    } finally {
        $repo.Dispose()
    }
}

function ThenHeadsDifferent {
    param(
        $BranchName = 'master'
    )

    It ('should not push changes to remote repository') {
        $serverRepo = Get-GitRepository $serverBareDirectory
        $clientRepo = Get-GitRepository $clientDirectory
        try {
            $serverRepo.Branches[$BranchName].Tip.Sha | Should -Not -Be $clientRepo.Branches[$BranchName].Tip.Sha
        } finally {
            $clientRepo.Dispose()
            $serverRepo.Dispose()
        }
    }
}

function ThenHeadsSame {
    param(
        $BranchName = 'master'
    )

    It ('should push changes to remote repository') {
        $serverRepo = Get-GitRepository $serverBareDirectory
        $clientRepo = Get-GitRepository $clientDirectory
        try {
            $serverRepo.Branches[$BranchName].Tip.Sha | Should -Be $clientRepo.Branches[$BranchName].Tip.Sha
        } finally {
            $clientRepo.Dispose()
            $serverRepo.Dispose()
        }
    }
}

function ThenMergeStatusIs {
    param(
        [LibGit2Sharp.MergeStatus]
        $ExpectedStatus
    )

    It ('should result in "{0}" merge' -f $ExpectedStatus) {
        $result.LastMergeResult.Status | Should -Be $ExpectedStatus
    }
}

function ThenPushStatus {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Is')]
        [GitAutomationCore.PushResult]
        $Is,

        [Parameter(Mandatory = $true, ParameterSetName = 'IsNull')]
        [Switch]
        $IsNull
    )

    if ( $PSCmdlet.ParameterSetName -eq 'Is' ) {
        It ('should result in "{0}" push' -f $Is) {
            $result.LastPushResult | Should -Be $Is
        }
    } else {
        It ('should not push') {
            $result.LastPushResult | Should -BeNullOrEmpty
        }
    }
}

function ThenUpdateFailed {
    It ('should fail the update') {
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -Not -BeNullOrEmpty
    }
}

function WhenUpdated {
    [CmdletBinding()]
    param(
        $RepoRoot,
        $AndMergeStrategyIs
    )

    $mergeStrategyArg = @{}
    if ( $AndMergeStrategyIs ) {
        $mergeStrategyArg['MergeStrategy'] = $AndMergeStrategyIs
    }

    $script:result = Send-GitBranch -RepoRoot $RepoRoot @mergeStrategyArg
}

Describe 'Send-GitBranch.when no new commits on the server' {
    Init
    GivenNewCommitIn $clientDirectory
    WhenUpdated -RepoRoot $clientDirectory
    ThenMergeStatusIs 'UpToDate'
    ThenPushStatus -Is Ok
    ThenHeadIsLastCommit
    ThenHeadsSame
}

Describe 'Send-GitBranch.when no new commits local and no new commits on server' {
    Init
    WhenUpdated -RepoRoot $clientDirectory
    ThenMergeStatusIs 'UpToDate'
    ThenPushStatus -Is Ok
    ThenHeadIsLastCommit
    ThenHeadsSame
}

Describe 'Send-GitBranch.when no new commits local and new commits on server and fast forwarding' {
    Init
    GivenNewCommitIn $serverWorkingDirectory -AndPushed
    WhenUpdated -RepoRoot $clientDirectory
    ThenMergeStatusIs 'FastForward'
    ThenPushStatus -Is Ok
    ThenHeadIsLastCommit
    ThenHeadsSame
}

Describe 'Send-GitBranch.when no new commits local and new commits on server and merging' {
    Init
    GivenNewCommitIn $serverWorkingDirectory -AndPushed
    WhenUpdated -RepoRoot $clientDirectory -AndMergeStrategyIs 'Merge'
    ThenMergeStatusIs 'NonFastForward'
    ThenPushStatus -Is Ok
    ThenHeadIsNewCommit
    ThenHeadsSame
}

Describe 'Send-GitBranch.when new commits local and new commits on server' {
    Init
    GivenNewCommitIn $serverWorkingDirectory -AndPushed
    GivenNewCommitIn $clientDirectory
    WhenUpdated -RepoRoot $clientDirectory
    ThenMergeStatusIs 'NonFastForward'
    ThenPushStatus -Is Ok
    ThenHeadIsNewCommit
    ThenHeadsSame
}

Describe 'Send-GitBranch.when new commits local and new commits on server and merge must be fast-forwarded' {
    Init
    GivenNewCommitIn $serverWorkingDirectory -AndPushed
    GivenNewCommitIn $clientDirectory
    WhenUpdated -RepoRoot $clientDirectory -AndMergeStrategyIs 'FastForward' -ErrorAction SilentlyContinue
    ThenPushStatus -IsNull
    ThenUpdateFailed
    ThenErrorIs 'Cannot\ perform\ fast-forward\ merge'
    ThenHeadIsLastCommit
    ThenHeadsDifferent
}

Describe 'Send-GitBranch.when no local branch' {
    Init
    GivenNewCommitIn $clientDirectory
    GivenCheckedOut $lastCommit.Sha
    WhenUpdated -RepoRoot $clientDirectory -ErrorAction SilentlyContinue
    ThenPushStatus -IsNull
    ThenUpdateFailed
    ThenErrorIs 'isn''t\ on\ a\ branch'
    ThenHeadIsLastCommit
    ThenHeadsDifferent
}

Describe 'Send-GitBranch.when no tracking branch and there is a remote equivalent' {
    Init
    GivenNewCommitIn $clientDirectory
    GivenNewCommitIn $serverWorkingDirectory -AndPushed
    GivenNoUpstreamBranchFor 'master'
    WhenUpdated -RepoRoot $clientDirectory
    ThenMergeStatusIs 'NonFastForward'
    ThenPushStatus -Is Ok
    ThenHeadIsNewCommit
    ThenHeadsSame
}

Describe 'Send-GitBranch.when no tracking branch and there is no remote equivalent' {
    Init
    GivenBranch 'develop'
    GivenNewCommitIn $clientDirectory
    WhenUpdated -RepoRoot $clientDirectory -ErrorAction SilentlyContinue
    ThenPushStatus -IsNull
    ThenUpdateFailed
    ThenErrorIs 'unable\ to\ find\ a\ remote\ branch\ named\ "develop"'
    ThenHeadIsLastCommit 'develop'
    ThenHeadsDifferent 'develop'
}

Describe 'Send-GitBranch.when the given repo doesn''t exist' {
    Clear-Error

    Send-GitBranch -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}

Describe 'Send-GitBranch.when there are conflicts between local and remote' {
    Init
    GivenConflicts
    WhenUpdated -RepoRoot $clientDirectory -ErrorAction SilentlyContinue
    ThenPushStatus -IsNull
    ThenMergeStatusIs 'Conflicts'
    ThenHeadIsLastCommit
    ThenHeadsDifferent
}