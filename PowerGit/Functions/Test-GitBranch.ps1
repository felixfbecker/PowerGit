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

function Test-GitBranch {
    <#
    .SYNOPSIS
    Checks if a branch exists in a Git repository.

    .DESCRIPTION
    The `Test-GitBranch` command tests if a branch exists in a Git repository. It returns $true if a branch exists; $false otherwise.

    Pass the branch name to test to the `Name` parameter

    .EXAMPLE
    Test-GitBranch -Name 'develop'

    Demonstrates how to check if the 'develop' branch exists in the current directory.

    .EXAMPLE
    Test-GitBranch -RepoRoot 'C:\Projects\PowerGit' -Name 'develop'

    Demonstrates how to check if the 'develop' branch exists in a specific repository.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        # The name of the branch.
        [Parameter(Mandatory)]
        [string] $Name
    )

    Set-StrictMode -Version 'Latest'

    return [bool](Get-GitBranch -RepoRoot $RepoRoot | Where-Object { $_.FriendlyName -ceq $Name })
}
