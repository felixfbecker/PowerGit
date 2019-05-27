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

function Send-GitObject {
    <#
    .SYNOPSIS
    Sends Git refs and object to a remote repository.

    .DESCRIPTION
    The `Send-GitObject` functions sends objects from a local repository to a remote repository. You specify what refs and objects to send with the `Revision` parameter.

    This command implements the `git push` command.

    .EXAMPLE
    Send-GitObject -Revision 'refs/heads/master'

    Demonstrates how to push the commits on a specific branch to the default remote repository.

    .EXAMPLE
    Send-GitObject -Revision 'refs/heads/master' -RemoteName 'upstream'

    Demonstrates how to push an object (in this case, the master branch) to a specific remote repository, in this case the remote named "upstream".

    .EXAMPLE
    Send-GitObject -Revision 'refs/tags/4.45.6'

    Demonstrates how to push a tag to the default remote repository.

    .EXAMPLE
    Send-GitObject -Tags

    Demonstrates how to push all tags to the default remote repository.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Branch], ParameterSetName = 'BranchObject')] # returns input to support piping
    param(
        [Parameter(Mandatory, ParameterSetName = 'BranchObject', ValueFromPipeline)]
        [LibGit2Sharp.Branch] $BranchObject,

        [Parameter(ParameterSetName = 'BranchObject')]
        [Alias('u')]
        [switch] $SetUpstream,

        # The refs that should be pushed to the remote repository.
        [Parameter(Mandatory, ParameterSetName = 'ByRefSpec')]
        [string[]] $RefSpec,

        # Push all tags to the remote repository.
        [Parameter(Mandatory, ParameterSetname = 'Tags')]
        [Switch] $Tags,

        # The name of the remote repository to send the changes to. The default is the branch's upstream or "origin".
        [Parameter(Position = 0)]
        [string] $Remote,

        # Usually, the command refuses to update a remote ref that is not an ancestor of the local ref used to overwrite it.
        # This flag disables this check by prefixing all refspecs with "+".
        [switch] $Force,

        # The path to the local repository from which to push changes. Defaults to the current directory.
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # The credentials to use to connect to the source repository.
        [pscredential] $Credential
    )

    process {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $repo = Find-GitRepository -Path $RepoRoot -Verify

        $cancel = $false

        $pushOptions = [LibGit2Sharp.PushOptions]::new()
        $pushOptions.OnPushTransferProgress = {
            param([int]$current, [int]$total, [long]$bytes)
            if ($ProgressPreference -ne 'SilentlyContinue' -and $total -ne 0) {
                Write-Progress -Activity 'Pushing objects' -PercentComplete (($current / $total) * 100) -Status "$($bytes)B"
            }
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        $pushOptions.OnPackBuilderProgress = {
            param([LibGit2Sharp.Handlers.PackBuilderStage]$stage, [int]$current, [int]$total)
            if ($ProgressPreference -ne 'SilentlyContinue' -and $total -ne 0) {
                Write-Progress -Activity 'Packing objects' -PercentComplete (($current / $total) * 100) -CurrentOperation $stage
            }
            return -not $cancel -and -not $PSCmdlet.Stopping
        }
        $pushOptions.OnPushStatusError = {
            param([LibGit2Sharp.PushStatusError]$PushStatusError)
            Write-Error -Message "$($PushStatusError.Reference): $($PushStatusError.Message)"
        }
        $credentialsProviderCalled = $false
        $pushOptions.CredentialsProvider = {
            param([string]$Url, [string]$UsernameForUrl, [LibGit2Sharp.SupportedCredentialTypes]$Types)
            Write-Verbose "Credentials required"
            if ($credentialsProviderCalled) {
                $Credential = Get-Credential -Title "Wrong credentials provided for $Url"
            } else {
                Set-Variable -Name credentialsProviderCalled -Value $true -Scope 1
                if (-not $Credential) {
                    $Credential = Get-Credential -Title "Authentication required for $Url"
                }
            }
            $gitCredential = [LibGit2Sharp.SecureUsernamePasswordCredentials]::new()
            $gitCredential.Username = $Credential.UserName
            $gitCredential.Password = $Credential.Password
            return $gitCredential
        }

        if (-not $Remote) {
            $Remote = if ($null -ne $BranchObject -and $BranchObject.RemoteName) {
                $BranchObject.RemoteName
            } else {
                'origin'
            }
        }

        [LibGit2Sharp.Remote]$remoteObject = $repo.Network.Remotes[$Remote]

        if (-not $remoteObject) {
            Write-Error "A remote named ""$Remote"" does not exist."
            return
        }

        if ($PSCmdlet.ParameterSetName -eq 'BranchObject') {
            $RefSpec = $BranchObject.CanonicalName
        }

        if ($Tags) {
            $RefSpec = $repo.Tags | ForEach-Object { $_.CanonicalName }
        }

        if ($Force) {
            $RefSpec = $RefSpec | ForEach-Object {
                if (-not $_.StartsWith('+')) { "+$_" } else { $_ }
            }
        }

        try {
            Write-Verbose "Pushing refspec $RefSpec of repository $RepoRoot to remote $($remoteObject.Name)"
            $repo.Network.Push($remoteObject, $RefSpec, $pushOptions) | Out-Null
            if ($SetUpstream) {
                # Setup tracking with the new remote branch.
                [void]$repo.Branches.Update($BranchObject, {
                    param([LibGit2Sharp.BranchUpdater] $Updater)
                    $updater.Remote = $Remote
                    $updater.UpstreamBranch = $BranchObject.CanonicalName
                })
                $BranchObject = $repo.Branches[$BranchObject.CanonicalName]
            }
            return $BranchObject
        } catch {
            Write-Error -ErrorRecord $_
        } finally {
            $cancel = $true
        }
    }
}
