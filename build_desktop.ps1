# Build script for Qt 6 Desktop (MinGW 64-bit)
$ErrorActionPreference = "Stop"

# Auto-detect Qt 6 (prefer 6.12.0, fallback to 6.11.1)
if (Test-Path "C:\Qt\6.12.0\mingw_64\bin\qmake.exe") {
    $QtDir = "C:\Qt\6.12.0\mingw_64"
    $MinGWDir = "C:\Qt\Tools\mingw1510_64\bin"
} elseif (Test-Path "C:\Qt\6.11.1\mingw_64\bin\qmake.exe") {
    $QtDir = "C:\Qt\6.11.1\mingw_64"
    $MinGWDir = "C:\Qt\Tools\mingw1310_64\bin"
} else {
    throw "No supported Qt 6 MinGW 64-bit installation found under C:\Qt"
}

$NinjaExe = "C:\Qt\Tools\Ninja\ninja.exe"
$CMakeExe = "C:\Qt\Tools\CMake_64\bin\cmake.exe"

$env:PATH = "$MinGWDir;$QtDir\bin;$env:PATH"

$BuildDir = "$PSScriptRoot\build_desktop"

Write-Host "=== Configuring Desktop Release Build ($QtDir) ===" -ForegroundColor Cyan
& $CMakeExe -S "$PSScriptRoot" -B "$BuildDir" -GNinja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_MAKE_PROGRAM="$NinjaExe" `
    -DCMAKE_CXX_COMPILER="$MinGWDir\g++.exe" `
    -DCMAKE_PREFIX_PATH="$QtDir"
if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed with exit code $LASTEXITCODE" }

Write-Host "=== Compiling with Ninja ===" -ForegroundColor Cyan
& $NinjaExe -C "$BuildDir"
if ($LASTEXITCODE -ne 0) { throw "Ninja compilation failed with exit code $LASTEXITCODE" }

# Sync 3D Tecan assets only if missing or updated
$tecanHeroSrc = "C:\ProgramData\Tecan\HeroAssets"
if (Test-Path $tecanHeroSrc) {
    $assetsTarget = "$BuildDir\assets"
    Write-Host "=== Syncing 3D Tecan Assets to Build Directory ===" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $assetsTarget -Force | Out-Null
    & robocopy $tecanHeroSrc $assetsTarget /E /XO /FFT /NFL /NDL /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }
}

# Copy CV document alongside Desktop executable
$cvSrc = Join-Path $PSScriptRoot "Maxime_Alessandri_CV_Lab_Automation_V2.docx"
if (Test-Path $cvSrc) {
    Copy-Item $cvSrc "$BuildDir\" -Force
}

Write-Host "=== Build Completed Successfully! ===" -ForegroundColor Green
Write-Host "Executable is at: $BuildDir\MaximeAlessandriPortfolio.exe" -ForegroundColor Yellow
