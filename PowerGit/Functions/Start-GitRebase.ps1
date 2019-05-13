Import-Module "$PSScriptRoot/New-LibGit2SharpRebaseOptions.psm1" -Scope Local

function Start-GitRebase {
    [CmdletBinding()]
    param (
        # The commit to begin rebasing from, defaults to rebase all reachable commits
        # This is the current base of $Branch
        [Parameter(Position = 0)]
        [string] $Upstream,

        # The terminal commit to rebase, defaults to rebase the current branch
        # This is the branch that will be "moved"
        [Parameter(Position = 1)]
        [Alias('FriendlyName')]
        [Alias('HeadRef')] # PSGitHub.PullRequest
        [string] $Branch,

        # The branch to rebase onto, defaults to rebase onto the given upstream
        [string] $Onto,

        [Parameter()]
        [LibGit2Sharp.CheckoutFileConflictStrategy] $ConflictStrategy,

        [Parameter()]
        [string] $RepoRoot
    )

    process {
        $cancel = $false
        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }
        $branchObject = if ($Branch) { Get-GitBranch -Name $Branch } else { $null }
        $upstreamObject = if ($Upstream) { Get-GitBranch -Name $Upstream } else { $null }
        $ontoObject = if ($Onto) { Get-GitBranch -Name $Onto } else { $null }
        $committer = New-GitSignature -RepoRoot $RepoRooth
        $options = New-LibGit2SharpRebaseOptions
        $options.OnCheckoutNotify = {
            param([string]$Path, [LibGit2Sharp.CheckoutNotifyFlags]$NotifyFlags)
            Write-Information "$($NotifyFlags): $Path"
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        if ($PSBoundParameters.ContainsKey('ConflictStrategy')) {
            $options.FileConflictStrategy = $ConflictStrategy
        }
        try {
            $repo.Rebase.Start($branchObject, $upstreamObject, $ontoObject, $committer, $options)
        } finally {
            $cancel = $true
        }
    }
}
