# Build script for Qt 6 WebAssembly (Multi-Threaded)
$ErrorActionPreference = "Stop"

$EmsdkDir = "C:\Users\Maxime\Documents\emsdk"

# Auto-detect Qt 6 WASM (prefer 6.12.0, fallback to 6.11.1)
if (Test-Path "C:\Qt\6.12.0\wasm_multithread\bin\qt-cmake.bat") {
    $QtWasmDir = "C:\Qt\6.12.0\wasm_multithread"
} elseif (Test-Path "C:\Qt\6.11.1\wasm_multithread\bin\qt-cmake.bat") {
    $QtWasmDir = "C:\Qt\6.11.1\wasm_multithread"
} else {
    throw "No supported Qt 6 WebAssembly installation found under C:\Qt"
}

$NinjaExe = "C:\Qt\Tools\Ninja\ninja.exe"

# Activate Emscripten environment variables
if (Test-Path "$EmsdkDir\emsdk_env.ps1") {
    & "$EmsdkDir\emsdk_env.ps1"
}

$BuildDir = "$PSScriptRoot\build_wasm"
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

# Stage only the 17 referenced 3D .glb CAD models for Emscripten --preload-file
$TecanSrc = "C:\ProgramData\Tecan\HeroAssets"
$WasmAssetsDir = "$BuildDir\wasm_assets"
$PreloadArgs = @()

if (Test-Path $TecanSrc) {
    Write-Host "=== Staging 17 Referenced 3D CAD (.glb) Assets for WASM Preload ===" -ForegroundColor Cyan
    $ReferencedGlbs = @(
        "Invenesis_worktable_New.glb",
        "Robots\Myrius1080.glb",
        "Robots\plate96.glb",
        "Robots\LiHa_Gantry.glb",
        "Robots\LiHa_YCarriages.glb",
        "Robots\LiHa_Plungers_Ch0.glb",
        "Robots\LiHa_Tips_Ch0.glb",
        "Robots\Roma_Gantry.glb",
        "Robots\Roma_ZElevator.glb",
        "Robots\Roma_RotaryHead.glb",
        "Robots\Roma_LeftJawFinger.glb",
        "Robots\Roma_RightJawFinger.glb",
        "Robots\MCA96_Gantry.glb",
        "Robots\MCA96_Carriage.glb",
        "Robots\MCA96_Elevator.glb",
        "Robots\MCA96_Adapter.glb",
        "Robots\MCA96_Tips.glb"
    )

    New-Item -ItemType Directory -Path "$WasmAssetsDir\Robots" -Force | Out-Null
    foreach ($relPath in $ReferencedGlbs) {
        $srcFile = Join-Path $TecanSrc $relPath
        $dstFile = Join-Path $WasmAssetsDir $relPath
        if (Test-Path $srcFile) {
            Copy-Item $srcFile $dstFile -Force
        } else {
            Write-Warning "Missing 3D asset: $srcFile"
        }
    }
    $PreloadArgs += "-DWASM_PRELOAD_ASSETS_DIR=$WasmAssetsDir"
}

Write-Host "=== Configuring Qt 6 WebAssembly Release Build ($QtWasmDir) ===" -ForegroundColor Cyan
& "$QtWasmDir\bin\qt-cmake.bat" -S "$PSScriptRoot" -B "$BuildDir" -GNinja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_MAKE_PROGRAM="$NinjaExe" `
    @PreloadArgs
if ($LASTEXITCODE -ne 0) { throw "qt-cmake configuration failed with exit code $LASTEXITCODE" }

Write-Host "=== Compiling WebAssembly with Ninja ===" -ForegroundColor Cyan
& $NinjaExe -C "$BuildDir"
if ($LASTEXITCODE -ne 0) { throw "Ninja WASM compilation failed with exit code $LASTEXITCODE" }

# Copy web entrypoint, favicon, CV, and COOP/COEP .htaccess
Write-Host "=== Packaging Web Deployment Artifacts ===" -ForegroundColor Cyan
Copy-Item "$PSScriptRoot\index.html" "$BuildDir\index.html" -Force
Copy-Item "$PSScriptRoot\assets\images\sphere.png" "$BuildDir\sphere.png" -Force
Copy-Item "$PSScriptRoot\Maxime_Alessandri_CV_Lab_Automation_V2.docx" "$BuildDir\Maxime_Alessandri_CV_Lab_Automation_V2.docx" -Force

$htaccessContent = @"
DirectoryIndex index.html MaximeAlessandriPortfolio.html

Header set Cross-Origin-Embedder-Policy "require-corp"
Header set Cross-Origin-Opener-Policy "same-origin"

<FilesMatch "\.(wasm|js|html|data)$">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
    Header set Pragma "no-cache"
    Header set Expires 0
</FilesMatch>
"@
Set-Content -Path "$BuildDir\.htaccess" -Value $htaccessContent -Encoding UTF8

Write-Host "=== WebAssembly Build Completed! ===" -ForegroundColor Green
Write-Host "Web output is at: $BuildDir\index.html" -ForegroundColor Yellow
Write-Host "Note: Multi-threaded Qt WASM requires COOP/COEP headers when served." -ForegroundColor Cyan
