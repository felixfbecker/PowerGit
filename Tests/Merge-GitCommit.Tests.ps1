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

[GitAutomationCore.MergeResult]$result = $null

function Get-RepoRoot {
    return Join-Path -Path $TestDrive.FullName -ChildPath 'repo'
}

function GivenCurrentHead {
    param(
        $Revision
    )

    Update-GitRepository -RepoRoot (Get-RepoRoot) -Revision $Revision
}

function GivenFile {
    param(
        $Name,
        $Content = ''
    )

    [IO.File]::WriteAllText((Join-Path -Path (Get-RepoRoot) -ChildPath $Name), $Content)
    Add-GitItem -Path $Name -RepoRoot (Get-RepoRoot)
    Save-GitCommit -Message $Name -RepoRoot (Get-RepoRoot)
}

function GivenGitBranch {
    param(
        $Name
    )

    New-GitBranch -RepoRoot (Get-RepoRoot) -Name $Name
}

function GivenGitRepository {
    $repoRoot = (Get-RepoRoot)
    New-Item -Path $repoRoot -ItemType 'Directory'
    New-GitRepository -Path $repoRoot
    $file = Join-Path -Path $repoRoot -ChildPath 'master'
    '' | Set-Content -Path $file
    Add-GitItem -Path 'master' -RepoRoot $repoRoot
    Save-GitCommit -Message 'master' -RepoRoot $repoRoot
}

function GivenTag {
    param(
        $Name
    )

    $repoRoot = Get-RepoRoot
    New-GitTag -RepoRoot $repoRoot -Name $Name
}

function Init {
    $script:result = $null
}

function ThenCommitCountIs {
    param(
        $ExpectedCount
    )

    $repoRoot = Get-RepoRoot
    It ('should have correct number of commits') {
        Get-GitCommit -RepoRoot $repoRoot -All | Measure-Object | Select-Object -ExpandProperty 'Count' | Should -Be $ExpectedCount
    }
}

function ThenFastForwarded {
    param(
        $SourceRevision,
        $DestinationRevision
    )

    $repoRoot = Get-RepoRoot
    $source = Get-GitCommit -Revision $SourceRevision -RepoRoot $repoRoot
    $destination = Get-GitCommit -Revision $DestinationRevision -RepoRoot $repoRoot

    It ('should fast-forward merge') {
        $source.Sha | Should -Be $destination.Sha
    }
}

function ThenFileContentIs {
    param(
        $Name,
        $ExpectedContent
    )

    It ('should have file with correct content') {
        $path = Join-Path -Path (Get-RepoRoot) -ChildPath $Name
        Get-Content -Raw -Path $path| Should -Be $ExpectedContent
    }
}

function ThenFileDoesNotExist {
    param(
        $Name
    )

    It ('should not merge file in from other') {
        Join-Path -Path (Get-RepoRoot) -ChildPath $Name | Should -Not -Exist
    }
}

function ThenFileExists {
    param(
        $Name
    )

    $repoRoot = Get-RepoRoot
    It ('should merge in file from other') {
        Join-Path -Path $repoRoot -ChildPath $Name | Should -Exist
    }
}

function ThenCreatedMergeCommit {
    param(
        $Parent1Revision,
        $Parent2Revision
    )

    $repoRoot = Get-RepoRoot
    $parent1 = Get-GitCommit -RepoRoot $repoRoot -Revision $Parent1Revision
    $parent2 = Get-GitCommit -RepoRoot $repoRoot -Revision $Parent2Revision
    It ('should create a merge commit') {
        $lastCommit = Get-GitCommit -RepoRoot $repoRoot -Revision 'HEAD'
        $lastCommit.Message | Should -BeLike 'Merge commit *'
        $lastCommit.Parents.Count | Should -Be 2
        $lastCommit.Parents[0].Sha | Should -Be $parent1.Sha
        $lastCommit.Parents[1].Sha | Should -Be $parent2.Sha
    }
}

function ThenErrorIs {
    param(
        $Regex
    )

    It ('should write an error') {
        $Global:Error | Should -Match $Regex
    }
}

function ThenMergeStatus {
    param(
        $Is,

        [Switch]
        $IsNull
    )

    if ( $IsNull ) {
        It ('should not return a merge result') {
            $result | Should -BeNullOrEmpty
        }
    } else {
        It ('should set the expected merge status') {
            $result.Status | Should -Be $Is
        }
    }
}

