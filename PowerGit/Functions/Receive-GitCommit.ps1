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

function Receive-GitCommit {
    <#
    .SYNOPSIS
    Downloads all branches (and their commits) from remote repositories.

    .DESCRIPTION
    The `Recieve-GitCommit` function gets all the commits on all branches from all remote repositories and brings them into your repository.

    It defaults to the repository in the current directory. Pass the path to a different repository to the `RepoRoot` parameter.

    This function implements the `git fetch` command.

    .EXAMPLE
    Receive-GitCommit

    Demonstrates how to get all branches from a remote repository.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The repository to fetch updates for. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if ( -not $repo ) {
        return
    }

    try {
        $fetchOptions = New-Object 'LibGit2Sharp.FetchOptions'
        foreach ( $remote in $repo.Network.Remotes ) {
            [string[]]$refspecs = $remote.FetchRefSpecs | Select-Object -ExpandProperty 'Specification'
            [LibGit2Sharp.Commands]::Fetch($repo, $remote.Name, $refspecs, $fetchOptions, $null)
        }
    } finally {
        $repo.Dispose()
    }
}