#!/bin/bash

# Build script for WeLabelDataRecorder
# This script runs tests and builds the application

set -e  # Exit on error

echo "=== Building WeLabelDataRecorder ==="

# Directory setup
ROOT_DIR="$(pwd)"
BUILD_DIR="${ROOT_DIR}/.build"
DERIVED_DATA="${ROOT_DIR}/.derivedData"

# Ensure build directory exists
mkdir -p "${BUILD_DIR}"
mkdir -p "${DERIVED_DATA}"

echo "=== Running Swift tests ==="
swift test --build-path "${BUILD_DIR}"

# If tests pass, build the application
if [ $? -eq 0 ]; then
    echo "=== Tests passed, building application ==="
    
    swift build --build-path "${BUILD_DIR}" -c release
    
    # Create app bundle structure
    APP_BUNDLE="${BUILD_DIR}/WeLabelDataRecorder.app"
    APP_CONTENTS="${APP_BUNDLE}/Contents"
    APP_MACOS="${APP_CONTENTS}/MacOS"
    APP_RESOURCES="${APP_CONTENTS}/Resources"
    
    mkdir -p "${APP_MACOS}"
    mkdir -p "${APP_RESOURCES}"
    
    # Copy binary
    cp "${BUILD_DIR}/release/WeLabelDataRecorder" "${APP_MACOS}/"
    
    # Copy Info.plist
    cp "${ROOT_DIR}/WeLabelDataRecorder/Sources/Info.plist" "${APP_CONTENTS}/"
    
    # Copy entitlements
    cp "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_CONTENTS}/"
    
    echo "=== Build complete ==="
    echo "Application bundle created at: ${APP_BUNDLE}"
else
    echo "=== Tests failed, build aborted ==="
    exit 1
fi 