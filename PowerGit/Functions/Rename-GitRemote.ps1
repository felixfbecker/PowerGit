function Rename-GitRemote {
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Remote])]
    param (
        [string] $RepoRoot,

        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $NewName
    )

    process {
        $repo = Find-GitRepository -Verify
        if (-not $repo) {
            return
        }
        $repo.Network.Remotes.Rename($Name, $NewName, {
                param([string] $problematicRefSpec)
                Write-Warning "Refspec $problematicRefSpec was not updated automatically because it didn't match the default."
            })
    }
}
