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

function Send-GitBranch {
    <#
    .SYNOPSIS
    Pushes commits from the current git branch to its remote repository.

    .DESCRIPTION
    The `Send-GitBranch` function sends all commits on the current branch of the
    local Git repository to its upstream remote repository. If you are pushing a
    new branch, use the `SetUpstream` switch to ensure Git tracks the new remote
    branch as a copy of the local branch.

    If the repository requires authentication, pass the username/password via
    the `Credential` parameter.

    This function implements the `git push` command.

    .EXAMPLE
    Send-GitBranch

    Pushes commits from the repository at the current location to its upstream
    remote repository

    .EXAMPLE
    Send-GitBranch -RepoRoot 'C:\Build\TestGitRepo' -Credential $PsCredential

    Pushes commits from the repository located at 'C:\Build\TestGitRepo' to its
    remote using authentication
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Branch])]
    param(
        [Parameter(ValueFromPipeline)]
        [LibGit2Sharp.Branch] $InputObject,

        # The remote to push the branch to
        [Parameter(Position = 0)]
        [string] $Remote,

        # The name of the branch to push
        [Parameter(Position = 1)]
        [string] $Name,

        # Specifies the location of the repository to synchronize. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # Add tracking information for any new branches pushed so Git sees the local branch and remote branch as the same.
        [Alias('u')]
        [switch] $SetUpstream,

        # Usually, the command refuses to update a remote ref that is not an ancestor of the local ref used to overwrite it.
        # This flag disables this check by prefixing all refspecs with "+".
        [switch] $Force,

        # The credentials to use to connect to the source repository.
        [pscredential] $Credential
    )

    process {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if (-not $InputObject) {
            $InputObject = if ($Name) {
                Get-GitBranch -RepoRoot $RepoRoot -Name $Name
            } else {
                Get-GitHead -RepoRoot $RepoRoot
            }
        }
        $sendParams = @{
            RepoRoot = $RepoRoot
            SetUpstream = [bool]$SetUpstream
            Force = [bool]$Force
        }
        if ($Credential) {
            $sendParams.Credential = $Credential
        }
        if ($Remote) {
            $sendParams.Remote = $Remote
        }
        if (-not $InputObject) {
            Write-Warning "No git branch matching $Name"
            return
        }
        $InputObject | Send-GitObject @sendParams
    }
}
