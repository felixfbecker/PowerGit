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

function Test-GitTag {
    <#
    .SYNOPSIS
    Tests if a tag exists in a Git repository.

    .DESCRIPTION
    The `Test-GitTag function tests if a tag exists in a Git repository.

    If a tag exists, returns $true; otherwise $false. Pass the name of the tag to check for to the `Name` parameter.

    .EXAMPLE
    Test-GitTag -Name 'Hello'

    Demonstrates how to check if the tag 'Hello' exists in the current directory.
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory = $true)]
        [string]
        # The name of the tag to check for.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $tag = Get-GitTag -RepoRoot $RepoRoot -Name $Name |
        Where-Object { $_.Name -eq $Name }

    return ($null -ne $tag)
}
