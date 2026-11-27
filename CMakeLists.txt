cmake_minimum_required(VERSION 3.16)

project(MaximeAlessandriPortfolio VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Discover Qt 6 Core, Gui, Qml, Quick, Network, Quick3D, and QuickControls2 packages
find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick Network Quick3D Quick3DAssetUtils QuickControls2)

qt_standard_project_setup()

# Define Binary Resources (Fonts, High-Res Portraits, and Media)
set(ASSET_RESOURCES
    assets/fonts/CormorantGaramond[wght].ttf
    assets/fonts/CormorantGaramond-Italic[wght].ttf
    assets/fonts/JetBrainsMono-Regular.ttf
    assets/fonts/JetBrainsMono-Bold.ttf
    assets/fonts/Inter-VariableFont.ttf
    assets/fonts/Inter-Italic-VariableFont.ttf
    assets/fonts/MaterialSymbolsOutlined.ttf
    assets/images/Maxime-Alessandri-BW.jpeg
    assets/images/sphere.png
    assets/plasma.frag.qsb
)

# Define QML Source Hierarchy
set(QML_SOURCES
    Main.qml
    Theme.qml
    components/PlasmaBackground.qml
    components/HeroSection.qml
    components/ContactModal.qml
    components/BrandEmblem.qml
    components/LogoShowcaseModal.qml
    controls/CustomButton.qml
    controls/TelemetryBadge.qml
    controls/AccentSlider.qml
    components/demos/DemosShowcase.qml
    components/demos/ClientPortalWorkflowDemo.qml
    components/demos/ExcelImportPreviewOverlay.qml
    components/demos/PortalCompoundSpreadsheet.qml
    components/demos/PortalTsvPasteOverlay.qml
    components/demos/PortalResultsBrowserStage.qml
    components/demos/PlateVisualizerDemo.qml
    components/demos/DoseResponseDemo.qml
    components/demos/RoboticArmDemo.qml
    components/demos/GwlGeneratorDemo.qml
    components/demos/fluent3d/TecanWorkstationView.qml
    components/demos/fluent3d/LiHaArm.qml
    components/demos/fluent3d/RomaArm.qml
    components/demos/fluent3d/Mca96Arm.qml
    components/demos/fluent3d/HeroAnimationController.qml
    views/ExecutiveSummaryView.qml
    views/CompetenciesView.qml
    views/ArchitectureDeepDiveView.qml
    views/PublicationsView.qml
    views/CareerTimelineView.qml
)

# Add Executable Target
qt_add_executable(MaximeAlessandriPortfolio
    main.cpp
    AppConfig.h
)

# Register Theme.qml as a QML Singleton
set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# Package QML Module with embedded assets
qt_add_qml_module(MaximeAlessandriPortfolio
    URI InvenesisPortfolio
    VERSION 1.0
    RESOURCE_PREFIX "/"
    SOURCES
        AppConfig.h
    QML_FILES
        ${QML_SOURCES}
    RESOURCES
        ${ASSET_RESOURCES}
)

# Link Qt 6 runtime dependencies
target_link_libraries(MaximeAlessandriPortfolio
    PRIVATE
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::Network
        Qt6::Quick3D
        Qt6::Quick3DAssetUtils
        Qt6::QuickControls2
)

# WebAssembly Optimization Flags
set(WASM_PRELOAD_ASSETS_DIR "" CACHE PATH "Optional directory of 3D .glb assets to preload into Emscripten VFS at /assets")

if(EMSCRIPTEN)
    target_link_options(MaximeAlessandriPortfolio PRIVATE
        "-sALLOW_MEMORY_GROWTH=1"
        "-sMAXIMUM_MEMORY=1073741824"
        "-sINITIAL_MEMORY=134217728"
    )

    if(WASM_PRELOAD_ASSETS_DIR AND EXISTS "${WASM_PRELOAD_ASSETS_DIR}")
        file(TO_CMAKE_PATH "${WASM_PRELOAD_ASSETS_DIR}" _wasm_assets_cmake)
        target_link_options(MaximeAlessandriPortfolio PRIVATE
            "SHELL:--preload-file ${_wasm_assets_cmake}@/assets"
        )
    endif()
endif()
