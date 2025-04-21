#!/bin/bash

# Скрипт для создания полноценного .app файла WeLabelDataRecorder

echo "Building WeLabelDataRecorder App..."

# Устанавливаем переменные
ROOT_DIR=$(pwd)
BUILD_DIR=${ROOT_DIR}/.build/debug
APP_BUNDLE=${ROOT_DIR}/WeLabelDataRecorder.app

# Удаляем старый app bundle, если существует
echo "Removing old app bundle if exists..."
if [ -d "${APP_BUNDLE}" ]; then
    rm -rf "${APP_BUNDLE}"
fi

# Компилируем Swift пакет
echo "Building Swift package..."
swift build

# Создаем структуру app bundle
echo "Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Копируем исполняемый файл
echo "Copying binary..."
cp "${BUILD_DIR}/WeLabelDataRecorder" "${APP_BUNDLE}/Contents/MacOS/"
chmod +x "${APP_BUNDLE}/Contents/MacOS/WeLabelDataRecorder"

# Копируем complete_Info.plist вместо создания нового
echo "Copying Info.plist..."
cp "${ROOT_DIR}/complete_Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Копируем entitlements файл
echo "Copying entitlements file..."
cp "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}/Contents/Resources/"

# Подписываем приложение с entitlements
echo "Signing with entitlements..."
codesign --force --deep --sign - --entitlements "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}"

echo "App bundle created at ${APP_BUNDLE}"
echo "Run the app with: open '${APP_BUNDLE}'" 