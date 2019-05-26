param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = 'Debug'
)

dotnet publish -o "$PSScriptRoot/PowerGit/Assemblies" -c $Configuration
if ($LASTEXITCODE -ne 0) {
    throw 'Build failed'
}
