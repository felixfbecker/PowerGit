param(
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Debug',

    [ValidateSet('quiet', 'minimal', 'normal', 'detailed', 'diagnostic')]
    [string] $Verbosity = 'minimal'
)

dotnet publish -o "$PSScriptRoot/PowerGit/Assemblies" -c $Configuration -v $Verbosity
if ($LASTEXITCODE -ne 0) {
    throw 'Build failed'
}
