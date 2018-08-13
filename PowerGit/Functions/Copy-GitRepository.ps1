# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Copy-GitRepository {
    <#
    .SYNOPSIS
    Clones a Git repository.

    .DESCRIPTION
    The `Copy-GitRepository` function clones a Git repository from the URL specified by `Uri` to the path specified by `DestinationPath` and checks out the `master` branch. If the repository requires authentication, pass the username/password via the `Credential` parameter.

    To clone a local repository, pass a file system path to the `Uri` parameter.

    .EXAMPLE
    Copy-GitRepository -Uri 'https://github.com/webmd-health-services/PowerGit' -DestinationPath PowerGit
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        # The URI or path to the source repository to clone.
        $Source,

        [string]
        # The directory where the repository should be cloned to. Must not exist or be empty.
        $DestinationPath,

        [pscredential]
        # The credentials to use to connect to the source repository.
        $Credential,

        [Switch]
        # Returns a `System.IO.DirectoryInfo` object for the new copy's `.git` directory.
        $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Source = ConvertTo-GitFullPath -Uri $Source
    if (-not $DestinationPath) {
        $DestinationPath = Join-Path $PWD (Split-Path $Source -LeafBase)
    }
    $DestinationPath = ConvertTo-GitFullPath -Path $DestinationPath

    $options = [libgit2sharp.CloneOptions]::new()
    if ( $Credential ) {
        $gitCredential = [LibGit2Sharp.SecureUsernamePasswordCredentials]::new()
        $gitCredential.Username = $Credential.UserName
        $gitCredential.Password = $Credential.Password
        $options.CredentialsProvider = { return $gitCredential }
    }

    $cancelClone = $false
    $options.OnProgress = {
        param(
            $Output
        )

        Write-Verbose -Message $Output
        return -not $cancelClone
    }

    $lastUpdated = Get-Date
    $options.OnTransferProgress = {
        param(
            [LibGit2Sharp.TransferProgress]
            $TransferProgress
        )

        # Only update progress every 1/10th of a second, otherwise updating the progress takes longer than the clone
        if ( ((Get-Date) - $lastUpdated).TotalMilliseconds -lt 100 ) {
            return $true
        }

        if ($ProgressPreference -ne 'SilentlyContinue') {
            $numBytes = $TransferProgress.ReceivedBytes
            if ( $numBytes -lt 1kb ) {
                $unit = 'B'
            } elseif ( $numBytes -lt 1mb ) {
                $unit = 'KB'
                $numBytes = $numBytes / 1kb
            } elseif ( $numBytes -lt 1gb ) {
                $unit = 'MB'
                $numBytes = $numBytes / 1mb
            } elseif ( $numBytes -lt 1tb ) {
                $unit = 'GB'
                $numBytes = $numBytes / 1gb
            } elseif ( $numBytes -lt 1pb ) {
                $unit = 'TB'
                $numBytes = $numBytes / 1tb
            } else {
                $unit = 'PB'
                $numBytes = $numBytes / 1pb
            }

            Write-Progress -Activity ('Cloning {0} -> {1}' -f $Source, $DestinationPath) `
                -Status ('{0}/{1} objects, {2:n0} {3}' -f $TransferProgress.ReceivedObjects, $TransferProgress.TotalObjects, $numBytes, $unit) `
                -PercentComplete (($TransferProgress.ReceivedObjects / $TransferProgress.TotalObjects) * 100)
            Set-Variable -Name 'lastUpdated' -Value (Get-Date) -Scope 1
        }
        return (-not $cancelClone)
    }

    try {
        $cloneCompleted = $false
        $gitPath = [LibGit2Sharp.Repository]::Clone($Source, $DestinationPath, $options)
        if ( $PassThru -and $gitPath ) {
            Get-Item -Path $gitPath -Force
        }
        $cloneCompleted = $true
    } finally {
        if ( -not $cloneCompleted ) {
            $cancelClone = $true
        }
    }
}
