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

function Add-GitItem {
    <#
    .SYNOPSIS
    Promotes changes to the Git staging area so they can be saved during the next commit.

    .DESCRIPTION
    The `Add-GitItem` function promotes new/untracked and modified files to the Git staging area. When committing changes, by default Git only commits changes that have been staged. Use this function on each file you want to commit before committing. No other files will be committed.

    Use the `PassThru` switch to get `IO.FileInfo` and `IO.DirectoryInfo` objects back for each file and directory added, respectively. If the items are already added or were unmodified and not added to the staging area, you'll still get objects back for them.

    This function implements the `git add` command.

    .LINK
    Save-GitCommit

    .EXAMPLE
    Add-GitItem -Path 'C:\Projects\GitAutomationCore'

    Demonstrates how to add all the items under a directory to the next commit to the repository in the current directory.

    .EXAMPLE
    Add-GitItem -Path 'C:\Projects\GitAutomationCore\Functions\Add-GitItem.ps1','C:\Projects\GitAutomationCore\Tests\Add-GitItem.Tests.ps1'

    Demonstrates how to add multiple items and files to the next commit.

    .EXAMPLE
    Get-ChildItem '.\GitAutomationCore\Functions','.\Tests' | Add-GitItem

    Demonstrates that you can pipe paths or file system objects to Add-GitItem. When passing directories, all untracked/new or modified files under that directory are added. When passing files, only that file is added.

    .EXAMPLE
    Add-GitItem -Path 'C:\Projects\GitAutomationCore' -RepoRoot 'C:\Projects\GitAutomationCore'

    Demonstrates how to operate on a repository that isn't the current directory.

    .EXAMPLE
    Get-ChildItem | Add-GitItem

    Demonstrates that you can pipe `IO.FileInfo` and `IO.DirectoryInfo` objects to `Add-GitItem`. Plain strings are also allowed.

    .EXAMPLE
    Add-GitItem -Path 'file1','directory1' -PassThru

    Demonstrates how to get `IO.FileInfo` and `IO.DirectoryInfo` objects returned for each file and directory, respectively.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string[]]
        # The paths to the files/directories to add to the next commit.
        $Path,

        [string]
        # The path to the repository where the files should be added. The default is the current directory as returned by Get-Location.
        $RepoRoot = (Get-Location).ProviderPath,

        [Switch]
        # Return `IO.FileInfo` and/or `IO.DirectoryInfo` objects for each file and/or directory added, respectively.
        $PassThru
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $repo = Find-GitRepository -Path $RepoRoot -Verify
    }

    process {
        if ( -not ((Test-Path -Path 'variable:repo') -and $repo) ) {
            return
        }

        foreach ( $pathItem in $Path ) {
            if ( -not [IO.Path]::IsPathRooted($pathItem) ) {
                $pathItem = Join-Path -Path $repo.Info.WorkingDirectory -ChildPath $pathItem -Resolve
                if ( -not $pathItem ) {
                    continue
                }
            }

            if ( -not (Test-Path -Path $pathItem) ) {
                Write-Error -Message ('Cannot find path ''{0}'' because it does not exist.' -f $pathItem)
                continue
            }

            $pathItem = (Resolve-RealPath $pathItem)

            $strComparison = if ($IsWindows) { [stringcomparison]::InvariantCultureIgnoreCase } else { [stringcomparison]::InvariantCulture }
            if (-not $pathItem.StartsWith($repo.Info.WorkingDirectory, $strComparison)) {
                Write-Error -Message ('Item ''{0}'' can''t be added because it is not in the repository ''{1}''.' -f $pathItem, $repo.Info.WorkingDirectory)
                continue
            }

            [LibGit2Sharp.Commands]::Stage($repo, $pathItem)

            if ( $PassThru ) {
                Get-Item -Path $pathItem
            }
        }
    }

    end {
        if ( ((Test-Path -Path 'variable:repo') -and $repo) ) {
            $repo.Dispose()
        }
    }
}
