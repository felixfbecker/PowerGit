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

Describe Set-GitHead {

    Describe 'when updating to a specific commit' {
        Clear-Error

        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        Set-GitHead -RepoRoot $repo -Revision $c1.Sha

        It 'should create a detached head state pointing at the commit' {
            $r = Find-GitRepository -Path $repo
            try {
                $r.Head.Tip.Sha | Should -Be $c1.Sha
                (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Match 'no branch'
            } finally {
                $r.Dispose()
            }
        }

        Assert-ThereAreNoErrors
    }

    Describe 'when updating to a tag' {
        Clear-Error

        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
        $tag = Get-GitTag -RepoRoot $repo -Name 'tag1'

        Set-GitHead -RepoRoot $repo -Revision $tag.CanonicalName

        It 'should create a detached head state pointing at the tag' {
            $r = Find-GitRepository -Path $repo
            try {
                $r.Head.Tip.Sha | Should -Be $c1.Sha
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should Match 'no branch'
    } finally {
        $r.Dispose()
    }
    }
    }

    Describe 'when updating to a remote reference' {
        Clear-Error

        $remoteRepo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
        Save-GitCommit -RepoRoot $remoteRepo -Message 'file1 commit'

        $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath
        AfterAll { Remove-Item -Recurse -Force -Path $localRepoPath }.GetNewClosure()

        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file2') -RepoRoot $remoteRepo
        $c2 = Save-GitCommit -RepoRoot $remoteRepo -Message 'file2 commit'

        Receive-GitObject -RepoRoot $localRepoPath

        Set-GitHead -RepoRoot $localRepoPath -Revision 'refs/remotes/origin/master'

        It 'should create a detached head pointing at the remote' {
            $r = Find-GitRepository -Path $localRepoPath
            try {
                $r.Head.Tip.Sha | Should -Be $c2.Sha
                (Get-GitBranch -RepoRoot $localRepoPath -Current).Name | Should Match 'no branch'
            } finally {
                $r.Dispose()
            }
        }

        Assert-ThereAreNoErrors
    }

    Describe 'when updating to the head of a branch' {
        Clear-Error

        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        $branch1Name = 'newbranch'
        New-GitBranch -RepoRoot $repo -Name $branch1Name -Revision $c1.Sha
        $branch1 = Get-GitBranch -RepoRoot $repo -Current
        New-GitBranch -RepoRoot $repo -Name 'newbranch2' -Revision $c2.Sha

        Set-GitHead -RepoRoot $repo -Revision $branch1Name

        It 'should checkout that branch' {
            $r = Find-GitRepository -Path $repo
            try {
                $r.Head.CanonicalName | Should Match $branch1.CanonicalName
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should Match $branch1.Name
    } finally {
        $r.Dispose()
    }
    }

    Assert-ThereAreNoErrors
    }

    Describe 'when updating to a branch that only exists at the remote origin' {
        Clear-Error

        $remoteRepo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
        Save-GitCommit -RepoRoot $remoteRepo -Message 'file1 commit'
        New-GitBranch -RepoRoot $remoteRepo -Name 'develop' -Revision 'master'
        Set-GitHead -RepoRoot $remoteRepo -Revision 'master'

        $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath ([Guid]::newGuid())
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath
        AfterAll { Remove-Item -Force -Recurse $localRepoPath }.GetNewClosure()

        Set-GitHead -RepoRoot $localRepoPath -Revision 'develop'

        It 'should create a local branch to track the remote branch' {
            $r = Find-GitRepository -Path $localRepoPath
            try {
                $originBranch = $r.Branches | Where-Object { $_.FriendlyName -eq 'origin/develop' }
            $localBranch = $r.Branches | Where-Object { $_.FriendlyName -eq 'develop' }

        $originBranch.IsRemote | Should -Be $true
    $localBranch.IsTracking | Should -Be $true
    $originBranch.CanonicalName | Should Match $localBranch.TrackedBranch
    } finally {
        $r.Dispose()
    }
    }

    Assert-ThereAreNoErrors
    }

    Describe 'when the given repo does not exist' {
        Clear-Error

        Set-GitHead -RepoRoot 'C:\I\do\not\exist' -Revision whatever -ErrorAction SilentlyContinue
        It 'should throw an error' {
            $Global:Error | Should -HaveCount 1
            $Global:Error | Should -Match 'does not exist'
        }
    }

    Describe 'when there are uncommitted changes' {
        Clear-Error

        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        [Guid]::NewGuid() | Set-Content -Path (Join-Path -Path $repo -ChildPath 'file2')
        Set-GitHead -RepoRoot $repo -Revision $c1.Sha -Force

        It 'should remove uncomitted changes' {
            $status = Get-GitRepositoryStatus -RepoRoot $repo 6>$null
            $status | Should -BeNullOrEmpty

            $r = Find-GitRepository -Path $repo
            try {
                $r.Head.Tip.Sha | Should -Be $c1.Sha
                (Get-GitBranch -RepoRoot $repo -Current).Name | Should Match 'no branch'
            } finally {
                $r.Dispose()
            }
        }

        Assert-ThereAreNoErrors
    }
}
