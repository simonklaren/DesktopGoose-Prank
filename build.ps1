[CmdletBinding()]
param(
    [switch]$SkipTests,
    [switch]$SkipZip
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$solution = Join-Path $repoRoot 'Source\GooseDesktop.sln'
$testProject = Join-Path $repoRoot 'tests\WindowDropPlanner.Tests.csproj'
$releaseExe = Join-Path $repoRoot 'Source\GooseDesktop\bin\Release\GooseDesktop.exe'
$runtimeRoot = Join-Path $repoRoot 'Runtime'
$toolsRoot = Join-Path $repoRoot 'tools'
$distParent = Join-Path $repoRoot 'dist'
$distRoot = Join-Path $distParent 'DesktopGoose-Prank'
$zipPath = Join-Path $repoRoot 'DesktopGoose-Prank.zip'
$env:NUGET_PACKAGES = Join-Path $repoRoot '.packages'

# A running development copy can lock GIF meme files inside dist.
Get-Process -Name 'GooseDesktop' -ErrorAction SilentlyContinue | Stop-Process -Force

dotnet restore $solution --ignore-failed-sources
if ($LASTEXITCODE -ne 0) { throw 'Solution restore failed.' }

dotnet msbuild $solution /t:Rebuild /p:Configuration=Release '/p:Platform=Any CPU' /p:RestorePackages=false
if ($LASTEXITCODE -ne 0) { throw 'Release build failed.' }

if (-not $SkipTests) {
    dotnet run --project $testProject -c Release
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
}

$expectedDistPrefix = [IO.Path]::GetFullPath($distParent) + [IO.Path]::DirectorySeparatorChar
$resolvedDistRoot = [IO.Path]::GetFullPath($distRoot)
if (-not $resolvedDistRoot.StartsWith($expectedDistPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to replace unexpected dist path: $resolvedDistRoot"
}

if (Test-Path -LiteralPath $distRoot) {
    Remove-Item -LiteralPath $distRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

Copy-Item -LiteralPath $releaseExe -Destination $distRoot
Copy-Item -Path (Join-Path $runtimeRoot '*') -Destination $distRoot -Recurse -Force
Copy-Item -LiteralPath $toolsRoot -Destination (Join-Path $distRoot 'tools') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'README.md') -Destination $distRoot

$resolvedZip = [IO.Path]::GetFullPath($zipPath)
if (-not $resolvedZip.StartsWith([IO.Path]::GetFullPath($repoRoot), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to replace unexpected ZIP path: $resolvedZip"
}
if (-not $SkipZip) {
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -LiteralPath $distRoot -DestinationPath $zipPath -CompressionLevel Optimal
}

Write-Host "Release executable: $releaseExe"
Write-Host "Distribution:      $distRoot"
if (-not $SkipZip) {
    Write-Host "ZIP:               $zipPath"
}
