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

function Test-GitRemoteUri {
    <#
    .SYNOPSIS
    Tests if the uri leads to a git repository

    .DESCRIPTION
    The `Test-GitRemoteUri` tries to list remote references for the specified uri. A uri that is not a git repo will throw a LibGit2SharpException.

    This function is similar to `git ls-remote` but returns a bool based on if there is any output

    .EXAMPLE
    Test-GitRemoteUri -Uri 'ssh://git@stash.portal.webmd.com:7999/whs/blah.git'

    Demonstrates how to check if there is a repo at the specified uri
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The uri to test
        $Uri
    )

    Set-StrictMode -Version 'Latest'

    try {
        [LibGit2Sharp.Repository]::ListRemoteReferences($Uri) | Out-Null
    } catch [LibGit2Sharp.LibGit2SharpException] {
        return $false
    }
    return $true
}
