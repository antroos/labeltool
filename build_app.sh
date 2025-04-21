#!/bin/bash

# Root directory
ROOT_DIR=$(pwd)

# App name, bundle id, and path to app bundle
APP_NAME="WeLabelDataRecorder"
BUNDLE_ID="com.labeltool.welabeldatarecorder"
APP_BUNDLE="${ROOT_DIR}/${APP_NAME}.app"

# Build directory
BUILD_DIR="${ROOT_DIR}/.build/release"

echo "Building ${APP_NAME} App..."

# Remove old app bundle if exists
echo "Removing old app bundle if exists..."
if [ -d "${APP_BUNDLE}" ]; then
    rm -rf "${APP_BUNDLE}"
fi

# Build Swift package
echo "Building Swift package..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
echo "Copying binary..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Info.plist instead of creating a new one
echo "Copying Info.plist..."
cp "${ROOT_DIR}/complete_Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Ensure bundle ID is consistent
echo "Ensuring bundle ID is consistent..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${APP_BUNDLE}/Contents/Info.plist"

# Copy entitlements file
echo "Copying entitlements file..."
cp "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}/Contents/Resources/"

# Sign application with entitlements
echo "Signing with entitlements..."
codesign --force --deep --sign - --entitlements "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" --identifier "${BUNDLE_ID}" "${APP_BUNDLE}"

echo "App bundle created at ${APP_BUNDLE}"
echo "Run the app with: open '${APP_BUNDLE}'" 