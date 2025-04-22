import Foundation
import AppKit
import AVFoundation

class ScreenCapture: NSObject, AVCaptureFileOutputRecordingDelegate {
    private var outputURL: URL?
    private var captureSession: AVCaptureSession?
    private var captureOutput: AVCaptureMovieFileOutput?
    private var lastScreenshotImage: NSImage? // Кэш для последнего скриншота
    private let savePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("WeLabelScreenshots")
    
    override init() {
        super.init()
        
        // Create temporary directory if it doesn't exist
        try? FileManager.default.createDirectory(at: savePath, withIntermediateDirectories: true)
    }
    
    // Функция для захвата скриншота
    func captureScreenshot() -> NSImage? {
        // Если у нас есть кэшированный скриншот, возвращаем его
        if let lastImage = lastScreenshotImage {
            // Запускаем новый захват в фоне для следующего вызова
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureNewScreenshot()
            }
            return lastImage
        }
        
        // Нет кэшированного скриншота, пробуем сначала системную команду
        if let systemScreenshot = captureScreenshotWithSystemCommand() {
            lastScreenshotImage = systemScreenshot
            return systemScreenshot
        }
        
        // Если системная команда не сработала, используем Core Graphics
        return captureScreenshotWithCoreGraphics()
    }
    
    // Захватить новый скриншот для обновления кэша
    private func captureNewScreenshot() {
        if let systemScreenshot = captureScreenshotWithSystemCommand() {
            lastScreenshotImage = systemScreenshot
        } else if let cgScreenshot = captureScreenshotWithCoreGraphics() {
            lastScreenshotImage = cgScreenshot
        }
    }
    
    // Использование системной команды screencapture для создания скриншота
    private func captureScreenshotWithSystemCommand() -> NSImage? {
        // Генерируем временное имя файла
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "temp_screenshot_\(timestamp).png"
        let outputPath = savePath.appendingPathComponent(filename).path
        
        // Подготавливаем команду
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        
        // Аргументы для тихого создания скриншота без звука
        task.arguments = ["-x", outputPath]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                // Прочитаем файл как изображение
                if let image = NSImage(contentsOfFile: outputPath) {
                    // Удалим временный файл после успешного чтения
                    try? FileManager.default.removeItem(atPath: outputPath)
                    return image
                }
            }
            
            print("screencapture завершился с кодом: \(task.terminationStatus)")
            return nil
        } catch {
            print("Ошибка запуска screencapture: \(error)")
            return nil
        }
    }
    
    // Захват скриншота с помощью Core Graphics (запасной метод)
    private func captureScreenshotWithCoreGraphics() -> NSImage? {
        let displayID = CGMainDisplayID()
        
        guard let image = CGDisplayCreateImage(displayID) else {
            print("Не удалось создать изображение с дисплея")
            return nil
        }
        
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        return nsImage
    }
    
    // Save a captured screenshot to a file
    func saveScreenshot(_ image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation else {
            print("Failed to get TIFF representation")
            return false
        }
        
        guard let bitmap = NSBitmapImageRep(data: tiffData) else {
            print("Failed to create bitmap representation")
            return false
        }
        
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to create PNG data")
            return false
        }
        
        do {
            try pngData.write(to: url)
            return true
        } catch {
            print("Failed to write PNG data: \(error)")
            return false
        }
    }
    
    // Setup for video recording
    func setupVideoRecording() -> Bool {
        // Create a capture session
        captureSession = AVCaptureSession()
        
        // TODO: Implement full screen capture setup with AVCaptureScreenInput
        // This requires proper permissions and setup
        
        // For now, we'll just return false as it's not implemented
        return false
    }
    
    // Start recording video
    func startRecording(to outputURL: URL) -> Bool {
        self.outputURL = outputURL
        
        guard let captureSession = captureSession, captureSession.isRunning else {
            return false
        }
        
        // Create movie file output if not already created
        if captureOutput == nil {
            captureOutput = AVCaptureMovieFileOutput()
            
            if let captureOutput = captureOutput {
                if captureSession.canAddOutput(captureOutput) {
                    captureSession.addOutput(captureOutput)
                } else {
                    return false
                }
            }
        }
        
        // Start recording to file
        if let captureOutput = captureOutput, !captureOutput.isRecording {
            // Use self as the delegate since we've conformed to AVCaptureFileOutputRecordingDelegate
            captureOutput.startRecording(to: outputURL, recordingDelegate: self)
            return true
        }
        
        return false
    }
    
    // Stop recording video
    func stopRecording() {
        captureOutput?.stopRecording()
    }
    
    // Release resources
    func cleanup() {
        captureOutput = nil
        captureSession?.stopRunning()
        captureSession = nil
        outputURL = nil
        lastScreenshotImage = nil // Очищаем кэш
        
        // Удаляем временные файлы
        try? FileManager.default.removeItem(at: savePath)
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording to file: \(error)")
        } else {
            print("Successfully finished recording to \(outputFileURL.path)")
        }
    }
} 