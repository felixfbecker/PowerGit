function Get-GitRemote {
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Remote])]
    param (
        [string] $RepoRoot,

        [Parameter(Position = 0)]
        [string] $Name
    )

    process {
        $repo = Find-GitRepository -Verify
        if (-not $repo) {
            return
        }
        if ($Name -and -not [WildcardPattern]::ContainsWildcardCharacters($Name)) {
            $repo.Network.Remotes[$Name]
        } else {
            $repo.Network.Remotes | Where-Object {
                -not $Name -or $_.Name -like $Name
            }
        }
    }
}
