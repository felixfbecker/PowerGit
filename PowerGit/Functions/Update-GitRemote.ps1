function Update-GitRemote {
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Remote])]
    param (
        [string] $RepoRoot,

        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Name,

        # Pipe in PSGitHub.Repository
        [Parameter(ValueFromPipelineByPropertyName, DontShow)]
        [string] $CloneUrl,

        [string] $Url,

        [string] $PushUrl,
        [LibGit2Sharp.TagFetchMode] $TagFetchMode
    )

    process {
        $repo = Find-GitRepository -Verify
        if (-not $repo) {
            return
        }
        $outerParams = $PSBoundParameters
        $repo.Network.Remotes.Update($Name, @( {
                    param([LibGit2Sharp.RemoteUpdater] $updater)
                    if ($outerParams.ContainsKey('Url')) {
                        $updater.Url = $Url
                    }
                    if ($outerParams.ContainsKey('CloneUrl')) {
                        $updater.Url = $CloneUrl
                    }
                    if ($outerParams.ContainsKey('PushUrl')) {
                        $updater.PushUrl = $PushUrl
                    }
                    if ($outerParams.ContainsKey('TagFetchMode')) {
                        $updater.TagFetchMode = $TagFetchMode
                    }
                }))
        $repo.Network.Remotes[$Name]
    }
}
