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

function Test-GitUncommittedChange {
    <#
    .SYNOPSIS
    Tests for uncommitted changes in a git repository.

    .DESCRIPTION
    The `Test-GitUncommittedChange` function checks for any uncommited changes in a git repository.

    It defaults to the current repository and only the current branch. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    Implements the `git diff --exit-code` command ( No output if no uncommitted changes, otherwise output diff )

    .EXAMPLE
    Test-GitUncommittedChange -RepoRoot 'C:\Projects\GitAutomationCore'

    Demonstrates how to check for uncommitted changes in a repository that isn't the current directory.
    #>

    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [string]
        # The repository to check for uncommitted changes. Defaults to current directory
        $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'

    if ( Get-GitRepositoryStatus -RepoRoot $RepoRoot ) {
        return $true
    }

    return $false
}
