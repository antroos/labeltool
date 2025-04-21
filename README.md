# WeLabelDataRecorder

A macOS application for recording screen activities and user interactions to create labeled datasets for AI training.

## Features

- Record screen activities including mouse movements, clicks, and keyboard input
- Capture screenshots at regular intervals and on user interaction
- Analyze UI element relationships (hierarchical, spatial, functional, logical)
- Visualize UI relationships as graphical networks
- Export recorded sessions in multiple formats (JSON, COCO, YOLO) for machine learning
- Generate structured data for training UI automation and understanding models

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

### Application Flow

1. **Application Launch**:
   - Normal mode: Shows UI with recording controls
   - Test mode: Generates a sample session and exports it (`--test-export <path>`)

2. **Recording Process**:
   - Captures periodic screenshots
   - Records mouse and keyboard events
   - Tracks UI element interactions via accessibility APIs

3. **UI Element Relationship Analysis**:
   - For each UI element interaction, analyzes relationships with other elements:
     - Hierarchical (parent, child, sibling)
     - Spatial (above, below, left, right)
     - Functional (button controls a form, label describes a field)
     - Logical (sequence, similar naming patterns)

4. **Data Export**:
   - Exports in multiple formats:
     - JSON: Raw data with full details
     - COCO: For computer vision applications
     - YOLO: For object detection models
   - Includes session metadata, interactions, UI element information, relationships, and screenshots

5. **Visualization**:
   - Generates DOT graphs of UI element relationships
   - Can be converted to PNG images for visual analysis

### Test Export Mode

For quick testing and demonstration, use the test export mode:

```bash
chmod +x run_test_export.sh
./run_test_export.sh
```

This will:
1. Create a test session with sample data
2. Export it in all supported formats
3. Open the export directory for inspection

## Recent Updates

### UI Element Relationship Analyzer

- Implemented comprehensive relationship analysis between UI elements
- Added support for hierarchical, spatial, functional, and logical relationships
- Integrated relevance scoring for relationship prioritization
- Created visualization capabilities using DOT graph format
- Added export of relationship data to all formats

### Export System Enhancements

- Completed implementation for JSON, COCO, and YOLO export formats
- Added structured metadata for all exports
- Implemented proper organization of files and directories
- Added support for element relationship export in all formats

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
- **UI Element Relationship Analyzer**: Analyzes connections between UI elements
- **User Interaction Models**: Defines data structures for different user interactions

## Roadmap

Our development roadmap includes the following milestones:

1. ✅ **Basic macOS application setup** - Complete
2. ✅ **Screen recording and user action capturing** - Complete
3. ✅ **Data storage system** - Complete
4. ✅ **Application bundling and permissions handling** - Complete
5. ✅ **UI Element Annotation** - Complete
   - ✅ Basic accessibility data collection
   - ✅ UI element detection during mouse clicks
   - ✅ UI element detection during keyboard input
   - ✅ UI element hierarchy and relationship tracking
   - ✅ Advanced element properties collection
6. ✅ **Export capabilities for ML training** - Complete
   - ✅ Basic JSON export
   - ✅ COCO format export for computer vision
   - ✅ YOLO format export for object detection
7. 🔄 **Performance optimization and UX improvements** - In Progress
   - 🚀 **[NEXT PRIORITY]** Make recording more efficient
   - 🚀 **[NEXT PRIORITY]** Improve user interface for session management
   - ⏳ Add filtering capabilities for recordings
8. ⏳ **Web interface integration** - Planned
   - Create simple web viewer for recorded sessions
   - Add annotation capabilities in web interface
9. ⏳ **Comprehensive testing and stabilization** - Planned
   - Unit and integration tests
   - Performance optimization
   - Documentation

## Next Up (v1.3.0 Development)

1. **Enhanced Relationship Analysis**
   - Implement more advanced context-aware relationship detection
   - Add semantic understanding of UI patterns
   - Improve relevance scoring algorithms

2. **Performance & Stability Improvements**
   - Optimize relationship analysis for large UI hierarchies
   - Reduce memory usage during long recording sessions
   - Add support for multi-monitor setups

3. **Integration Capabilities**
   - Add API for integrating with other tools
   - Support for collaborative dataset creation
   - Integration with popular ML frameworks

## Development

### Building from Source

```bash
swift build -c release
```

### Running Tests

```bash
swift test
```

### Running Test Export

To quickly test the export functionality:

```bash
chmod +x run_test_export.sh
./run_test_export.sh
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 