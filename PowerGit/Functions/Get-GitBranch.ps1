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

function Get-GitBranch {
    <#
   .SYNOPSIS
   Gets the branches in a Git repository.

   .DESCRIPTION
   The `Get-GitBranch` function returns a list of all the branches in a repository.

   Use the `Current` switch to return just the current branch.

   It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

   .EXAMPLE
   Get-GitBranch -RepoRoot 'C:\Projects\PowerGit' -Current

   Returns an object representing the current branch for the specified repo.

   .EXAMPLE
   Get-GitBranch

   Returns objects for all the branches in the current directory.
   #>
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    [OutputType([LibGit2Sharp.Branch])]
    param(
        # Specifies which git repository to check. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # The name of the branch. Supports wildcards.
        [Parameter(Position = 0)]
        [string] $Name,

        # Get the current branch only. Otherwise all branches are returned.
        [Parameter(Mandatory, ParameterSetName = 'Current')]
        [switch] $Current,

        # Get remote branches only
        [Parameter(Mandatory, ParameterSetName = 'Remote')]
        [switch] $Remote,

        # Get all branches including remote
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if (-not $repo) {
        return
    }

    if ($Current -or $Name -eq 'HEAD') {
        $repo.Head
    } elseif ($Name -and -not [WildcardPattern]::ContainsWildcardCharacters($Name)) {
        $repo.Branches[$Name]
    } else {
        $repo.Branches | Where-Object {
            ($All -or ($Remote -eq $_.IsRemote)) -and (-not $Name -or $_.FriendlyName -like $Name)
        }
    }
}
