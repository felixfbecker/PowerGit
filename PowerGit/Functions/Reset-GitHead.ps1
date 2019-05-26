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

function Reset-GitHead {
    <#
    .SYNOPSIS
    Reset current HEAD to the specified state
    .DESCRIPTION
    By default, resets the index but not the working tree (i.e., the changed
    files are preserved but not marked for commit) and reports what has not been
    updated.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Mixed')]
    [OutputType([LibGit2Sharp.Branch])]
    param(
        # Specifies which git repository to update. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # The revision to reset to, i.e. update the repository HEAD to.
        # A revision can be a specific commit ID/sha (short or long), branch name, tag name, etc.
        # Run git help gitrevisions or go to https://git-scm.com/docs/gitrevisions for full documentation on Git's revision syntax.
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('FriendlyName')]
        [Alias('HeadRef')] # PSGitHub.PullRequest
        [string] $Revision = 'HEAD',

        # Does not touch the index file or the working tree at all (but resets
        # the head to <commit>, just like all modes do). This leaves all your
        # changed files "Changes to be committed", as git status would put it.
        [Parameter(ParameterSetName = 'Soft')]
        [switch] $Soft,

        # Resets the index and working tree. Any changes to tracked files in the
        # working tree since <commit> are discarded.
        [Parameter(ParameterSetName = 'Hard')]
        [switch] $Hard
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if (-not $repo) {
        return
    }

    $cancel = $false
    try {
        $checkoutOptions = [LibGit2Sharp.CheckoutOptions]::new()
        $checkoutOptions.OnCheckoutNotify = {
            param([string]$Path, [LibGit2Sharp.CheckoutNotifyFlags]$NotifyFlags)
            Write-Information "$($NotifyFlags): $Path"
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        $checkoutOptions.OnCheckoutProgress = {
            param([string]$Path, [int]$CompletedSteps, [int]$TotalSteps)
            if ($ProgressPreference -ne 'SilentlyContinue' -and $TotalSteps -ne 0) {
                $progressParams = @{
                    Activity = 'Checking files out'
                }
                if ($TotalSteps -ne 0) {
                    $progressParams.PercentComplete = (($CompletedSteps / $TotalSteps) * 100)
                }
                if ($Path) {
                    $progressParams.Status = $Path
                }
                Write-Progress @progressParams
            }
        }
        $resetMode = if ($Soft) {
            [LibGit2Sharp.ResetMode]::Soft
        } elseif ($Hard) {
            [LibGit2Sharp.ResetMode]::Hard
        } else {
            [LibGit2Sharp.ResetMode]::Mixed
        }
        $commit = $repo.Lookup($Revision)
        $repo.Reset($resetMode, $commit, $checkoutOptions)
    } finally {
        $cancel = $true
        $repo.Dispose()
    }
}
