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

Describe 'Test-GitUncommittedChange when checking for uncommitted changes' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'added file1'

    It 'should return false if there are no changes' {
        Test-GitUncommittedChange -RepoRoot $repo | Should Be $false
    }

    '' | Set-Content -Path (Join-Path -Path $repo -ChildPath 'file1')

    It 'should return true if a file has been modified' {
        Test-GitUncommittedChange -RepoRoot $repo | Should Be $true
    }

    Add-GitItem -Path (Join-Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'modified file1'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo

    It 'should return true if a file has been added' {
        Test-GitUncommittedChange -RepoRoot $repo | Should Be $true
    }

    Save-GitCommit -RepoRoot $repo -Message 'added file2'

    Rename-Item -Path (Join-Path -Path $repo -ChildPath 'file2') -NewName 'file2.Awesome'

    It 'should return true if a file has been renamed' {
        Test-GitUncommittedChange -RepoRoot $repo | Should Be $true
    }

    Add-GitItem -Path (Join-Path $repo -ChildPath 'file2.Awesome') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'renamed file2'

    Remove-Item -Path (Join-Path -Path $repo -ChildPath 'file1')

    It 'should return true if a file has been deleted' {
        Test-GitUncommittedChange -RepoRoot $repo | Should Be $true
    }

    Assert-ThereAreNoErrors
}

Describe 'Test-GitUncommittedChanges when the given repo doesn''t exist' {
    Clear-Error

    Test-GitUncommittedChange -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}