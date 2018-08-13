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

function Compare-GitTree {
    <#
    .SYNOPSIS
    Gets a diff of the file tree changes in a repository between two commits.

    .DESCRIPTION
    The `Compare-GitTree` function returns a `LibGit2Sharp.TreeChanges` object representing the file tree changes in a repository between two commits. The tree changes are the names of the files that have been added, removed, modified, and renamed in a git repository.

    Pass the name of commits to diff, such as commit hash, branch name, or tag name, to the `ReferenceCommit` and `DifferenceCommit` parameters.

    You must specify a commit reference name for the `ReferenceCommit` parameter. The `DifferenceCommit` parameter is optional and defaults to `HEAD`.

    This function implements the `git diff --name-only` command.

    .EXAMPLE
    Compare-GitTree -ReferenceCommit 'HEAD^'

    Demonstrates how to get the diff between the default `HEAD` commit and its parent commit referenced by `HEAD^`.

    .EXAMPLE
    Compare-GitTree -RepoRoot 'C:\build\repo' -ReferenceCommit 'tags/1.0' -DifferenceCommit 'tags/2.0'

    Demonstrates how to get the diff between the commit tagged with `2.0` and the older commit tagged with `1.0` in the repository located at `C:\build\repo`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding(DefaultParameterSetName = 'RepositoryRoot')]
    [OutputType([LibGit2Sharp.TreeChanges])]
    param(
        [Parameter(ParameterSetName = 'RepositoryRoot')]
        [Alias('RepoRoot')]
        [string]
        # The root path to the repository. Defaults to the current directory.
        $RepositoryRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'RepositoryObject')]
        [LibGit2Sharp.Repository]
        $RepositoryObject,

        [Parameter(Mandatory = $true)]
        [string]
        # A commit to compare `DifferenceCommit` against, e.g. commit hash, branch name, tag name.
        $ReferenceCommit,

        [string]
        # A commit to compare `ReferenceCommit` against, e.g. commit hash, branch name, tag name. Defaults to `HEAD`.
        $DifferenceCommit = 'HEAD'
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($RepositoryObject) {
        $repo = $RepositoryObject
    } else {
        $repo = Find-GitRepository -Path $RepositoryRoot -Verify
        if (-not $repo) {
            Write-Error -Message ('Unable to get diff between ''{0}'' and ''{1}''. See previous errors for more details.' -f $ReferenceCommit, $DifferenceCommit)
            return
        }
    }

    try {
        $oldCommit = $repo.Lookup($ReferenceCommit)
        $newCommit = $repo.Lookup($DifferenceCommit)

        if (-not $oldCommit) {
            Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $ReferenceCommit, $repo.Info.WorkingDirectory)
            return
        } elseif (-not $newCommit) {
            Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $DifferenceCommit, $repo.Info.WorkingDirectory)
            return
        }

        # use `,` to prevent unwrapping of enumerable TreeChanges type
        return , [GitAutomationCore.Diff]::GetTreeChanges($repo, $oldCommit, $newCommit)
    } finally {
        if (-not $RepositoryObject) {
            Invoke-Command -NoNewScope -ScriptBlock {
                $repo.Dispose()
            }
        }
    }
}
