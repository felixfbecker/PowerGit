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

function Send-GitCommit {
    <#
    .SYNOPSIS
    Pushes commits from the current Git repository to its remote source repository.

    .DESCRIPTION
    The `Send-GitCommit` function sends all commits on the current branch of the local Git repository to its upstream remote repository. If you are pushing a new branch, use the `SetUpstream` switch to ensure Git tracks the new remote branch as a copy of the local branch.

    If the repository requires authentication, pass the username/password via the `Credential` parameter.

    Returns a `PowerGit.PushResult` that represents the result of the push. One of:

    * `Ok`: the push succeeded
    * `Failed`: the push failed.
    * `Rejected`: the push failed because there are changes on the branch that aren't present in the local repository. They should get pulled into the local repository and the push attempted again.

    This function implements the `git push` command.

    .EXAMPLE
    Send-GitCommit

    Pushes commits from the repository at the current location to its upstream remote repository

    .EXAMPLE
    Send-GitCommit -RepoRoot 'C:\Build\TestGitRepo' -Credential $PsCredential

    Pushes commits from the repository located at 'C:\Build\TestGitRepo' to its remote using authentication
    #>
    [CmdletBinding()]
    [OutputType([PowerGit.PushResult])]
    param(
        [string]
        # Specifies the location of the repository to synchronize. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [pscredential]
        # The credentials to use to connect to the source repository.
        $Credential,

        [Switch]
        # Add tracking information for any new branches pushed so Git sees the local branch and remote branch as the same.
        $SetUpstream
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify

    try {
        [LibGit2Sharp.Branch]$currentBranch = $repo.Branches | Where-Object { $_.IsCurrentRepositoryHead -eq $true }

        $result = Send-GitObject -RefSpec $currentBranch.CanonicalName -RepoRoot $RepoRoot -Credential $Credential

        if ( -not $SetUpstream -or $result -ne [PowerGit.PushResult]::Ok ) {
            return $result
        }

        # Setup tracking with the new remote branch.
        [void]$repo.Branches.Update($currentBranch, {
                param(
                    [LibGit2Sharp.BranchUpdater]
                    $Updater
                )

                $updater.Remote = 'origin'
                $updater.UpstreamBranch = $currentBranch.CanonicalName
            });

        return $result
    } finally {
        $repo.Dispose()
    }
}
