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

function Find-GitRepository {
    <#
    .SYNOPSIS
    Searches a directory and its parents for a Git repository.

    .DESCRIPTION
    The `Find-GitRepository` function searches a directory for a Git repository and returns a `LibGit2Sharp.Repository` object representing that repository. If a repository isn't found, it looks up the directory tree until it finds one (i.e. it looks at the directories parent directory, then that directory's parent, then that directory's parent, etc. until it finds a repository or gets to the root directory. If it doesn't find one, nothing is returned.

    With no parameters, looks in the current directory and up its directory tree. If given a path with the `Path` parameter, it looks in that directory then up its directory tree.

    The repository object that is returned contains resources that don't get automatically removed from memory by .NET. To avoid memory leaks, you must call its `Dispose()` method when you're done using it.

    .OUTPUTS
    LibGit2Sharp.Repository.

    .EXAMPLE
    Find-GitRepository

    Demonstrates how to find the Git repository of the current directory.

    .EXAMPLE
    Find-GitRepository -Path 'C:\Projects\PowerGit\PowerGit\bin'

    Demonstrates how to find the Git repository that a specific directory is a part of. In this case, a `LibGit2Sharp.Repository` object is returned for the repository at `C:\Projects\PowerGit`.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Repository])]
    param(
        # The path to start searching.
        [string] $Path = (Get-Location).ProviderPath,

        # Write an error if a repository isn't found. Usually, no error is written and nothing is returned when a repository isn't found.
        [Switch] $Verify
    )

    Set-StrictMode -Version 'Latest'

    if (-not $Path) {
        $Path = (Get-Location).ProviderPath
    }

    $Path = Resolve-Path -Path $Path -ErrorAction Ignore | Select-Object -ExpandProperty 'ProviderPath'
if (-not $Path) {
    Write-Error -Message ('Can''t find a repository in ''{0}'' because it does not exist.' -f $PSBoundParameters['Path'])
    return
}

$startedAt = $Path

while ($Path -and -not [LibGit2Sharp.Repository]::IsValid($Path)) {
    $Path = Split-Path -Parent -Path $Path
}

if (-not $Path) {
    if ($Verify) {
        Write-Error -Message ('Path ''{0}'' not in a Git repository.' -f $startedAt)
    }
    return
}

return Get-GitRepository -RepoRoot $Path
}
