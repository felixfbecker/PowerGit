
using namespace System.Management.Automation;

$revisionCompleterIncludingRemoteBranches = {
    [CmdletBinding()]
    param([string]$command, [string]$parameter, [string]$wordToComplete, [CommandAst]$commandAst, [Hashtable]$params)

    (
        (
            Get-GitBranch -All |
                Where-Object {
                    $_.FriendlyName -like "$wordToComplete*" -or
                    ($_.IsRemote -and ($_.FriendlyName -creplace "^$($_.RemoteName)/", "") -like "$wordToComplete*")
                }
        ),
        (Get-GitTag -Name "$wordToComplete*")
    ) |
        ForEach-Object { $_ } |
        ForEach-Object {
            $suggestion = if ($_.IsRemote) {
                ($_.FriendlyName -creplace "^$($_.RemoteName)/", "")
            } else {
                $_.FriendlyName
            }
            $tooltip = "$($_.FriendlyName) → $($_.Tip.Sha.Substring(0, 7)) $($_.Tip.MessageShort.Trim())"
            [CompletionResult]::new($suggestion, $suggestion, [CompletionResultType]::ParameterValue, $tooltip)
        }
}
Register-ArgumentCompleter -CommandName Set-GitHead -ParameterName Revision -ScriptBlock $revisionCompleterIncludingRemoteBranches

$revisionCompleter = {
    [CmdletBinding()]
    param([string]$command, [string]$parameter, [string]$wordToComplete, [CommandAst]$commandAst, [Hashtable]$params)

    (Get-GitBranch -All -Name "$wordToComplete*"), (Get-GitTag -Name "$wordToComplete*") |
        ForEach-Object { $_ } |
        ForEach-Object {
            $tooltip = "$($_.FriendlyName) → $($_.Tip.Sha.Substring(0, 7)) $($_.Tip.MessageShort.Trim())"
            [CompletionResult]::new($_.FriendlyName, $_.FriendlyName, [CompletionResultType]::ParameterValue, $tooltip)
        }
}
Register-ArgumentCompleter -CommandName Get-GitBranch -ParameterName Name -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Merge-GitCommit -ParameterName Revision -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Get-GitCommit -ParameterName Revision -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Start-GitRebase -ParameterName Branch -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Start-GitRebase -ParameterName Upstream -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Start-GitRebase -ParameterName Onto -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Compare-GitTree -ParameterName DifferenceRevision -ScriptBlock $revisionCompleter
Register-ArgumentCompleter -CommandName Compare-GitTree -ParameterName ReferenceRevision -ScriptBlock $revisionCompleter

$remoteCompleter = {
    [CmdletBinding()]
    param([string]$command, [string]$parameter, [string]$wordToComplete, [CommandAst]$commandAst, [Hashtable]$params)
    (Get-GitRemote -Name "$wordToComplete*") |
        ForEach-Object {
            [CompletionResult]::new($_.Name, $_.Name, [CompletionResultType]::ParameterValue, "$($_.Name) → $($_.Url)")
        }
}
Register-ArgumentCompleter -CommandName Send-GitObject -ParameterName Remote -ScriptBlock $remoteCompleter
Register-ArgumentCompleter -CommandName Receive-GitObject -ParameterName Remote -ScriptBlock $remoteCompleter
Register-ArgumentCompleter -CommandName Get-GitRemote -ParameterName Name -ScriptBlock $remoteCompleter
Register-ArgumentCompleter -CommandName Update-GitRemote -ParameterName Name -ScriptBlock $remoteCompleter
Register-ArgumentCompleter -CommandName Remove-GitRemote -ParameterName Name -ScriptBlock $remoteCompleter
Register-ArgumentCompleter -CommandName Rename-GitRemote -ParameterName Name -ScriptBlock $remoteCompleter
