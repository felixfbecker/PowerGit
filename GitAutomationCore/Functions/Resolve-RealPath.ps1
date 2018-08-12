
function Resolve-RealPath {
    <#
        .SYNOPSIS
        Implementation of Unix realpath().

        .PARAMETER Path
        Must exist
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string] $Path
    )

    if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) {
        return [IO.Path]::GetFullPath($Path)
    }

    [string[]] $parts = ($Path.TrimStart([IO.Path]::DirectorySeparatorChar).Split([IO.Path]::DirectorySeparatorChar))
    [string] $realPath = ''
    foreach ($part in $parts) {
        $realPath += [string] ([IO.Path]::DirectorySeparatorChar + $part)
        $item = Get-Item $realPath
        if ($item.Target) {
            $realPath = $item.Target
        }
    }
    $realPath
}
