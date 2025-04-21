# WeLabelDataRecorder

A macOS application for recording screen activities and user interactions to create labeled datasets for AI training.

## Features

- Record screen activities including mouse movements, clicks, and keyboard input
- Capture screenshots at regular intervals and on user interaction
- Export recorded sessions in JSON format for further processing
- Extensible design with support for multiple export formats (JSON, COCO, YOLO)

## Requirements

- macOS 11.0 or later
- Xcode 13.0 or later (for development)

## Installation

1. Clone this repository
2. Run the build script to create the application:
   ```bash
   chmod +x build_app.sh
   ./build_app.sh
   ```
3. The application will be built at `./WeLabelDataRecorder.app`

## Permission Requirements

WeLabelDataRecorder requires several system permissions to function correctly. When you first launch the application, it will request:

- **Screen Recording Permission**: Required to capture screenshots and video
- **Accessibility Permission**: Required to detect UI elements via Accessibility API
- **Camera Permission**: Required by macOS security model (even though camera is not actively used)

### Permission Configuration

The permissions are configured through two key files:

1. **complete_Info.plist**: Contains usage descriptions required by macOS
2. **WeLabelDataRecorder.entitlements**: Specifies which entitlements the app needs

The build script automatically incorporates these permissions into the app bundle.

### Troubleshooting Permissions

If you experience permission issues:

1. Use the included diagnostic script:
   ```bash
   chmod +x check_permissions_status.swift
   ./check_permissions_status.swift
   ```

2. For permission issues with screen recording or accessibility:
   ```bash
   # Reset screen recording permissions
   tccutil reset ScreenCapture
   
   # Reset accessibility permissions
   tccutil reset Accessibility
   ```

3. Manually verify permissions in System Preferences → Security & Privacy → Privacy

For full details on permission configuration, see `DOCUMENTATION.md`.

## Usage

1. Launch the application
2. Grant necessary permissions for screen recording and accessibility when prompted
3. Click "Start Recording" to begin a recording session
4. Perform the activities you want to record
5. Click "Stop Recording" to end the session
6. Click "Export Last Session" to save the recorded data

## Recent Updates

### Fixed Permissions and Application Build System

- Fixed permissions issues for screen recording and accessibility
- Updated Info.plist with proper usage descriptions
- Optimized entitlements configuration
- Added permissions check utility script
- Improved application bundling process

### Fixed Session Export

- Added proper serialization support for AppKit/CoreGraphics types (NSPoint, CGRect)
- Implemented robust session storage mechanisms with in-memory backup
- Enhanced logging for improved debugging
- Added direct reference to the last session in the view controller

## Architecture

The application is organized into several key components:

- **Recording Manager**: Handles screen recording, event monitoring, and accessibility features
- **Session Manager**: Manages recording sessions, stores interaction data
- **Export Manager**: Handles exporting sessions to various formats
- **User Interaction Models**: Defines data structures for different user interactions

## Roadmap

Our development roadmap includes the following milestones:

1. ✅ **Basic macOS application setup** - Complete
2. ✅ **Screen recording and user action capturing** - Complete
3. ✅ **Data storage system** - Complete
4. ✅ **Application bundling and permissions handling** - Complete
5. 🔄 **UI Element Annotation** - In Progress
   - ✅ Basic accessibility data collection implemented
   - ✅ UI element detection during mouse clicks
   - ✅ UI element detection during keyboard input
   - 🚀 **[NEXT PRIORITY]** UI element hierarchy and relationship tracking
   - ⏳ Advanced element properties collection
6. 🔄 **Export capabilities for ML training** - Partially Complete
   - ✅ Basic JSON export
   - 🚀 **[NEXT PRIORITY]** COCO format export for computer vision
   - ⏳ YOLO format export for object detection
7. ⏳ **Performance optimization and UX improvements** - Planned
   - Make recording more efficient
   - Improve user interface for session management
   - Add filtering capabilities for recordings
8. ⏳ **Web interface integration** - Planned
   - Create simple web viewer for recorded sessions
   - Add annotation capabilities in web interface
9. ⏳ **Comprehensive testing and stabilization** - Planned
   - Unit and integration tests
   - Performance optimization
   - Documentation

## Next Up (v1.2.0 Development)

1. **Complete UI Element Relationship Analyzer**
   - Implement improved UI element hierarchy detection
   - Add relationship tracking between UI elements
   - Create visualization tools for element hierarchies

2. **Finish COCO Export Format**
   - Complete implementation of ExportManager.exportToCOCO
   - Add proper category mapping for UI elements
   - Generate valid COCO-format annotations

3. **Performance & Stability Improvements**
   - Optimize screenshot capture process
   - Reduce memory usage during long recording sessions
   - Implement auto-save functionality

## Development

### Building from Source

```bash
swift build -c release
```

### Running Tests

```bash
swift test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 