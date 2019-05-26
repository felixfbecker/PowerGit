Import-Module "$PSScriptRoot/New-LibGit2SharpRebaseOptions.psm1" -Scope Local

function Resume-GitRebase {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $RepoRoot,

        [Parameter()]
        [LibGit2Sharp.CheckoutFileConflictStrategy] $ConflictStrategy
    )

    process {
        $cancel = $false
        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }
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
            $repo.Rebase.Continue($committer, $options)
        } finally {
            $cancel = $true
        }
    }
}
