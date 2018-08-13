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

function Set-GitConfiguration {
    <#
    .SYNOPSIS
    Sets Git configuration options

    .DESCRIPTION
    The `Set-GitConfiguration` function sets Git configuration variables. These variables change Git's behavior. Git has hundreds of variables and we can't document them here. Some are shared between Git commands. Some variables are only used by specific commands. The `git help config` help topic lists most of them.

    By default, this function sets options for the current repository, or a specific repository using the `RepoRoot` parameter. To set options for the current user across all repositories, use the `-Global` switch. If running in an elevated process, `Set-GitConfiguration` will look in `$env:HOME` and `$env:USERPROFILE` (in that order) for a .gitconfig file. If it can't find one, it will create one in `$env:HOME`. If the `HOME` environment variable isn't defined, it will create a `.gitconfig` file in the `$env:USERPROFILE` directory.

    If running in a non-elevated process, `Set-GitConfiguration` will look in `$env:HOME`, `$env:HOMEDRIVE$env:HOMEPATH`, and `$env:USERPROFILE` (in that order) and use the first `.gitconfig` file it finds. If it can't find a `.gitconfig` file, it will create a `.gitconfig` in the `$env:HOME` directory. If the `HOME` environment variable isn't defined, it will create the `.gitconfig` file in the `$env:HOMEDRIVE$env:HOMEPATH` directory.

    To set the configuration in a specific file, use the `Path` parameter. If the file doesn't exist, it is created.

    This function implements the `git config` command.

    .EXAMPLE
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false'

    Demonstrates how to set the `core.autocrlf` setting to `false` for the repository in the current directory.

    .EXAMPLE
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Global

    Demonstrates how to set a configuration variable so that it applies across all a user's repositories by using the `-Global` switch.

    .EXAMPLE
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot 'C:\Projects\PowerGit'

    Demonstrates how to set a configuration variable for a specific repository. In this case, the configuration for the repository at `C:\Projects\PowerGit` will be updated.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        # The name of the configuration variable to set.
        $Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]
        # The value of the configuration variable.
        $Value,

        [Parameter(ParameterSetName = 'ByScope')]
        [LibGit2Sharp.ConfigurationLevel]
        # Where to set the configuration value. Local means the value will be set for a specific repository. Global means set for the current user. System means set for all users on the current computer. The default is `Local`.
        $Scope = ([LibGit2Sharp.ConfigurationLevel]::Local),

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]
        # The path to a specific file whose configuration to update.
        $Path,

        [Parameter(ParameterSetName = 'ByScope')]
        [string]
        # The path to the repository whose configuration variables to set. Defaults to the repository the current directory is in.
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ( $PSCmdlet.ParameterSetName -eq 'ByPath' ) {
        if ( -not (Test-Path -Path $Path -PathType Leaf) ) {
            New-Item -Path $Path -ItemType 'File' -Force | Write-Verbose
        }

        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty 'ProviderPath'

        $config = [LibGit2Sharp.Configuration]::BuildFrom($Path)
        try {
            $config.Set( $Name, $Value, 'Local' )
        } finally {
            $config.Dispose()
        }
        return
    }

    $pathParam = @{}
    if ( $RepoRoot ) {
        $pathParam['Path'] = $RepoRoot
    }

    if ( $Scope -eq [LibGit2Sharp.ConfigurationLevel]::Local ) {
        $repo = Find-GitRepository @pathParam -Verify
        if ( -not $repo ) {
            return
        }

        try {
            $repo.Config.Set($Name, $Value, $Scope)
        } finally {
            $repo.Dispose()
        }
    } else {
        Update-GitConfigurationSearchPath -Scope $Scope

        # LibGit2 only creates config files explicitly.
        [string[]]$searchPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($Scope) | Join-Path -ChildPath '.gitconfig'
        $scopeConfigFiles = $searchPaths | Where-Object { Test-Path -Path $_ -PathType Leaf }
        if ( -not $scopeConfigFiles ) {
            New-Item -Path $searchPaths[0] -ItemType 'File' -Force | Write-Verbose
        }

        $config = [LibGit2Sharp.Configuration]::BuildFrom([nullstring]::Value, [nullstring]::Value)
        try {
            $config.Set($Name, $Value, $Scope)
        } finally {
            $config.Dispose()
        }
    }
}
