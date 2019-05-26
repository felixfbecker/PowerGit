Import-Module "$PSScriptRoot/New-LibGit2SharpRebaseOptions.psm1" -Scope Local

function Stop-GitRebase {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $RepoRoot
    )

    process {
        $cancel = $false
        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }
        $options = New-LibGit2SharpRebaseOptions
        $options.OnCheckoutNotify = {
            param([string]$Path, [LibGit2Sharp.CheckoutNotifyFlags]$NotifyFlags)
            Write-Information "$($NotifyFlags): $Path"
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        try {
            $repo.Rebase.Abort($options)
        } finally {
            $cancel = $true
        }
    }
}
