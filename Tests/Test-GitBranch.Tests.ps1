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

Describe 'Test-GitBranch when running from a valid git repository' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    It 'should return true if the branch name exists' {
        Test-GitBranch -RepoRoot $repo -Name 'master' | Should Be $true
    }

    It 'should return false if the branch name does not exist' {
        Test-GitBranch -RepoRoot $repo -Name 'whocares' | Should Be $false
    }
    Assert-ThereAreNoErrors
}

Describe 'Test-GitBranch when passed an invalid repository' {
    Clear-Error

    Test-GitBranch -RepoRoot 'C:\I\do\not\exist' -Name 'whocares' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}