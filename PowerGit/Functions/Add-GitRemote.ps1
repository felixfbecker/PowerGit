function Add-GitRemote {
    <#
    .INPUTS
    PSGitHub.Repository. You can pipe the output of Get-GitHubRepository, New-GitHubRepository or Start-GitHubFork.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Remote])]
    param (
        [string] $RepoRoot,

        # Name of the new remote
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Parameters')]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # URL for the new remote
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Parameters')]
        [ValidateNotNullOrEmpty()]
        [string] $Url,

        [Parameter(Mandatory, ValueFromPipeline, DontShow, ParameterSetName = 'Input')]
        [psobject] $Input
    )

    process {
        # PSGitHub support
        if ($PSCmdlet.ParameterSetName -eq 'Input') {
            $Name = $Input.Owner
            $Url = $Input.CloneUrl
        }
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
