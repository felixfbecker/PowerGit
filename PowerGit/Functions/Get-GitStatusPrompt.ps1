function Get-GitStatusPrompt {
    <#
    .SYNOPSIS
    Returns a git prompt.

    .DESCRIPTION
    Returns a string colored with ANSI escape sequences that contains a git status summary.
    To be used in a custom prompt() function.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $repo = Find-GitRepository
    if ($repo) {
        $promptText += "`e[33m[`e[0m"

        # current branch
        $branch = $repo.Head
        $branchText = $branch.FriendlyName

        # tracking status
        if ($branch.IsTracking) {
            if ($branch.TrackedBranch.IsGone) {
                $branchText += " ×"
            } else {
                if ($branch.TrackingDetails.AheadBy) {
                    $branchText += " ↑" + $branch.TrackingDetails.AheadBy
                }
                if ($branch.TrackingDetails.BehindBy) {
                    $branchText += " ↓" + $branch.TrackingDetails.BehindBy
                }
                if (-not $branch.TrackingDetails.AheadBy -and -not $branch.TrackingDetails.BehindBy) {
                    $branchText += " ≡"
                }
            }
        }
        $color = if ($branch.IsTracking -and $branch.TrackingDetails.AheadBy -and $branch.TrackingDetails.BehindBy) {
            "`e[33m"
        } elseif ($branch.IsTracking -and $branch.TrackingDetails.AheadBy) {
            "`e[32m"
        } elseif ($branch.IsTracking -and $branch.TrackingDetails.BehindBy) {
            "`e[31m"
        } else {
            "`e[36m"
        }
        $promptText += "$color$branchText`e[0m"

        # workdir and index status
        $status = Get-GitStatus 6>$null
        if ($status) {
            $counts = @{ }
            $indexIsDirty = $false
            $workDirIsDirty = $false
            foreach ($flag in [Enum]::GetValues([FileStatus])) {
                $counts[$flag] = 0
            }
            foreach ($file in $status) {
                foreach ($flag in [Enum]::GetValues([FileStatus])) {
                    if ($file.State.HasFlag($flag)) {
                        $counts[$flag]++
                    }
                }
                if ($null -ne $file.IndexChange) {
                    $indexIsDirty = $true
                } elseif ($null -ne $file.WorkDirChange) {
                    $workDirIsDirty = $true
                }
            }
            if ($workDirIsDirty) {
                $promptText += " `e[31m+$($counts[[FileStatus]::NewInWorkdir]) ~$($counts[[FileStatus]::ModifiedInWorkdir]) -$($counts[[FileStatus]::DeletedFromWorkdir])`e[0m"
                if ($counts[[FileStatus]::Conflicted]) {
                    $promptText += " !$($counts[[FileStatus]::Conflicted])"
                }
            }
            if ($indexIsDirty) {
                if ($workDirIsDirty) {
                    $promptText += " `e[33m|`e[0m"
                }
                $promptText += " `e[32m+$($counts[[FileStatus]::NewInIndex]) ~$($counts[[FileStatus]::ModifiedInIndex]) -$($counts[[FileStatus]::DeletedFromIndex])`e[0m"
            }
        }
        $repo.Dispose()

        $promptText += "`e[33m]`e[0m"
        $promptText
    }
}
