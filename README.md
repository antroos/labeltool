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

## Usage

1. Launch the application
2. Grant necessary permissions for screen recording and accessibility when prompted
3. Click "Start Recording" to begin a recording session
4. Perform the activities you want to record
5. Click "Stop Recording" to end the session
6. Click "Export Last Session" to save the recorded data

## Recent Updates

### Fixed Session Export

Fixed an issue with session export functionality:
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
4. 🔄 **UI Element Annotation** - In Progress
   - ✅ Basic accessibility data collection implemented
   - ✅ UI element detection during mouse clicks
   - ✅ UI element detection during keyboard input
   - ⏳ Hierarchy and relationship tracking
   - ⏳ Advanced element properties collection
5. 🔄 **Export capabilities for ML training** - Partially Complete
   - ✅ Basic JSON export
   - ⏳ COCO format export for computer vision
   - ⏳ YOLO format export for object detection
6. ⏳ **Web interface integration** - Planned
   - Create simple web viewer for recorded sessions
   - Add annotation capabilities in web interface
7. ⏳ **Comprehensive testing and stabilization** - Planned
   - Unit and integration tests
   - Performance optimization
   - Documentation

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