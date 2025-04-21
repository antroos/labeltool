#!/bin/bash

# Путь к приложению
APP_BUNDLE="/Users/ivanpasichnyk/Labeling tool/labeltool/WeLabelDataRecorder.app"
BUNDLE_ID="com.labeltool.welabeldatarecorder"

echo "🔑 Настройка разрешений для WeLabelDataRecorder"
echo "===================================="
echo "Приложение: $APP_BUNDLE"
echo ""

# Проверка существования приложения
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Ошибка: Приложение не найдено по указанному пути"
    echo "Сначала выполните ./build_app.sh для создания приложения"
    exit 1
fi

echo "1. Запрашиваем разрешения на запись экрана"
echo "-----------------------------------"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
echo "   ✓ Открыты настройки записи экрана"
echo "   ⚠️ Пожалуйста, нажмите '+' и выберите WeLabelDataRecorder.app"
echo "   ⚠️ Убедитесь, что установлена галочка напротив приложения"
echo ""
read -p "Нажмите Enter после предоставления разрешения на запись экрана... " -r

echo "2. Запрашиваем разрешения на доступность (Accessibility)"
echo "-----------------------------------"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
echo "   ✓ Открыты настройки доступности"
echo "   ⚠️ Пожалуйста, нажмите '+' и выберите WeLabelDataRecorder.app"
echo "   ⚠️ Убедитесь, что установлена галочка напротив приложения"
echo ""
read -p "Нажмите Enter после предоставления разрешения на доступность... " -r

echo "3. Проверка статуса разрешений"
echo "-----------------------------------"
echo "Проверка доступов может быть выполнена только с правами администратора."
echo "Для проверки, выполните следующие команды в отдельном терминале с правами sudo:"
echo ""
echo "sudo sqlite3 ~/Library/Application\\ Support/com.apple.TCC/TCC.db 'SELECT client,allowed FROM access WHERE service=\"kTCCServiceScreenCapture\" AND client=\"$BUNDLE_ID\"'"
echo "sudo sqlite3 ~/Library/Application\\ Support/com.apple.TCC/TCC.db 'SELECT client,allowed FROM access WHERE service=\"kTCCServiceAccessibility\" AND client=\"$BUNDLE_ID\"'"
echo ""

echo "4. Перезапуск приложения"
echo "-----------------------------------"
killall WeLabelDataRecorder 2>/dev/null || true
echo "   ✓ Приложение остановлено (если было запущено)"
echo "   ✓ Запуск приложения с новыми разрешениями..."
open "$APP_BUNDLE"

echo ""
echo "✅ Процесс настройки разрешений завершен"
echo "⚠️ Если приложение продолжает запрашивать разрешения, попробуйте:"
echo "   1. Закрыть приложение полностью"
echo "   2. Выполнить ./build_app.sh для пересборки"
echo "   3. Запустить этот скрипт снова"
echo ""
echo "Для дополнительной диагностики воспользуйтесь ./check_permissions_status.swift" 