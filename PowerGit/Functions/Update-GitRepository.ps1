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

function Update-GitRepository {
    <#
    .SYNOPSIS
    Updates the working directory of a Git repository to a specific commit.

    .DESCRIPTION
    The `Update-GitRepository` function updates a Git repository to a specific commit, i.e. it checks out a specific commit.

    The default target is "HEAD". Use the `Revision` parameter to specifiy a different branch, tag, commit, etc. If you specify a branch name, and there isn't a local branch by that name, but there is a remote branch, this function creates a new local branch that tracks the remote branch.

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    Use the `Force` switch to remove any uncommitted/unstaged changes during the checkout. Otherwise, the update will fail.

    This function implements the `git checkout <target>` command.

    .EXAMPLE
    Update-GitRepository -RepoRoot 'C:\Projects\GitAutomationCore' -Revision 'feature/ticket'

    Demonstrates how to checkout the 'feature/ticket' branch of the given repository.

    .EXAMPLE
    Update-GitRepository -RepoRoot 'C:\Projects\GitAutomationCore' -Revision 'refs/tags/tag1'

    Demonstrates how to create a detached head at the tag 'tag1'.

    .EXAMPLE
    Update-GitRepository -RepoRoot 'C:\Projects\GitAutomationCore' -Revision 'develop' -Force

    Demonstrates how to remove any uncommitted changes during the checkout by using the `Force` switch.
    #>

    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Branch])]
    param(
        [string]
        # Specifies which git repository to update. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [string]
        # The revision checkout, i.e. update the repository to. A revision can be a specific commit ID/sha (short or long), branch name, tag name, etc. Run git help gitrevisions or go to https://git-scm.com/docs/gitrevisions for full documentation on Git's revision syntax.
        $Revision = "HEAD",

        [Switch]
        # Remove any uncommitted changes when checking out/updating to `Revision`.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if ( -not $repo ) {
        return
    }

    try {
        $checkoutOptions = New-Object -TypeName 'LibGit2Sharp.CheckoutOptions'
        if ( $Force ) {
            $checkoutOptions.CheckoutModifiers = [LibGit2Sharp.CheckoutModifiers]::Force
        }

        $branch = $repo.Branches[$Revision]
        if ( -not $branch ) {
            [LibGit2Sharp.Branch]$remoteBranch = $repo.Branches | Where-Object { $_.UpstreamBranchCanonicalName -eq ('refs/heads/{0}' -f $Revision) }
            if ( $remoteBranch ) {
                $branch = $repo.Branches.Add($Revision, $remoteBranch.Tip.Sha)
                $repo.Branches.Update($branch, {
                        param(
                            [LibGit2Sharp.BranchUpdater]
                            $Updater
                        )

                        $Updater.TrackedBranch = $remoteBranch.CanonicalName
                    })
            }
        }

        [LibGit2Sharp.Commands]::Checkout($repo, $Revision, $checkoutOptions)
    } finally {
        $repo.Dispose()
    }
}
