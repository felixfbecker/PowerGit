<#
.SYNOPSIS
    Internal. Returns the options for LibGit2Sharp.Repository#Rebase(), shared by Start-, Stop- and Resume-GitRebase.
#>
function New-LibGit2SharpRebaseOptions {
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.RebaseOptions])]
    param()

    $options = [LibGit2Sharp.RebaseOptions]::new()
    $options.OnCheckoutProgress = {
        param([string]$Path, [int]$CompletedSteps, [int]$TotalSteps)
        if ($ProgressPreference -ne 'SilentlyContinue' -and $TotalSteps -ne 0) {
            $progressParams = @{
                Activity = 'Checking files out'
            }
            if ($TotalSteps -ne 0) {
                $progressParams.PercentComplete = (($CompletedSteps / $TotalSteps) * 100)
            }
            if ($Path) {
                $progressParams.Status = $Path
            }
            Write-Progress @progressParams
        }
    }
    $options.RebaseStepStarting = {
        param([LibGit2Sharp.BeforeRebaseStepInfo] $info)
        if ($ProgressPreference -ne 'SilentlyContinue') {
            Write-Progress `
                -Activity 'Rebasing' `
                -Status "$($info.StepIndex)/$($info.TotalStepCount)" `
                -CurrentOperation "Applying $($info.StepInfo.Commit.Sha.Substring(0, 7)) $($info.StepInfo.Commit.MessageShort)"
        }
    }
    $options.RebaseStepCompleted = {
        param([LibGit2Sharp.AfterRebaseStepInfo] $info)
        if ($ProgressPreference -ne 'SilentlyContinue' -and $info.TotalStepCount -ne 0) {
            Write-Progress `
                -Activity 'Rebasing' `
                -PercentComplete (($info.StepIndex / $info.TotalStepCount) * 100)
        }
        # Write-Information "Applied $($info.StepInfo.Commit.Sha.Substring(0, 7)) $($info.StepInfo.Commit.MessageShort)"
        $info.StepInfo
    }
    return $options
}
Export-ModuleMember -Function New-LibGit2SharpRebaseOptions
