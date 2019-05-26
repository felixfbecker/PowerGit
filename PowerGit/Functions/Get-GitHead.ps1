function Get-GitHead {
    <#
    .SYNOPSIS
    Gets the currently checked-out branch of the repository.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Branch])]
    param ([string] $RepoRoot = (Get-Location).ProviderPath)

    process {
        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }
        $repo.Head
    }
}
