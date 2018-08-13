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

function Test-GitCommit {
    <#
    .SYNOPSIS
    Tests if a Git revision exists.

    .DESCRIPTION
    The `Test-GitCommit` function tests if a commit exists. You pass the revision you want to check to the `Revision` parameter and the repository in the current working directory is checked. If a commit exists, the function returns `$true`. Otherwise, it returns `$false`.

    To test for a commit in a specific repository, pass the path to that repository to the `RepoRoot` parameter.

    .EXAMPLE
    Test-GitCommit -Revision 'feature/test-gitcommit'

    Demonstrates how to check if a branch exists. In this example, if the branch `feature/test-gitcommit` exists, `$true` is returned.

    .EXAMPLE
    Test-GitCommit -Revision 'deadbee'

    Demonstrates how to check if a commit exists using its partial SHA hash.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # A revision to test, e.g. a branch name, partial commit SHA hash, full commit SHA hash, tag name, etc.
        #
        # See https://git-scm.com/docs/gitrevisions for documentation on how to specify Git revisions.
        $Revision,

        [string]
        # The path to the repository. Defaults to the current directory.
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ( (Get-GitCommit -Revision $Revision -RepoRoot $RepoRoot -ErrorAction Ignore) ) {
        return $true
    }

    return $false
}