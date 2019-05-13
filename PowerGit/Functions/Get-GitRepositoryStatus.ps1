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

function Get-GitRepositoryStatus {
    <#
    .SYNOPSIS
    Gets information about all added, untracked, and modified files in a repository.

    .DESCRIPTION
    The `Get-GitRepositoryStatus` commands gets information about which files in your working directory are new, untracked, or modified, including files that have been staged for the next commit. It gets information about each uncommitted change in your repository.

    Ignored items are not returned unless you provide the `IncludeIgnored` switch.

    You can get status for specific files and directories with the Path parameter. If you provide a `RepoRoot` parameter to work with a specific repository, the values of the `Path` parameter should be relative to the root of that repository. With no `RepoRoot` parameter, the paths in the `Path` parameter are treated as relative to the current directory. Wildcards are supported and are passed directly to Git to evaluate (i.e. use Git wildcard syntax not PowerShell's).

    The `LibGit2Sharp.StatusEntry` objects returned have several extended type data members added. You should use these members instead of using the object's `State` property.

     * `IsStaged`: `$true` if the item has been staged for the next commit; `$false` otherwise.
     * `IsAdded`: returns `$true` if the item is new in the working directory or has been staged for the next commit; `$false` otherwise.
     * `IsConflicted`: returns `$true` if the item was merged and currently has conflicts; `$false` otherwise.
     * `IsDeleted`: returns `$true` if the item was deleted from the working directory or has been staged for removal in the next commit; `$false` otherwise.
     * `IsIgnored`: returns `$true` if the item is ignored; `$false` otherwise. You'll only see ignored items if you use the `IncludeIgnored` switch.
     * `IsModified`: returns `$true` if the item is modified; `$false` otherwise.
     * `IsRenamed`: returns `$true` if the item was renamed; `$false` otherwise.
     * `IsTypeChanged`: returns `$true` if the item's type was changed; `$false` otherwise.
     * `IsUnchanged`: returns `$true` if the item is unchanged; `$false` otherwise.
     * `IsUnreadable`: returns `$true` if the item is unreadable; `$false` otherwise.
     * `IsUntracked`: returns `$true` if the item is untracked (i.e. hasn't been staged or added to the repository); `$false` otherwise.

    When displayed in a table (the default), the first column will show characters that indicate the state of each item, e.g.

        State    FilePath
        -----    --------
         a       PowerGit\Formats\LibGit2Sharp.StatusEntry.ps1xml
         a       PowerGit\Functions\Get-GitRepositoryStatus.ps1
          m      PowerGit\PowerGit.psd1
         a       PowerGit\Types\LibGit2Sharp.StatusEntry.types.ps1xml
         a       Tests\Get-GitRepositoryStatus.Tests.ps1

    The state will display:

     * `i` if the item is ignored (i.e. `IsIgnored` returns `$true`)
     * `a` if the item is untracked or staged for the next commit (i.e. `IsAdded` returns `$true`)
     * `m` if the item was modified (i.e. `IsModified` returns `$true`)
     * `d` if the item was deleted (i.e. `IsDeleted` returns `$true`)
     * `r` if the item was renamed (i.e. `IsRenamed` returns `$true`)
     * `t` if the item's type was changed (i.e. `IsTypeChanged` returns `$true`)
     * `?` if the item can't be read (i.e. `IsUnreadable` returns `$true`)
     * `!` if the item was merged with conflicts (i.e. `IsConflicted` return `$true`)

    If no state characters are shown, the file is unchanged (i.e. `IsUnchanged` return `$true`).

    This function implements the `git status` command.


    .EXAMPLE
    Get-GitRepositoryStatus

    Demonstrates how to get the status of any uncommitted changes for the repository in the current directory.

    .EXAMPLE
    Get-GitRepositoryStatus -RepoRoot 'C:\Projects\PowerGit'

    Demonstrates how to get the status of any uncommitted changes for the repository at a specific location.

    .EXAMPLE
    Get-GitRepositoryStatus -Path 'build.ps1','*.cs'

    Demonstrates how to get the status for specific files at or under the current directory using the Path parameter. In this case, only modified files named `build.ps1` or that match the wildcard `*.cs` under the current directory will be returned.

    .EXAMPLE
    Get-GitRepositoryStatus -Path 'build.ps1','*.cs' -RepoRoot 'C:\Projects\PowerGit`

    Demonstrates how to get the status for specific files under the root of a specific repository. In this case, only modified files named `build.ps1` or that match the wildcard `*.cs` under `C:\Projects\PowerGit` will be returned.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.StatusEntry])]
    param(
        [Parameter(Position = 0)]
        # The path to specific files and/or directories whose status to get. Git-style wildcards are supported.
        #
        # If no `RepoRoot` parameter is provided, these paths are evaluated as relative to the current directory. If a `RepoRoot` parameter is provided, these paths are evaluated as relative to the root of that repository.
        [string[]] $Path,

        # Return ignored files and directories. The default is to not return them.
        [Switch] $IncludeIgnored,

        # The path to the repository whose status to get.
        [string] $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if (-not $repo) {
        return
    }

    try {
        $statusOptions = [LibGit2Sharp.StatusOptions]::new()

        if ($IncludeIgnored) {
            $statusOptions.RecurseIgnoredDirs = $true
        }

        $currentLocation = (Get-Location).ProviderPath
        if (-not $currentLocation.EndsWith([IO.Path]::DirectorySeparatorChar)) {
            $currentLocation = '{0}{1}' -f $currentLocation, [IO.Path]::DirectorySeparatorChar
        }

        if (-not $currentLocation.StartsWith($repo.Info.WorkingDirectory)) {
            Push-Location -Path $repo.Info.WorkingDirectory -StackName 'Get-GitRepositoryStatus'
        }

        $repoRootRegex = $repo.Info.WorkingDirectory.TrimEnd([IO.Path]::DirectorySeparatorChar)
        $repoRootRegex = '^' + ([regex]::Escape($repoRootRegex)) + [regex]::Escape([IO.Path]::DirectorySeparatorChar) + '?'

        try {
            if ($Path) {
                Write-Verbose "repoRootRegex $repoRootRegex"
                $statusOptions.PathSpec = $Path |
                    ForEach-Object {
                        $pathItem = $_

                        if ([IO.Path]::IsPathRooted($_)) {
                            return $_
                        }

                        $fullPath = Join-Path -Path (Get-Location).ProviderPath -ChildPath $_
                        try {
                            return [IO.Path]::GetFullPath($fullPath)
                        } catch {
                            return $pathItem
                        }
                    } |
                    ForEach-Object { $_ -replace $repoRootRegex, '' } |
                    ForEach-Object { $_ -replace ([regex]::Escape([IO.Path]::DirectorySeparatorChar)), '/' }
                Write-Verbose "PathSpec $($statusOptions.PathSpec)"
            }

            $status = $repo.RetrieveStatus($statusOptions)
            if (-not $status.IsDirty) {
                Write-Information "Nothing to commit, working tree clean"
                return
            }
            $status | Where-Object {
                if ($IncludeIgnored) {
                    return $true
                }
                return -not $_.IsIgnored
            }
    } finally {
        Pop-Location -StackName 'Get-GitRepositoryStatus' -ErrorAction Ignore
    }
} finally {
    $repo.Dispose()
}
}

Set-Alias -Name Get-GitStatus -Value Get-GitRepositoryStatus
