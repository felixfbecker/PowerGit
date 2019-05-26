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

$name = $null
$email = $null
$when = $null

function GivenRepositoryConfig {
    param(
        $Config
    )

    New-GitRepository -Path $TestDrive.FullName
    $Config | Set-Content -Path (Join-Path -Path $TestDrive.FullName -ChildPath '.git\config')
}

function Init {
    $script:name = $null
    $script:email = $null
    $script:when = $null
}

function ThenSignatureIs {
    param(
        $Name,
        $Email
    )

    It ('should set name') {
        $signature.Name | Should -Be $Name
    }
    It ('should set email') {
        $signature.Email | Should -Be $Email
    }
    It ('should set When') {
        $signature.When | Should -BeGreaterOrEqual $when
    }
}

function WhenCreatingSignature {
    [CmdletBinding()]
    param(
        $Name,
        $Email,
        $RepoRoot
    )

    $parameters = @{ }
    if ($Name) {
        $parameters['Name'] = $Name
    }

    if ($Email) {
        $parameters['Email'] = $Email
    }

    if ($RepoRoot) {
        $parameters['RepoRoot'] = $RepoRoot
    }

    $script:when = [DateTimeOffset]::Now
    $Global:Error.Clear()
    $script:signature = New-GitSignature @parameters
}

Describe 'New-GitSignature.when passing author information' {
    WhenCreatingSignature 'Fubar Snafu' 'fizzbuzz@example.com'
    ThenSignatureIs 'Fubar Snafu' 'fizzbuzz@example.com'
}

Describe 'New-GitSignature.when reading configuration from global files' {
    $blankGitConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '../PowerGit/gitconfig'
    $config = [LibGit2Sharp.Configuration]::BuildFrom($blankGitConfigPath)
    $name = $config | Where-Object { $_.Key -eq 'user.name' } | Select-Object -ExpandProperty 'Value'
    $clearName = $false
    if (-not $name) {
        $name = 'name name'
        $config.Set('user.name', $name, [LibGit2Sharp.ConfigurationLevel]::Global)
        $clearName = $true
    }
    $email = $config | Where-Object { $_.Key -eq 'user.email' } | Select-Object -ExpandProperty 'Value'
    $clearEmail = $false
    if (-not $email) {
        $email = 'email@example.com'
        $config.Set('user.email', $email, [LibGit2Sharp.ConfigurationLevel]::Global)
        $clearEmail = $true
    }

    try {
        WhenCreatingSignature
        ThenSignatureIs $name $email
    } finally {
        if ($clearName) {
            $config.Unset('user.name', [LibGit2Sharp.ConfigurationLevel]::Global)
        }
        if ($clearEmail) {
            $config.Unset('user.email', [LibGit2Sharp.ConfigurationLevel]::Global)
        }
        $config.Dispose()
    }
}

Describe 'New-GitSignature.when reading configuration from repository' {
    GivenRepositoryConfig '
[user]
	name = Repo Repo
    email = repo@example.com
'
    WhenCreatingSignature -RepoRoot $TestDrive.FullName
    ThenSignatureIs 'Repo Repo' 'repo@example.com'
}

Describe 'New-GitSignature.when configuration is missing' {
    $blankGitConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '../PowerGit/gitconfig'
    $config = [LibGit2Sharp.Configuration]::BuildFrom($blankGitConfigPath)
    $name = $config | Where-Object { $_.Key -eq 'user.name' } | Select-Object -ExpandProperty 'Value'
    $email = $config | Where-Object { $_.Key -eq 'user.email' } | Select-Object -ExpandProperty 'Value'

    $config.Unset('user.name', 'Global')
    $config.Unset('user.email', 'Global')

    try {
        WhenCreatingSignature -ErrorAction SilentlyContinue
        It ('should return nothing') {
            $script:signature | Should -BeNullOrEmpty
        }

        It ('should write error') {
            $Global:Error | Should -Match 'Failed\ to\ build\ author\ signature'
        }

        WhenCreatingSignature -ErrorAction Ignore
        It ('should ignore errors without throwing an error') {
            $Global:Error.Count | Should -Be 0
        }
    } finally {
        if ($name) {
            $config.Set('user.name', $name, 'Global')
        }
        if ($email) {
            $config.Set('user.email', $email, 'Global')
        }
        $config.Dispose()
    }
}
