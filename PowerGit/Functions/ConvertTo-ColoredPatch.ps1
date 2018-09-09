function ConvertTo-ColoredPatch {
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Content')]
        [string] $Patch
    )
    ($Patch -split "`n" | ForEach-Object {
            if ($_.StartsWith('-')) {
                "`e[31m$_`e[0m"
            } elseif ($_.StartsWith('+')) {
                "`e[32m$_`e[0m"
            } elseif ($_.StartsWith('@@')) {
                $_ -replace '@@(.+)@@', "`e[36m@@`$1@@`e[0m"
            } elseif ($_.StartsWith('diff ') -or $_.StartsWith('index ') -or $_.StartsWith('--- ') -or $_.StartsWith('+++ ')) {
                "`e[1m$_`e[0m"
            } else {
                $_
            }
        }) -join "`n"
}
