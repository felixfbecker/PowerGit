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

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

$globalSearchPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global)

function Assert-ConfigurationVariableSet {
    param(
        $Path
    )

    It 'should set the configuraton variable' {
        Get-Content -Path $Path | Where-Object { $_ -match 'autocrlf\ =\ false' } | Should Not BeNullOrEmpty
    }
}

Describe 'Set-GitConfiguration when setting the current repository''s configuration' {
    $repo = New-GitTestRepo
    Push-Location -Path $repo
    try {
        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false'
        Assert-ConfigurationVariableSet -Path '.git\config'
    } finally {
        Pop-Location
    }
}

Describe 'Set-GitConfiguration when setting a specific repository''s configuration' {
    $repo = New-GitTestRepo

    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot $repo
    Assert-ConfigurationVariableSet -Path (Join-Path -Path $repo -ChildPath '.git\config')
}

Describe 'Set-GitConfiguration when repo does not exist' {
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot (Resolve-TestDrivePath) -ErrorVariable 'errors' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $errors | Should Match 'not in a Git repository'
    }
}

Describe 'Set-GitConfiguration when setting global configuration' {
    $value = [Guid]::NewGuid()
    Set-GitConfiguration -Name 'PowerGit.test' -Value $value -Scope Global
    $repo = Find-GitRepository -Path $PSScriptRoot
    It 'should set option globally' {
        $repo.Config | Where-Object { $_.Key -eq 'PowerGit.test' -and $_.Value -eq $value -and $_.Level -eq [LibGit2Sharp.ConfigurationLevel]::Global } | Should Not BeNullOrEmpty
    }
}

Describe 'Set-GitConfiguration when setting a specific repository''s configuration and current directory is a sub-directory of the repository root' {
    $repo = New-GitTestRepo
    Push-Location -Path $repo
    try {
        New-Item -Path 'child' -ItemType 'Directory'
        Set-Location -Path 'child'

        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -ErrorVariable 'errors'
        Assert-ConfigurationVariableSet -Path '..\.git\config'
        It 'should not write any errors' {
            $errors | Should BeNullOrEmpty
        }
    } finally {
        Pop-Location
    }
}

Describe 'Set-GitConfiguration when using a specific configuration file' {
    $file = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'fubarsnafu'

    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Path $file -ErrorVariable 'errors'
    Assert-ConfigurationVariableSet -Path $file
    It 'should not write any errors' {
        $errors | Should BeNullOrEmpty
    }
}

Describe 'Set-GitConfiguration when using a relative path to a specific configuration file' {
    $testDriveRoot = (Resolve-TestDrivePath)

    Push-Location -Path $testDriveRoot
    try {
        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Path 'fubarsnafu' -ErrorVariable 'errors'
        Assert-ConfigurationVariableSet -Path (Join-Path -Path $testDriveRoot -ChildPath 'fubarsnafu')
        It 'should not write any errors' {
            $errors | Should BeNullOrEmpty
        }
    } finally {
        Pop-Location
    }
}

Describe 'Set-GitConfiguration when setting global configuration and not in a repository' {
    $tempRoot = (Resolve-TestDrivePath)
    Mock -CommandName 'Test-Path' -ModuleName 'PowerGit' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return $false }
    Push-Location -Path $tempRoot
    try {
        [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, ($tempRoot -replace '\\', '/'))
        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Scope Global -ErrorVariable 'errors'
        Assert-ConfigurationVariableSet -Path '.gitconfig'
        It 'should not write any errors' {
            $errors | Should BeNullOrEmpty
        }
    } finally {
        Pop-Location
    }
}

Describe 'Set-GitConfiguration when HOME environment variable exists' {
    [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, (([IO.Path]::GetTempPath()) -replace '\\', '/') )
    $tempRoot = (Resolve-TestDrivePath)
    Mock -CommandName 'Test-Path' -ModuleName 'PowerGit' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return $true }
    Mock -CommandName 'Get-Item' -ModuleName 'PowerGit' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return [pscustomobject]@{ Name = 'HOME' ; Value = (Resolve-TestDrivePath) } }

    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Scope Global -ErrorVariable 'errors'
    Assert-ConfigurationVariableSet -Path (Join-Path -Path $tempRoot -ChildPath '.gitconfig')
    It 'should not write any errors' {
        $errors | Should BeNullOrEmpty
    }

    It 'should not create any other configuration files' {
        Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath '.gitconfig' | Should Not Exist
    }
}

[LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $globalSearchPaths)
