function Remove-GitRemote {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([LibGit2Sharp.Remote])]
    param (
        [string] $RepoRoot,

        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    process {
        $repo = Find-GitRepository -Verify
        if (-not $repo) {
            return
        }

        $shouldProcessCaption = "Deleting git remote"
        $shouldProcessDescription = "Deleting the git remote `"$Name`" in the repository `"$($repo.RepositoryName)`"."
        $shouldProcessWarning = "Do you want to create the git remote `"$Name`" in the repository `"$($repo.RepositoryName)`"?"

        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption)) {
            $repo.Network.Remotes.Remove($Name)
        }
    }
}
