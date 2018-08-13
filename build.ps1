param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = 'Debug'
)

Push-Location ./Source/PowerGit
try {
    dotnet publish -o "$PSScriptRoot/PowerGit/Assemblies" -c $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw 'Build failed'
    }
} finally {
    Pop-Location
}
