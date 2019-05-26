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

$getTreeChanges = [LibGit2Sharp.Diff].GetMethod('Compare', [Type[]]@([LibGit2Sharp.Tree], [LibGit2Sharp.Tree])).MakeGenericMethod([LibGit2Sharp.TreeChanges])

function Compare-GitTree {
    <#
    .SYNOPSIS
    Gets a diff of the file tree changes in a repository between two commits.

    .DESCRIPTION
    The `Compare-GitTree` function returns a `LibGit2Sharp.TreeChanges` object representing the file tree changes in a repository between two commits. The tree changes are the names of the files that have been added, removed, modified, and renamed in a git repository.

    Pass the name of commits to diff, such as commit hash, branch name, or tag name, to the `ReferenceRevision` and `DifferenceRevision` parameters.

    You must specify a commit reference name for the `ReferenceRevision` parameter. The `DifferenceRevision` parameter is optional and defaults to `HEAD`.

    This function implements the `git diff --name-only` command.

    .EXAMPLE
    Compare-GitTree -ReferenceRevision 'HEAD^'

    Demonstrates how to get the diff between the default `HEAD` commit and its parent commit referenced by `HEAD^`.

    .EXAMPLE
    Compare-GitTree -RepoRoot 'C:\build\repo' -ReferenceRevision 'tags/1.0' -DifferenceRevision 'tags/2.0'

    Demonstrates how to get the diff between the commit tagged with `2.0` and the older commit tagged with `1.0` in the repository located at `C:\build\repo`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')] # needed to prevent enumerable expansion
    [CmdletBinding(DefaultParameterSetName = 'RepoRoot')]
    [OutputType([LibGit2Sharp.TreeChanges])]
    param(
        # The root path to the repository. Defaults to the current directory.
        [Parameter(ParameterSetName = 'RepoRoot')]
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # A commit to compare `DifferenceRevision` against, e.g. commit hash, branch name, tag name.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Sha')]
        [Alias('FriendlyName')]
        [Alias('ReferenceCommit')]
        [string] $ReferenceRevision,

        # A commit to compare `ReferenceRevision` against, e.g. commit hash, branch name, tag name. Defaults to `HEAD`.
        [Parameter()]
        [Alias('DifferenceCommit')]
        [string] $DifferenceRevision = 'HEAD'
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if (-not $repo) {
        Write-Error -Message ('Unable to get diff between ''{0}'' and ''{1}''. See previous errors for more details.' -f $ReferenceRevision, $DifferenceRevision)
        return
    }

    $oldCommit = $repo.Lookup($ReferenceRevision)
    $newCommit = $repo.Lookup($DifferenceRevision)

    if (-not $oldCommit) {
        Write-Error -Message ('Revision ''{0}'' not found in repository ''{1}''.' -f $ReferenceRevision, $repo.Info.WorkingDirectory)
        return
    } elseif (-not $newCommit) {
        Write-Error -Message ('Revision ''{0}'' not found in repository ''{1}''.' -f $DifferenceRevision, $repo.Info.WorkingDirectory)
        return
    }

    # use `,` to prevent unwrapping of enumerable TreeChanges type
    return , $script:getTreeChanges.Invoke($repo.Diff, @($oldCommit.Tree, $newCommit.Tree))
}
