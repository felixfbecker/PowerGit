function Remove-GitBranch {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([LibGit2Sharp.Branch])]
    param(
        # Specifies which git repository to check. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # The name of the branch. Supports wildcards.
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('CanonicalName')]
        [string] $Name
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }
    }

    process {
        $branch = $repo.Branches[$Name]
        if ($null -eq $branch) {
            Write-Error "Branch '$Name' not found."
            return
        }

        $shouldProcessCaption = "Removing git branch"
        $shouldProcessDescription = "Removing the branch `e[1m$Name`e[0m in the repository $RepoRoot."
        $shouldProcessWarning = "Do you want to remove the branch `e[1m$Name`e[0m in the repository $($RepoRoot)?"
        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption)) {
            try {
                $repo.Branches.Remove($branch)
                Write-Information "Deleted branch '$Name'"
            } catch {
                Write-Error -ErrorRecord $_
            }
        }
    }
}