function ThenNotMerged {
    param(
        $Revision1,
        $Revision2
    )

    $repoRoot = Get-RepoRoot
    It ('should not merge') {
        (Get-GitCommit -RepoRoot $repoRoot -Revision $Revision1).Sha | Should -Not -Be (Get-GitCommit -RepoRoot $repoRoot -Revision $Revision2).Sha
    }
}


function WhenMerging {
    [CmdletBinding()]
    param(
        $Revision,

        $FastForward,

        [Switch]
        $NonInteractive
    )

    $optionalParams = @{ }
    if ( $FastForward ) {
        $optionalParams['FastForward'] = $FastForward
    }

    if ( $NonInteractive ) {
        $optionalParams['NonInteractive'] = $NonInteractive
    }

    $Global:Error.Clear()
    $myResult = Merge-GitCommit -RepoRoot (Get-RepoRoot) -Revision $Revision @optionalParams
    if ( $myResult ) {
        $script:result = $myResult
    }
}

Describe 'Merge-GitCommit.when merging one branch into another and can fast forward' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    WhenMerging 'develop'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::FastForward)
    ThenFileExists 'develop'
    ThenFastForwarded 'master' 'develop'
}

Describe 'Merge-GitCommit.when merging one branch into another and can''t fast forward' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    GivenFile 'master.2'
    WhenMerging 'develop'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::NonFastForward)
    ThenFileExists 'develop'
    ThenCreatedMergeCommit 'master^1' 'develop'
}

Describe 'Merge-GitCommit.when merging one branch into another and user doesn''t want to fast forward' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    WhenMerging 'develop' -FastForward 'No'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::NonFastForward)
    ThenFileExists 'develop'
    ThenCreatedMergeCommit 'master^1' 'develop'
}

Describe 'Merge-GitCommit.when merging one branch into another and user only wants to fast forward' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    WhenMerging 'develop' -FastForward 'Only'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::FastForward)
    ThenFileExists 'develop'
    ThenFastForwarded 'develop' 'master'
}

Describe 'Merge-GitCommit.when merging one branch into another and user only wants to fast forward but can''t fast forward' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    GivenFile 'master.2'
    WhenMerging 'develop' -FastForward 'Only' -ErrorAction SilentlyContinue
    ThenMergeStatus -IsNull
    ThenFileDoesNotExist 'develop'
    ThenCommitCountIs 3
    ThenErrorIs 'Cannot\ perform\ fast-forward\ merge'
}

Describe 'Merge-GitCommit.when there are conflicts' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'conflict' 'develop'
    GivenCurrentHead 'master'
    GivenFile 'conflict' 'master'
    WhenMerging 'develop'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::Conflicts)
    ThenFileContentIs 'conflict' ("<<<<<<< HEAD`nmaster`n=======`ndevelop`n>>>>>>> {0}`n" -f (Get-GitCommit -RepoRoot (Get-RepoRoot) -Revision 'develop').Sha)
    ThenCommitCountIs 3
}

Describe 'Merge-GitCommit.when there are conflicts and merging non-interactively' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'conflict' 'develop'
    GivenCurrentHead 'master'
    GivenFile 'conflict' 'master'
    WhenMerging 'develop' -NonInteractive
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::Conflicts)
    ThenFileContentIs 'conflict' "master"
    ThenCommitCountIs 3
}

Describe 'Merge-GitCommit.when already merged' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    WhenMerging 'develop'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::FastForward)
    ThenFileExists 'develop'
    ThenFastForwarded 'master' 'develop'
    WhenMerging 'develop'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::UpToDate)
    ThenFileExists 'develop'
    ThenFastForwarded 'master' 'develop'
}

Describe 'Merge-GitCommit.when merging a tag' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenTag 'fubar'
    GivenCurrentHead 'master'
    GivenFile 'master.2'
    WhenMerging 'fubar'
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::NonFastForward)
    ThenFileExists 'develop'
    ThenCreatedMergeCommit -Parent1Revision 'HEAD~1' -Parent2Revision 'fubar'
    ThenNotMerged 'master' 'develop'
}

Describe 'Merge-GitCommit.when merging a specific commit' {
    Init
    GivenGitRepository
    GivenGitBranch 'develop'
    GivenFile 'develop'
    GivenCurrentHead 'master'
    GivenFile 'master.2'
    $commit = Get-GitCommit -RepoRoot (Get-RepoRoot) -Revision 'develop'
    WhenMerging $commit.Sha
    ThenMergeStatus -Is ([LibGit2Sharp.MergeStatus]::NonFastForward)
    ThenFileExists 'develop'
    ThenCreatedMergeCommit 'HEAD^1' $commit.Sha
    ThenNotMerged 'master' 'develop'
}
