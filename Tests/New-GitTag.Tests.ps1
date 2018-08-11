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

Describe 'New-GitTag when creating a new unique tag without passing a target' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    $tagName = 'TAAAAAGGGGG'
    Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $false
    New-GitTag -RepoRoot $repo -Name $tagName


    It 'should create the tag' {
        Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $true
    }

    It 'should point at the current head' {
        $r = Find-GitRepository -Path $repo
        try {
            (Get-GitTag -RepoRoot $repo -Name $tagName).Sha | Should Be $r.Head.Tip.Sha
        } finally {
            $r.Dispose()
        }
    }

    Assert-ThereAreNoErrors
}

Describe 'New-GitTag when creating a new unique tag and passing a revision' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    $tagName = 'aNOTHER---ONNEEE!!!'
    Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $false
    New-GitTag -RepoRoot $repo -Name $tagName -Revision $c1.Sha

    It 'should create the tag' {
        Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $true
    }

    It 'should point at the target' {
        (Get-GitTag -RepoRoot $repo -Name $tagName).Sha | Should Be $c1.Sha
    }

    Assert-ThereAreNoErrors
}

Describe 'New-GitTag when passing a name of a tag that already exists without using -Force' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    $tagName = 'duplicate'
    New-GitTag -RepoRoot $repo -Name $tagName
    Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $true

    New-GitTag -RepoRoot $repo -Name $tagName -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'already exists'
    }
}

Describe 'New-GitTag when using the -Force switch to overwrite a tag' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    $tagName = 'tag'
    New-GitTag -RepoRoot $repo -Name $tagName -Revision $c1.Sha
    Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $true

    New-GitTag -RepoRoot $repo -Name $tagName -Revision $c2.Sha -Force

    It 'should update the tag to the new target' {
        Test-GitTag -RepoRoot $repo -Name $tagName | Should Be $true
        (Get-GitTag -RepoRoot $repo -Name $tagName).Sha | Should Be $c2.Sha
    }

    Assert-ThereAreNoErrors
}

Describe 'New-GitTag when creating a new tag for a revision that is already tagged' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    Add-GitTestFile -RepoRoot $repo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

    $tag1 = 'tag1'
    $tag2 = 'tag2'
    New-GitTag -RepoRoot $repo -Name $tag1 -Revision $c1.Sha
    New-GitTag -RepoRoot $repo -Name $tag2 -Revision $c1.Sha

    It 'should create a new tag pointing at target' {
        Test-GitTag -RepoRoot $repo -Name $tag2 | Should Be $true
        (Get-GitTag -RepoRoot $repo -Name $tag2).Sha | Should Be $c1.Sha
    }

    It 'should not affect the older tag' {
        Test-GitTag -RepoRoot $repo -Name $tag1 | Should Be $true
        (Get-GitTag -RepoRoot $repo -Name $tag1).Sha | Should Be $c1.Sha
    }

    Assert-ThereAreNoErrors
}

Describe 'New-GitTag when passing an invalid revision' {
    Clear-Error

    $repo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $repo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
    Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

    New-GitTag -RepoRoot $repo -Name 'whocares' -Revision 'IdoNotExist' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'No valid git object'
    }
}

Describe 'New-GitTag when ran with an invalid git repository' {
    Clear-Error

    New-GitTag -RepoRoot 'C:/I/do/not/exist' -Name 'whocares' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}
