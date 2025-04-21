# WeLabelDataRecorder Documentation

## Overview

WeLabelDataRecorder is a macOS application designed to capture and record user interactions with the system UI, creating labeled datasets for machine learning applications focused on user interface analysis and automation. The tool records screen captures, accessibility information, and user interactions to generate comprehensive datasets that can be exported in various formats.

## Key Features

- **Screen Recording**: Captures screenshots and video of user activity
- **Accessibility Integration**: Records UI element properties, hierarchies, and relationships
- **Interaction Tracking**: Logs mouse movements, clicks, keyboard input, and system events
- **Relationship Analysis**: Identifies connections between UI elements (hierarchical, spatial, functional, logical)
- **Multiple Export Formats**: Supports JSON, COCO, and YOLO formats for machine learning applications
- **Entitlements**: Includes necessary permissions for screen recording, camera access, and accessibility features

## System Requirements

- macOS 10.15 (Catalina) or later
- Administrative access for permission setup
- Sufficient disk space for recording sessions

## Installation

1. Download the latest release from the repository
2. Open the application bundle (`WeLabelDataRecorder.app`)
3. Grant the necessary permissions when prompted:
   - Screen Recording
   - Accessibility access
   - Camera access (if needed)
   - Microphone access (if needed)

## Permissions Configuration Guide

WeLabelDataRecorder requires specific system permissions to function properly. This section details how these permissions are configured and how to troubleshoot permission-related issues.

### Required Permissions

The application requires the following permissions:

1. **Screen Recording**: Essential for capturing screenshots and videos
2. **Accessibility**: Required for accessing UI element information
3. **Camera**: Required due to macOS security model, but not actively used unless needed
4. **File Access**: For saving recordings to disk

### How Permissions Are Configured

The application uses two key files to configure permissions:

1. **Info.plist**: Located at `complete_Info.plist`, this file contains usage descriptions required by macOS:
   ```xml
   <key>NSScreenCaptureUsageDescription</key>
   <string>Приложение требует разрешения для записи экрана, чтобы фиксировать взаимодействия с интерфейсом.</string>
   
   <key>NSAccessibilityUsageDescription</key>
   <string>Приложение нуждается в доступе к Accessibility для записи информации об UI элементах и отслеживания нажатий клавиш и мыши.</string>
   
   <key>NSCameraUsageDescription</key>
   <string>Не используется, но требуется системой.</string>
   ```

2. **Entitlements File**: Located at `WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements`, this file specifies which permissions the app needs:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <false/>
   
   <key>com.apple.security.screen-recording</key>
   <true/>
   
   <key>com.apple.security.automation.apple-events</key>
   <true/>
   ```

### Build Process For Correct Permissions

Our application uses a custom build script `build_app.sh` that ensures all permissions are properly configured:

1. Compiles the Swift package
2. Creates the app bundle structure
3. Copies the binary, entitlements, and Info.plist
4. Signs the app with the entitlements

```bash
# Copy complete_Info.plist instead of creating a new one
echo "Copying Info.plist..."
cp "${ROOT_DIR}/complete_Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Copy entitlements file
echo "Copying entitlements file..."
cp "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}/Contents/Resources/"

# Sign application with entitlements
echo "Signing with entitlements..."
codesign --force --deep --sign - --entitlements "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}"
```

### Troubleshooting Permission Issues

We've included a diagnostic script `check_permissions_status.swift` to verify that permissions are correctly configured:

```bash
chmod +x check_permissions_status.swift
./check_permissions_status.swift
```

This script checks:
1. The existence and content of Info.plist
2. The existence and content of entitlements file
3. Whether the application is properly signed
4. Provides instructions to verify system-level permission grants

### Known Permission Issues and Solutions

1. **App Crashes with Camera Permission Error**:
   - Symptom: The app crashes with message `This app has crashed because it attempted to access privacy-sensitive data without a usage description`
   - Solution: Ensure `NSCameraUsageDescription` is present in Info.plist even if camera is not used

2. **Screen Recording Not Working**:
   - Solution: Reset screen recording permissions using Terminal:
     ```bash
     tccutil reset ScreenCapture
     ```
   - Then restart the application and grant permission when prompted

3. **Accessibility Features Not Working**:
   - Solution: Reset accessibility permissions using Terminal:
     ```bash
     tccutil reset Accessibility
     ```
   - Then restart the application and grant permission when prompted

4. **Permission Prompts Not Appearing**:
   - Solution: Check system permissions manually in System Preferences → Security & Privacy → Privacy
   - Add the application manually to Screen Recording and Accessibility sections

### Testing Permissions After Grant

After granting permissions, you can verify they are working with:

```bash
log show --predicate 'process == "WeLabelDataRecorder"' --last 2m | grep -i "error"
```

If no permission errors appear, the application is correctly configured.

## Usage Guide

### Starting a Recording Session

1. Launch the application
2. Click on the status bar icon or open the main window
3. Configure recording settings:
   - Recording area (full screen or custom region)
   - Frame rate and quality
   - Include/exclude specific applications
4. Click "Start Recording" to begin

### During Recording

- A status indicator will show that recording is in progress
- User interactions will be automatically tracked
- Optionally add manual annotations or markers during recording

### Ending a Recording Session

1. Click "Stop Recording" in the menu bar or main window
2. Provide a name for the session
3. Select where to save the session data

### Exporting Data

1. Select a recorded session from the sessions list
2. Choose Export from the menu
3. Select an export format (JSON, COCO, YOLO)
4. Choose a destination folder
5. Click "Export" to generate the dataset

## Accessibility Integration

WeLabelDataRecorder leverages macOS's Accessibility API to:

- Identify UI elements on screen
- Track focus changes
- Record element properties (role, title, identifier, etc.)
- Build element hierarchies
- Monitor state changes

## Relationship Analysis System

The application analyzes relationships between UI elements using multiple strategies:

1. **Hierarchy Relationships**: Based on the UI element tree structure
   - Parent/child relationships
   - Sibling relationships

2. **Spatial Relationships**: Based on screen positioning
   - Containment (element within another)
   - Overlapping elements
   - Proximity-based relationships

3. **Functional Relationships**: Based on interaction patterns
   - Controls that affect other elements
   - Label-to-control associations

4. **Logical Relationships**: Based on semantic meaning
   - Elements that form logical groups
   - Sequential flows (wizards, forms)

## Troubleshooting

### Permission Issues

If the application doesn't have full functionality:

1. Check System Preferences > Security & Privacy > Privacy
2. Ensure WeLabelDataRecorder is enabled under:
   - Screen Recording
   - Accessibility
   - Camera (if needed)
   - Microphone (if needed)

### Recording Failures

If recordings fail to start or stop properly:

1. Restart the application
2. Check available disk space
3. Verify no other screen recording applications are running

## Privacy Considerations

- All data is stored locally on your system
- No automatic data transmission to external servers
- Be aware of sensitive information in your recordings
- Review screenshots before sharing datasets

## Advanced Usage

### Command Line Interface

For automation and integration with other tools:

```
WeLabelDataRecorderCLI [options]
```

Options:
- `--record [duration]`: Start recording for specified duration
- `--export [session_id] [format]`: Export a specific session
- `--list-sessions`: Show all available sessions
- `--config [path]`: Use custom configuration file

## Roadmap

Planned features for future releases:

- Real-time data labeling during recording
- Cloud integration for dataset sharing
- Custom annotation tools
- Advanced filtering options for exports
- Batch processing capabilities

## Support

For issues, questions, or feature requests:

- Check the GitHub repository Issues section
- Contact the development team at support@welabeldatarecorder.example.com