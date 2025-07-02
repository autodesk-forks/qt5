#!/bin/bash
#################################################
#@file VerifyNoGPL.sh
#@brief Verification script to ensure no GPL binaries are present (Linux/macOS)
#@team FARA/CM (Consistent Material scrum team)
#################################################

# Function to check for GPL components in a given installation path
check_gpl_components() {
    local INSTALL_PATH=$1
    local PLATFORM=$2
    local GPL_COMPONENTS_FOUND=0
    
    echo
    echo "#################################################"
    echo "Verifying Qt installation contains no GPL components..."
    echo "Installation path: $INSTALL_PATH"
    echo "Platform: $PLATFORM"
    echo "#################################################"
    echo

    if [ ! -d "$INSTALL_PATH" ]; then
        echo "ERROR: Installation path does not exist: $INSTALL_PATH"
        return 1
    fi

    # Check for GPL shared libraries
    echo "Checking for GPL shared libraries..."
    
    if [ "$PLATFORM" = "Linux" ]; then
        # Linux .so files
        if find "$INSTALL_PATH" -name "libQt6VirtualKeyboard*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: VirtualKeyboard library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Charts*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: Charts library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6DataVisualization*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: DataVisualization library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Quick3D*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: Quick3D library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Designer*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: Designer library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Coap*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: Coap library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Mqtt*.so*" 2>/dev/null | grep -q .; then
            echo "ERROR: Mqtt library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
    elif [ "$PLATFORM" = "macOS" ]; then
        # macOS .dylib files and frameworks
        if find "$INSTALL_PATH" -name "libQt6VirtualKeyboard*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: VirtualKeyboard library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "*Qt6VirtualKeyboard*" -path "*/Frameworks/*" 2>/dev/null | grep -q .; then
            echo "ERROR: VirtualKeyboard framework found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Charts*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: Charts library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "*Qt6Charts*" -path "*/Frameworks/*" 2>/dev/null | grep -q .; then
            echo "ERROR: Charts framework found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6DataVisualization*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: DataVisualization library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Quick3D*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: Quick3D library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Designer*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: Designer library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Coap*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: Coap library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
        if find "$INSTALL_PATH" -name "libQt6Mqtt*.dylib" 2>/dev/null | grep -q .; then
            echo "ERROR: Mqtt library found - GPL component present!"
            GPL_COMPONENTS_FOUND=1
        fi
    fi

    # Check for GPL QML modules (common for both platforms)
    echo "Checking for GPL QML modules..."
    if [ -d "$INSTALL_PATH/qml/QtQuick/VirtualKeyboard" ]; then
        echo "ERROR: VirtualKeyboard QML found - GPL component present!"
        GPL_COMPONENTS_FOUND=1
    fi
    if [ -d "$INSTALL_PATH/qml/QtCharts" ]; then
        echo "ERROR: Charts QML found - GPL component present!"
        GPL_COMPONENTS_FOUND=1
    fi
    if [ -d "$INSTALL_PATH/qml/QtDataVisualization" ]; then
        echo "ERROR: DataVisualization QML found - GPL component present!"
        GPL_COMPONENTS_FOUND=1
    fi
    if [ -d "$INSTALL_PATH/qml/QtQuick3D" ]; then
        echo "ERROR: Quick3D QML found - GPL component present!"
        GPL_COMPONENTS_FOUND=1
    fi
    if [ -d "$INSTALL_PATH/qml/Qt/labs/lottieqt" ]; then
        echo "ERROR: Lottie QML found - GPL component present!"
        GPL_COMPONENTS_FOUND=1
    fi

    # Check for GPL binaries (common for both platforms)
    echo "Checking for GPL executables..."
    if [ -f "$INSTALL_PATH/bin/designer" ]; then
        echo "ERROR: Qt Designer executable found - GPL component present!"
        GPL_COMPONENTS_FOUND=1
    fi

    echo
    if [ $GPL_COMPONENTS_FOUND -eq 0 ]; then
        echo "SUCCESS: No GPL components detected in Qt installation!"
        echo "The build successfully excluded all GPL-licensed binaries."
        return 0
    else
        echo "ERROR: GPL components were found in the installation!"
        echo "Please check the build configuration and exclusion lists."
        return 1
    fi
}

# Main script logic
if [ $# -eq 0 ]; then
    # Auto-detect platform and use default paths
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Detected platform: Linux"
        if [ -d "/out/debug" ]; then
            echo "Checking debug build..."
            check_gpl_components "/out/debug" "Linux"
            DEBUG_RESULT=$?
        fi
        if [ -d "/out/release" ]; then
            echo "Checking release build..."  
            check_gpl_components "/out/release" "Linux"
            RELEASE_RESULT=$?
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Detected platform: macOS"
        CUR_DIR=$(dirname "$0")
        QT_ROOT_PATH="$CUR_DIR/.."
        if [ -d "$QT_ROOT_PATH/Build/qt5.mac/debug" ]; then
            echo "Checking debug build..."
            check_gpl_components "$QT_ROOT_PATH/Build/qt5.mac/debug" "macOS"
            DEBUG_RESULT=$?
        fi
        if [ -d "$QT_ROOT_PATH/Build/qt5.mac/release" ]; then
            echo "Checking release build..."
            check_gpl_components "$QT_ROOT_PATH/Build/qt5.mac/release" "macOS"
            RELEASE_RESULT=$?
        fi
    else
        echo "ERROR: Unsupported platform: $OSTYPE"
        exit 1
    fi
    
    # Overall result
    if [ "${DEBUG_RESULT:-0}" -eq 0 ] && [ "${RELEASE_RESULT:-0}" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
else
    # Manual path specification
    INSTALL_PATH=$1
    PLATFORM=${2:-"Linux"}
    check_gpl_components "$INSTALL_PATH" "$PLATFORM"
    exit $?
fi

echo
echo "#################################################"
echo "Verification complete."
echo "#################################################" 