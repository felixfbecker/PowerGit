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

function Assert-FileNotStaged {
    param(
        [string[]]
        $Path,

        [string]
        $RepoRoot = (Get-Location).ProviderPath
    )

    foreach ($pathItem in $Path) {
        Get-GitRepositoryStatus -RepoRoot $RepoRoot -Path $pathItem 6>$null |
            Where-Object { $_.IsStaged } |
            Should -BeNullOrEmpty
    }
}
function Assert-FileStaged {
    param(
        [string[]]
        $Path,

        [string]
        $RepoRoot = (Get-Location).ProviderPath
    )

    foreach ($pathItem in $Path) {
        Get-GitRepositoryStatus -RepoRoot $RepoRoot -Path $pathItem |
            Where-Object { $_.IsStaged } |
            Should -Not -BeNullOrEmpty
    }
}

Describe Add-GitItem {

    It 'should add new files' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repoRoot -Path 'file1', 'file2', 'file3', 'file4'
        Add-GitItem -Path (Join-Path -Path $repoRoot -ChildPath 'file1'), (Join-Path -Path $repoRoot -ChildPath 'file2') -RepoRoot $repoRoot

        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot -Path 'file1'

        Assert-FileStaged -Path 'file1', 'file2' -RepoRoot $repoRoot
        Assert-FileNotStaged -Path 'file3', 'file4' -RepoRoot $repoRoot
    }

    It 'should add new files from the current directory' {
        $repoRoot = New-GitTestRepo
        Push-Location $repoRoot
        try {
            Add-GitTestFile -Path 'file1', 'file2', 'file3', 'file4'
            Add-GitItem -Path 'file1', 'file2'

            Assert-FileStaged 'file1', 'file2'
            Assert-FileNotStaged 'file3', 'file4'
        } finally {
            Pop-Location
        }
    }

    It "should write an error for each file if paths aren't under the repository" {
        $repoRoot = New-GitTestRepo
        $anotherRepo = New-GitTestRepo
        $relativePath = Join-Path -Path ('..\{0}' -f (Split-Path -Leaf -Path $anotherRepo)) -ChildPath ([IO.Path]::GetRandomFileName())
        Set-Content -Path (Join-Path -Path $anotherRepo -ChildPath (Split-Path -Leaf -Path $relativePath)) -Value ''
        $fullPath = Join-Path -Path $anotherRepo -ChildPath ([IO.Path]::GetRandomFileName())
        Set-Content -Path $fullPath -Value ''

        Add-GitItem -Path $relativePath, $fullPath -RepoRoot $repoRoot -ErrorAction SilentlyContinue -ErrorVariable addErrors
        $addErrors | Should -HaveCount 2
    $addErrors | Should -Match 'not in the repository'
}

Describe 'when paths to add do not exist' {
    It 'should write errors for each file' {
        $repoRoot = New-GitTestRepo
        $relativePath = Join-Path -Path '..' -ChildPath ([IO.Path]::GetRandomFileName())
        $fullPath = Join-Path -Path $repoRoot -ChildPath ([IO.Path]::GetRandomFileName())
        Add-GitItem -Path $relativePath, $fullPath -RepoRoot $repoRoot -ErrorAction SilentlyContinue -ErrorVariable addErrors
        $addErrors | Should -HaveCount 2
    $addErrors | Should -Match 'does not exist'
}
}

Describe 'when passed a relative repository root path' {
    $repoRoot = New-GitTestRepo
    Push-Location -Path (Split-Path -Parent -Path $repoRoot)
    try {
        Add-GitTestFile -RepoRoot $repoRoot -Path 'file1'
        Add-GitItem -Path 'file1' -RepoRoot (Split-Path -Leaf -Path $repoRoot)
        Assert-FileStaged -Path 'file1' -RepoRoot $repoRoot
    } finally {
        Pop-Location
    }
}

Describe 'when repository does not exist' {
    It 'should write an error' {
        Add-GitItem -RepoRoot 'C:\I\do\not\exist' -Path 'meneither' -ErrorAction SilentlyContinue -ErrorVariable addErrors
        $addErrors | Should -HaveCount 1
    $addErrors | Should -Match 'does not exist'
}
}

Describe 'when repository is not a repository' {
    It 'should write an error' {
        Push-Location -Path 'TestDrive:'
        try {
            '' | Set-Content 'file1'
        Add-GitItem -Path 'file1' -ErrorAction SilentlyContinue -ErrorVariable addErrors
        $addErrors | Should -Not -BeNullOrEmpty
    $addErrors | Should -Match 'not in a Git repository'
} finally {
    Pop-Location
}
}
}

It 'should add items when part of a pipeline' {
    $repoRoot = New-GitTestRepo
    Add-GitTestFile 'file1', 'file2', 'dir1\file3', 'dir1\file4' -RepoRoot $repoRoot
    ('file1', (Get-Item -Path (Join-Path -Path $repoRoot -ChildPath 'file2')), (Get-Item -Path (Join-Path -Path $repoRoot -ChildPath 'dir1'))) |
        Add-GitItem -RepoRoot $repoRoot
    Assert-FileStaged 'file1', 'file2', 'dir1\file3', 'dir1\file4' -RepoRoot $repoRoot
}

Describe 'when -PassThru switch is used' {
    It 'should return objects' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -Path 'file1', 'dir1\file2' -RepoRoot $repoRoot
        $result = Add-GitItem -RepoRoot $repoRoot -Path 'file1', 'dir1' -PassThru
        Assert-FileStaged 'file1', 'dir1\file2' -RepoRoot $repoRoot
        $result | Should -HaveCount 2
    $result[0] | Should BeOfType ([IO.FileInfo])
$result[0].Name | Should -Be 'file1'
$result[1] | Should BeOfType ([IO.DirectoryInfo])
$result[1].Name | Should -Be 'dir1'
}
}

Describe 'when item is already added' {
    It 'should not throw any errors' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -Path 'file1' -RepoRoot $repoRoot
        Add-GitItem -Path 'file1', 'file1' -RepoRoot $repoRoot -ErrorAction Stop
        Assert-FileStaged -Path 'file1' -RepoRoot $repoRoot
    }
}

Describe 'for an unmodified file' {
    It 'should not throw any errors' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -Path 'file1' -RepoRoot $repoRoot
        Add-GitItem -Path 'file1', 'file1' -RepoRoot $repoRoot
        Save-GitCommit -Message 'Committing a file change' -RepoRoot $repoRoot
        Add-GitItem -Path 'file1' -RepoRoot $repoRoot -ErrorAction Stop
        Assert-FileNotStaged -Path 'file1' -RepoRoot $repoRoot
    }
}
}
