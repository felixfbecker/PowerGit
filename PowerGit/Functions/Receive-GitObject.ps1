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

function Receive-GitObject {
    <#
    .SYNOPSIS
    Downloads the given rev spec or all branches (and their commits) from remote repositories.

    .DESCRIPTION
    The `Recieve-GitCommit` function gets all the commits on all branches from all remote repositories and brings them into your repository.

    It defaults to the repository in the current directory. Pass the path to a different repository to the `RepoRoot` parameter.

    This function implements the `git fetch` command.

    .EXAMPLE
    Receive-GitObject

    Demonstrates how to get all branches from a remote repository.
    #>
    [CmdletBinding(DefaultParameterSetName = 'CurrentBranchRemote')]
    param(
        # The repository to fetch updates for. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory, ParameterSetName = 'Remote')]
        [string[]] $Remote,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        # Before fetching, remove any remote-tracking references that no longer
        # exist on the remote.
        [switch] $Prune,

        [LibGit2Sharp.TagFetchMode] $TagFetchMode,

        [pscredential] $Credential
    )

    process {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $repo = Find-GitRepository -Path $RepoRoot -Verify
        if (-not $repo) {
            return
        }

        $cancel = $false

        $fetchOptions = [LibGit2Sharp.FetchOptions]::new()
        $fetchOptions.OnProgress = {
            param([string] $serverProgressOutput)
            if ($ProgressPreference -ne 'SilentlyContinue') {
                if ($serverProgressOutput -match '^(.+):\s+(\d+)% \((\d+/\d+)\)') {
                    # Compressing objects:   0% (1/123)
                    # Counting objects:   3% (11/550)
                    if ($ProgressPreference -ne 'SilentlyContinue') {
                        Write-Progress `
                            -Activity $Matches[1] `
                            -PercentComplete $Matches[2] `
                            -Status $Matches[3]
                    }
                } elseif ($serverProgressOutput -match '^(.+)(?::)?\s+(\d+)') {
                    # Enumerating objects: 576, done.
                    # Counting objects 4
                    if ($ProgressPreference -ne 'SilentlyContinue') {
                        Write-Progress `
                            -Activity $Matches[1] `
                            -Status $Matches[2] `
                            -PercentComplete -1
                    }
                } elseif (-not [string]::IsNullOrWhiteSpace($serverProgressOutput)) {
                    Write-Information $serverProgressOutput
                }
            }
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        $fetchOptions.OnTransferProgress = {
            param([LibGit2Sharp.TransferProgress] $progress)
            if ($ProgressPreference -ne 'SilentlyContinue' -and $progress.TotalObjects -ne 0) {
                Write-Progress `
                    -Activity "Fetching objects" `
                    -Status "$($progress.ReceivedObjects)/$($progress.TotalObjects), $($progress.ReceivedBytes) bytes" `
                    -PercentComplete (($progress.ReceivedObjects / $progress.TotalObjects) * 100)
            }
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        $credentialsProviderCalled = $false
        $fetchOptions.CredentialsProvider = {
            param([string]$Url, [string]$UsernameForUrl, [LibGit2Sharp.SupportedCredentialTypes]$Types)
            Write-Verbose "Credentials required"
            if ($credentialsProviderCalled) {
                $Credential = Get-Credential -Title "Wrong credentials provided for $Url"
            }
            Set-Variable -Name credentialsProviderCalled -Value $true -Scope 1
            if (-not $Credential) {
                $Credential = Get-Credential -Title "Authentication required for $Url"
            }
            $gitCredential = [LibGit2Sharp.SecureUsernamePasswordCredentials]::new()
            $gitCredential.Username = $Credential.UserName
            $gitCredential.Password = $Credential.Password
            return $gitCredential
        }
        if ($PSBoundParameters.ContainsKey('Prune')) {
            $fetchOptions.Prune = $Prune
        }
        if ($PSBoundParameters.ContainsKey('TagFetchMode')) {
            $fetchOptions.TagFetchMode = $TagFetchMode
        }

        $remoteObjects = if ($All) {
            $repo.Network.Remotes
        } elseif (-not $Remote) {
            $Remote = if ($repo.Head.RemoteName) { $repo.Head.RemoteName } else { 'origin' }
            $repo.Network.Remotes[$Remote]
        }
        try {
            foreach ($remoteObject in $remoteObjects) {
                [string[]]$refspecs = $remoteObject.FetchRefSpecs | Select-Object -ExpandProperty Specification
            Write-Verbose "Fetching remote $($remoteObject.Name) with refspecs $refspecs"
            try {
                [LibGit2Sharp.Commands]::Fetch($repo, $remoteObject.Name, $refspecs, $fetchOptions, $null)
            } catch {
                Write-Error -ErrorRecord $_
            }
        }
    } finally {
        $cancel = $true
    }
}
}
