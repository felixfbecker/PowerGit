function ConvertTo-ColoredPatch {
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Content')]
        [string] $Patch
    )
    ($Patch -split "`n" | ForEach-Object {
            if ($_.StartsWith('-')) {
                "$([char]0x001b)[31m$_$([char]0x001b)[0m"
            } elseif ($_.StartsWith('+')) {
                "$([char]0x001b)[32m$_$([char]0x001b)[0m"
            } elseif ($_.StartsWith('@@')) {
                $_ -replace '@@(.+)@@', "$([char]0x001b)[36m@@`$1@@$([char]0x001b)[0m"
            } elseif ($_.StartsWith('diff ') -or $_.StartsWith('index ') -or $_.StartsWith('--- ') -or $_.StartsWith('+++ ')) {
                "$([char]0x001b)[1m$_$([char]0x001b)[0m"
            } else {
                $_
            }
        }) -join "`n"
}
