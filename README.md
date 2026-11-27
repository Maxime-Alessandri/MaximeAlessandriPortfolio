# Dr. Maxime Alessandri, PhD — Scientific Software & Lab Automation Portfolio

Interactive Qt 6 / QML / QtQuick3D / WebAssembly engineering portfolio showcasing production software systems for automated drug screening, LIMS microplate tracking, and liquid-handling robotics.

- **GitHub:** https://github.com/Maxime-Alessandri
- **LinkedIn:** https://www.linkedin.com/in/maxime-alessandri-phd
- **Contact:** alessandrimaxime@gmail.com

---

## Interactive Engineering Modules

1. **Client Portal -> LIMS -> 3D Fluent -> Results Workflow (`ClientPortalWorkflowDemo`)**
   - Full 6-stage interactive simulation of an external client ordering pipeline: assay catalog browsing, inline compound table editing (with Excel drag-and-drop import, TSV/CSV paste, and duplicate validation), cart & batch submission, SBS-96 plate placement, GWL worklist compilation into the live 3D Tecan Fluent simulator, and client-facing results browsing with 4PL curves.
2. **3D Tecan Fluent 1080 Workcell Digital Twin (`RoboticArmDemo`, `TecanWorkstationView`)**
   - Live QtQuick3D CAD model of the LiHa (8-channel FCA with independent per-channel Z-axis kinematics), RoMa gripper, and MCA-96 arm running collision-free GWL hitpick and parallel serial dilution sequences.
3. **SBS 96-to-384 Plate Mapper & Hitpick Simulator (`PlateVisualizerDemo`)**
   - Interactive A1–P24 coordinate mapping and quadrant hitpick visualization across source and destination microplates.
4. **4PL Dose-Response & Assay QC Analyzer (`DoseResponseDemo`)**
   - Four-parameter logistic (`IC50`, Hill slope, `Emax`) curve fitting with microplate `Z'`-factor and signal-to-background quality metrics.
5. **GWL & SiLA 2 Worklist Compiler (`GwlGeneratorDemo`)**
   - Dynamic `.gwl` liquid-handling instruction generator paired with structured SiLA 2 scheduling payloads.

---

## Building

### Prerequisites
- Qt 6.12.0+ (or Qt 6.11+) with `Gui`, `Qml`, `Quick`, `Network`, `Quick3D`, `Quick3DAssetUtils`, and `QuickControls2`
- CMake 3.16+, Ninja, and MinGW / MSVC (Desktop) or Emscripten (WebAssembly)
- Optional external 3D CAD assets in `C:\ProgramData\Tecan\HeroAssets` (automatically synced by the build scripts)

### Desktop Build (Windows / MinGW)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build_desktop.ps1
```

### WebAssembly Build
Multi-threaded Qt WebAssembly requires HTTP `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers (included in the generated `.htaccess`):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build_wasm.ps1
```
