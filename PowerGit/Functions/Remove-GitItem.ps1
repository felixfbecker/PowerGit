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

function Remove-GitItem {
    <#
    .SYNOPSIS
    Function to Remove files from both working directory and in the repository

    .DESCRIPTION
    This function will delete the files from the working directory and stage the files to be deleted in the next commit. Multiple filepaths can be passed at once.

    .EXAMPLE
    Remove-GitItem -RepoRoot $repoRoot -Path 'file.ps1'

    .Example
    Remove-GitItem -Path 'file.ps1'

    .Example
    Get-ChildItem '.\PowerGit\Functions','.\Tests' | Remove-GitItem

    #>

    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [String[]]
        # The paths to the files/directories to remove in the next commit.
        $Path,

        [string]
        # The path to the repository where the files should be removed. The default is the current directory as returned by Get-Location.
        $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify

    if (-not $repo) {
        return
    }

    foreach ( $pathItem in $Path ) {
        if (-not [IO.Path]::IsPathRooted($pathItem)) {
            $pathItem = Join-Path -Path $repo.Info.WorkingDirectory -ChildPath $pathItem
        }
        [LibGit2Sharp.Commands]::Remove($repo, $pathItem, $true)
    }
    $repo.Dispose()
}
