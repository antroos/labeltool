#!/usr/bin/env swift

import Foundation
import AppKit

print("🔍 Проверка статуса разрешений для WeLabelDataRecorder")
print("==================================")

// Функция для запуска процесса и получения его вывода
func runProcess(_ path: String, args: [String]) -> (output: String, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.executableURL = URL(fileURLWithPath: path)
    task.arguments = args
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output, task.terminationStatus)
    } catch {
        return ("Ошибка: \(error)", 1)
    }
}

// Проверяем существует ли приложение
let appPath = "/Users/ivanpasichnyk/Labeling tool/labeltool/WeLabelDataRecorder.app"
if !FileManager.default.fileExists(atPath: appPath) {
    print("❌ Ошибка: Приложение не найдено по пути: \(appPath)")
    exit(1)
}

// Проверяем Info.plist
let infoPlistPath = "\(appPath)/Contents/Info.plist"
if !FileManager.default.fileExists(atPath: infoPlistPath) {
    print("❌ Ошибка: Info.plist не найден по пути: \(infoPlistPath)")
} else {
    print("✅ Info.plist существует")
    
    // Проверяем наличие всех необходимых ключей в Info.plist
    let plistResult = runProcess("/usr/bin/plutil", args: ["-p", infoPlistPath])
    let plistContent = plistResult.output
    
    let requiredKeys = [
        "NSScreenCaptureUsageDescription",
        "NSAccessibilityUsageDescription",
        "NSAppleEventsUsageDescription"
    ]
    
    for key in requiredKeys {
        if plistContent.contains("\"\(key)\"") {
            print("  ✅ Ключ \(key) найден в Info.plist")
        } else {
            print("  ❌ Ключ \(key) ОТСУТСТВУЕТ в Info.plist")
        }
    }
}

// Проверяем entitlements
let entitlementsPath = "\(appPath)/Contents/Resources/WeLabelDataRecorder.entitlements"
if !FileManager.default.fileExists(atPath: entitlementsPath) {
    print("❌ Ошибка: Entitlements файл не найден по пути: \(entitlementsPath)")
} else {
    print("✅ Entitlements файл существует")
    
    // Проверяем наличие всех необходимых ключей в entitlements
    let entitlementsResult = runProcess("/usr/bin/plutil", args: ["-p", entitlementsPath])
    let entitlementsContent = entitlementsResult.output
    
    let requiredEntitlements = [
        "com.apple.security.screen-recording",
        "com.apple.security.automation.apple-events"
    ]
    
    for key in requiredEntitlements {
        if entitlementsContent.contains("\"\(key)\"") {
            print("  ✅ Ключ \(key) найден в entitlements")
        } else {
            print("  ❌ Ключ \(key) ОТСУТСТВУЕТ в entitlements")
        }
    }
}

print("\n📋 Проверка цифровой подписи")
let codesignResult = runProcess("/usr/bin/codesign", args: ["-dv", "--verbose=4", appPath])
print(codesignResult.output)

print("\n📋 Проверка предоставленных разрешений в системе")
print("Примечание: Для полной проверки необходимо запустить с правами администратора (sudo)")

// Проверяем статус в TCC.db (Terminal не может получить доступ к этим данным без прав sudo)
print("\nДля проверки статуса разрешений, выполните в Терминале как администратор:")
print("sudo sqlite3 ~/Library/Application\\ Support/com.apple.TCC/TCC.db 'SELECT client,allowed FROM access WHERE service=\"kTCCServiceScreenCapture\" AND client=\"com.labeltool.welabeldatarecorder\"'")
print("sudo sqlite3 ~/Library/Application\\ Support/com.apple.TCC/TCC.db 'SELECT client,allowed FROM access WHERE service=\"kTCCServiceAccessibility\" AND client=\"com.labeltool.welabeldatarecorder\"'")

print("\n🔸 Инструкции по предоставлению разрешений вручную:")
print("1. Откройте Системные настройки → Конфиденциальность и безопасность → Запись экрана")
print("   Убедитесь, что WeLabelDataRecorder присутствует в списке и имеет галочку")
print("")
print("2. Откройте Системные настройки → Конфиденциальность и безопасность → Специальные возможности")
print("   Убедитесь, что WeLabelDataRecorder присутствует в списке и имеет галочку")
print("")
print("3. После предоставления разрешений перезапустите приложение")
print("   killall WeLabelDataRecorder; open '/Users/ivanpasichnyk/Labeling tool/labeltool/WeLabelDataRecorder.app'") 