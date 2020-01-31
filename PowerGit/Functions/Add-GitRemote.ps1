function Add-GitRemote {
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Remote])]
    param (
        [string] $RepoRoot,

        # Name of the new remote
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # URL for the new remote
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $Url
    )

    process {
        $repo = Find-GitRepository -Verify
        if (-not $repo) {
            return
        }
        try {
            $repo.Network.Remotes.Add($Name, $Url)
        } catch {
            Write-Error -Exception $_.Exception
        }
    }
}
