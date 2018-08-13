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

Describe 'New-GitBranch when creating a new unique branch' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    $branchName = 'newBranch'
    Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $false
    New-GitBranch -RepoRoot $repo -Name $branchName

    It 'should create the branch' {
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $true
    }

    It 'should checkout that branch' {
        (Get-GitBranch -RepoRoot $repo -Current).Name | Should Be $branchName
    }

    It 'should be pointing at the current HEAD' {
        $r = Find-GitRepository -Path $repo
        try {
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should Be $r.Head.FriendlyName
        } finally {
            $r.Dispose()
        }
    }

    Assert-ThereAreNoErrors
}

Describe 'New-GitBranch when trying to create an existing branch name' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    $branchName = 'master'
    Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $true
    New-GitBranch -RepoRoot $repo -Name $branchName -WarningVariable warning

    It 'should only throw a warning' {
        $warning | Should Match 'already exists'
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $true
    }

    Assert-ThereAreNoErrors
}

Describe 'New-GitBranch when ran with an invalid git repository' {
    Clear-Error

    New-GitBranch -RepoRoot 'C:/I/do/not/exist' -Name 'whocares' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}

Describe 'New-GitBranch when passing a start point that is not head' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    $branchName = 'newBranch'
    Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $false
    New-GitBranch -RepoRoot $repo -Name $branchName -Revision 'HEAD~1'

    It 'should create the branch' {
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $true
    }

    It 'should checkout that branch' {
        (Get-GitBranch -RepoRoot $repo -Current).Name | Should Be $branchName
    }

    It 'should be at the starting point' {
        (Get-GitBranch -RepoRoot $repo -Current).Tip.Sha | Should Be $c1.Sha
    }
}

Describe 'New-GitBranch when passing an invalid start point' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    $branchName = 'newBranch'
    $startPoint = 'IDONOTEXIST'
    Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $false
    New-GitBranch -RepoRoot $repo -Name $branchName -Revision $startPoint -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error[0] | Should Match 'invalid starting point'
    }

    It 'should not create the branch' {
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should Be $false
    }
}
