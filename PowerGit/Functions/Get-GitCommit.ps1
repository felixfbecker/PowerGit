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

function Get-GitCommit {
    <#
    .SYNOPSIS
    Gets the sha-1 ID for specific changes in a Git repository.

    .DESCRIPTION
    The `Get-GitCommit` gets all the commits in a repository, from most recent to oldest.

    To get a commit for a specific named revision, e.g. HEAD, a branch, a tag), pass the name to the `Revision` parameter.

    To get the commit of the current checkout, pass `HEAD` to the `Revision` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([PowerGit.CommitInfo])]
    param(
        [Parameter(ParameterSetName = 'All')]
        [switch]
        # Get all the commits in the repository.
        $All,

        [Parameter(Mandatory = $true, ParameterSetName = 'Lookup')]
        [string]
        # A named revision to get, e.g. `HEAD`, a branch name, tag name, etc.
        # To get the commit of the current checkout, pass `HEAD`.
        $Revision,

        [Parameter(ParameterSetName = 'CommitFilter')]
        [string]
        # The starting commit from which to generate a list of commits. Defaults to `HEAD`.
        $Since = 'HEAD',

        [Parameter(Mandatory = $true, ParameterSetName = 'CommitFilter')]
        [string]
        # The commit and its ancestors which will be excluded from the returned commit list which starts at `Since`.
        $Until,

        [Parameter(ParameterSetName = 'CommitFilter')]
        [switch]
        # Do not include any merge commits in the generated commit list.
        $NoMerges,

        [switch]
        # Include the patch for each commit.
        $Patch,

        [string]
        # The path to the repository. Defaults to the current directory.
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot
    if ( -not $repo ) {
        return
    }

    try {
        $commits = if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            $filter = New-Object -TypeName 'LibGit2Sharp.CommitFilter'
            $filter.IncludeReachableFrom = $repo.Refs
            $repo.Commits.QueryBy($filter)
        } elseif ( $PSCmdlet.ParameterSetName -eq 'Lookup' ) {
            $change = $repo.Lookup($Revision)
            if ( $change ) {
                $change
            } else {
                Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Revision, $repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
                return
            }
        } elseif ( $PSCmdlet.ParameterSetName -eq 'CommitFilter') {
            $IncludeFromCommit = $repo.Lookup($Since)
            $ExcludeFromCommit = $repo.Lookup($Until)

            if (-not $IncludeFromCommit) {
                Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Since, $repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
                return
            } elseif (-not $ExcludeFromCommit) {
                Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Until, $repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
                return
            } elseif ($IncludeFromCommit.Sha -eq $ExcludeFromCommit.Sha) {
                Write-Error -Message ('Commit reference ''{0}'' and ''{1}'' refer to the same commit with hash ''{2}''.' -f $Since, $Until, $IncludeFromCommit.Sha)
                return
            }

            $CommitFilter = New-Object -TypeName LibGit2Sharp.CommitFilter
            $CommitFilter.IncludeReachableFrom = $IncludeFromCommit.Sha
            $CommitFilter.ExcludeReachableFrom = $ExcludeFromCommit.Sha

            $filteredCommits = $repo.Commits.QueryBy($CommitFilter)

            if ($NoMerges) {
                $filteredCommits = $filteredCommits | Where-Object { $_.Parents.Count -le 1 }
            }

            $filteredCommits
        }
        $commits | ForEach-Object {
            [LibGit2Sharp.Patch]$patchObj = $null
            if ($Patch) {
                $parent = [System.Linq.Enumerable]::FirstOrDefault($_.Parents)
                if ($parent) {
                    $patchObj = [PowerGit.Diff]::GetTreePatch($repo, $_, $parent)
                }
            }
            [PowerGit.CommitInfo]::new($_, $patchObj)
        }
    } finally {
        $repo.Dispose()
    }
}
