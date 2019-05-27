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

function New-GitSignature {
    <#
    .SYNOPSIS
    Creates an author signature object used to identify who created a commit.

    .DESCRIPTION
    The `New-GitSignature` object creates `LibGit2Sharp.Signature` objects. These objects are added when committing changes to identify the author of the commit and when the commit was made.

    With no parameters, this function reads author metadata from the "user.name" and "user.email" user level or system level configuration. If there is no user or system-level "user.name" or "user.email" setting, you'll get an error and nothing will be returned.

    To use explicit author information, pass the author's name and email address to the "Name" and "EmailAddress" parameters.

    .EXAMPLE
    New-GitSignature

    Demonstrates how to get create a Git author signature from the current user's user-level and system-level Git configuration files.

    .EXAMPLE
    New-GitSignature -Name 'Jock Nealy' -EmailAddress 'email@example.com'

    Demonstrates how to create a Git author signature using an explicit name and email address.
    #>
    [CmdletBinding(DefaultParameterSetName = 'FromConfiguration')]
    [OutputType([LibGit2Sharp.Signature])]
    param(
        # The author's name, i.e. GivenName Surname.
        [Parameter(Mandatory, ParameterSetName = 'FromParameter')]
        [string] $Name,

        # The author's email address.
        [Parameter(Mandatory, ParameterSetName = 'FromParameter')]
        [string] $EmailAddress,

        [Parameter(Mandatory, ParameterSetName = 'FromRepositoryConfiguration')]
        [string] $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function Get-Signature {
        param(
            [LibGit2Sharp.Configuration]
            $Configuration
        )

        $signature = $Configuration.BuildSignature([DateTimeOffset]::Now)
        if (-not $signature) {
            Write-Error -Message ('Failed to build author signature from Git configuration files. Please pass custom author information to the "Name" and "EmailAddress" parameters or set author information in Git''s user-level configuration files by running these commands:

    git config --global user.name "GIVEN_NAME SURNAME"
    git config --global user.email "email@example.com"
 ') -ErrorAction $ErrorActionPreference
            return
        }
        return $signature
    }

    if ($PSCmdlet.ParameterSetName -eq 'FromRepositoryConfiguration') {
        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }

        return Get-Signature -Configuration $repo.Config
    }

    if ($PSCmdlet.ParameterSetName -eq 'FromConfiguration') {
        $blankGitConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '../gitconfig' -Resolve
        [LibGit2Sharp.Configuration]$config = [LibGit2Sharp.Configuration]::BuildFrom($blankGitConfigPath)

        return Get-Signature -Configuration $config
    }

    [LibGit2Sharp.Signature]::new($Name, $EmailAddress, ([DateTimeOffset]::Now))
}
