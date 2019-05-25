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

$repos = New-Object System.Collections.Generic.List[LibGit2Sharp.Repository]

function Clear-GitRepositoryCache {
    foreach ($repo in $repos) {
        $repo.Dispose()
    }
    $repos.Clear()
}

function Get-GitRepository {
    <#
    .SYNOPSIS
    Gets an object representing a Git repository.

    .DESCRIPTION
    The `Get-GitRepository` function gets a `LibGit2Sharp.Repository` object representing a Git repository. By default, it gets the current directory's repository. You can get an object for a specific repository using the `RepoRoot` parameter. If the `RepoRoot` path doesn't point to the root of a Git repository, or, if not using the `RepoRoot` parameter and the current directory isn't the root of a Git repository, you'll get an error.

    The repository object contains resources that don't get automatically removed from memory by .NET. To avoid memory leaks, you must call its `Dispose()` method when you're done using it.

    .EXAMPLE
    Get-GitRepository

    Demonstrates how to get a `LibGit2Sharp.Repository` object for the repository in the current directory.

    .EXAMPLE
    Get-GitRepository -RepoRoot 'C:\Projects\PowerGit'

    Demonstrates how to get a `LibGit2Sharp.Repository` object for a specific repository.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Repository])]
    param(
        # The root to the repository to get. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'

    $RepoRoot = Resolve-Path -Path $RepoRoot -ErrorAction Ignore | Select-Object -ExpandProperty 'ProviderPath'
    if (-not $RepoRoot) {
        Write-Error -Message ('Repository ''{0}'' does not exist.' -f $PSBoundParameters['RepoRoot'])
        return
    }

    if ($repoCache.ContainsKey($RepoRoot)) {
        $repoCache[$RepoRoot]
    } else {
        try {
            $repo = [LibGit2Sharp.Repository]::new($RepoRoot)
            $script:repos.Add($repo)
            $repo
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}
