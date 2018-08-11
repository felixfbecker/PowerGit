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

Describe 'Get-GitTag without passing a name' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
    New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
    $tags = Get-GitTag -RepoRoot $repo

    It 'should get all the tags' {
        $tags.Count | Should Be 2
        $tags[0].Name | Should Be 'tag1'
        $tags[0].Sha | Should Be $c1.Sha
        $tags[1].Name | Should Be 'tag2'
        $tags[1].Sha | Should Be $c2.Sha
    }

    Assert-ThereAreNoErrors
}

Describe 'Get-GitTag when passing a specific name' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
    New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
    $tags = Get-GitTag -RepoRoot $repo -Name 'tag1'

    It 'should get the specific tag' {
        $tags | Should Not BeNullOrEmpty
        $tags.Name | Should Be 'tag1'
        $tags.Sha | Should Be $c1.Sha
    }

    Assert-ThereAreNoErrors
}

Describe 'Get-GitTag when passing a name that does not exist' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
    New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
    $tags = Get-GitTag -RepoRoot $repo -Name 'tag3'

    It 'should get no tags' {
        $tags | Should BeNullOrEmpty
    }

    Assert-ThereAreNoErrors
}

Describe 'Get-GitTag when passing a name using wildcards' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
    New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
    New-GitTag -RepoRoot $repo -Name 'anotherTag' -Revision $c1.Sha
    $tags = Get-GitTag -RepoRoot $repo -Name 'tag*'

    It 'should get tags that match wildcard' {
        $tags.Count | Should Be 2
        $tags[0].Name | Should Be 'tag1'
        $tags[0].Sha | Should Be $c1.Sha
        $tags[1].Name | Should Be 'tag2'
        $tags[1].Sha | Should Be $c2.Sha
    }

    Assert-ThereAreNoErrors
}

Describe 'Get-GitTag when ran with an invalid git repository' {
    Clear-Error

    Get-GitTag -RepoRoot 'C:/I/do/not/exist' -Name 'whocares' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}