#!/bin/bash

# Script to build a full app bundle with correct entitlements

set -e  # Exit on error

echo "=== Building WeLabelDataRecorder App ==="

# Directory setup
ROOT_DIR="$(pwd)"
BUILD_DIR="${ROOT_DIR}/.build"
APP_BUNDLE="${ROOT_DIR}/WeLabelDataRecorder.app"

# Remove old app bundle if it exists
echo "=== Removing old app bundle if exists ==="
rm -rf "${APP_BUNDLE}"

# Build the Swift package
echo "=== Building Swift package ==="
swift build -c release

# Create app bundle structure
echo "=== Creating App Bundle ==="
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
echo "=== Copying binary ==="
cp "${BUILD_DIR}/release/WeLabelDataRecorder" "${APP_BUNDLE}/Contents/MacOS/"
chmod +x "${APP_BUNDLE}/Contents/MacOS/WeLabelDataRecorder"

# Copy Info.plist
echo "=== Copying Info.plist ==="
cp "${ROOT_DIR}/fixed_Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Create PkgInfo
echo "=== Creating PkgInfo ==="
echo "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Sign with entitlements
echo "=== Signing with entitlements ==="
codesign --force --deep --sign - --entitlements "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}"

echo "=== App Build Complete ==="
echo "App bundle created at: ${APP_BUNDLE}"
echo "To run the app, execute: open '${APP_BUNDLE}'" 