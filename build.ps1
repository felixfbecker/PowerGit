Push-Location ./Source/PowerGit
try {
    dotnet publish -o "$PSScriptRoot/PowerGit/Assemblies"
    if ($LASTEXITCODE -ne 0) {
        throw 'Build failed'
    }
} finally {
    Pop-Location
}
