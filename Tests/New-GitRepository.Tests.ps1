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

function Assert-Repository {
    param(
        [Parameter(Position = 0)]
        $Repository,
        $CreatedAt
    )

    It 'should create a repository' {
        $Repository | Should -Not -BeNullOrEmpty
        $Repository | Should -BeOfType ([LibGit2Sharp.Repository])
        $Repository.Info.WorkingDirectory.TrimEnd([IO.Path]::DirectorySeparatorChar) | Should -Be $CreatedAt.TrimEnd([IO.Path]::DirectorySeparatorChar)
        $Repository.Info.Path | Should -Be (Join-Path -Path $CreatedAt -ChildPath '.git\')
    }
}

function ThenDirectory {
    param(
        $Path,
        [switch] $Exists,
        [switch] $DoesNotExist
    )

    $fullPath = Join-Path -Path $global:testDir.Fullname -ChildPath $Path
    if ($Exists) {
        It ('should have a "{0}" directory' -f $Path) {
            $fullPath | Should -Exist
        }
    } else {
        It ('should not have a "{0}" directory' -f $Path) {
            $fullPath | Should -Not -Exist
        }
    }
}

function ThenFile {
    param(
        $Path,
        $Matches
    )

    $fullPath = Join-Path -Path $global:testDir.FullName -ChildPath $Path

    It ('should have a "{0}" file that matches /{1}/' -f $Path, $Matches) {
        Get-Content -Raw -Path $fullPath | Should -Match $Matches
    }
}

function Init {
    $Global:Error.Clear()
}

function WhenCreatingRepo {
    param(
        [Switch]
        $Bare
    )

    New-GitRepository -Path $global:testDir.FullName -Bare:$Bare
}

Describe 'New-GitRepository when path does not exist' {
    Init
    $repoRoot = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'parent\reporoot\'
    $repo = New-GitRepository -Path $repoRoot
    Assert-Repository $repo -CreatedAt $repoRoot
}

Describe 'New-GitRepository when path is relative' {
    Init
    $base = (Join-Path (Resolve-TestDrivePath) ([Guid]::NewGuid()))
    New-Item -ItemType Directory $base
    $repoRoot = 'parent\reporoot\'
    Push-Location -Path $base
    try {
        $repo = New-GitRepository -Path $repoRoot
        Assert-Repository $repo -CreatedAt (Join-Path -Path $base -ChildPath $repoRoot)
    } finally {
        Pop-Location
    }
}

Describe 'New-GitRepository when path exists' {
    Init
    $repoRoot = Join-Path (Resolve-TestDrivePath) ([Guid]::NewGuid())
    $repo = New-GitRepository -Path $repoRoot
    Assert-Repository $repo -CreatedAt $repoRoot
}

Describe 'New-GitRepository when path is already a repository' {
    Init
    $repoRoot = Join-Path (Resolve-TestDrivePath) ([Guid]::NewGuid())
    $repo = New-GitRepository -Path $repoRoot
    Assert-Repository $repo -CreatedAt $repoRoot
    $repo = New-GitRepository -Path $repoRoot
    Assert-Repository $repo -CreatedAt $repoRoot
}

Describe 'New-GitRepository when -WhatIf switch is passed' {
    Init
    $repoRoot = Join-Path (Resolve-TestDrivePath) ([Guid]::NewGuid())
    $repo = New-GitRepository -Path $repoRoot -WhatIf
    It 'should not create a repository' {
        $repo | Should BeNullOrEmpty
        $repoRoot | Should -Not -Exist
    }
    Assert-ThereAreNoErrors
}

Describe 'New-GitRepository.when creating bare repository' {
    Init
    WhenCreatingRepo -Bare
    ThenDirectory '.git' -DoesNotExist
    ThenDirectory 'refs' -Exists
    ThenFile 'config' -Matches 'bare\ =\ true'
}
