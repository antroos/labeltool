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

## User Interface Overview

The application interface is organized into several key components:

### 1. Status Panel
- Located at the top of the window
- Displays current permission status for Screen Recording and Accessibility
- Shows available disk space for recordings
- Provides visual feedback during recording (red pulse animation)

### 2. Session List
- Central table view with columns for:
  - Thumbnail: Visual preview of the session
  - Session Info: ID, start/end times
  - Metrics: Duration and interaction count
  - Actions: Quick access to export functions
- Automatically updates when sessions are created or modified
- Allows selection of sessions for export

### 3. Control Buttons
- Start/Stop Recording: Toggles recording state with clear visual feedback
- Export Session: Exports the currently selected session
- Status indicator shows current application state

### 4. Visual Feedback
- Permission indicators change color based on status (red/green)
- Recording state is clearly visible
- Animations provide feedback for user actions

## Complete Application Workflow

WeLabelDataRecorder follows a comprehensive workflow for capturing, analyzing, and exporting UI interactions:

### 1. Application Launch

- **Normal Mode**: The application starts with a graphical interface showing recording controls
  - Creates a main window and a status bar item for easy access
  - Sets up permission checks and verification
  
- **Test Export Mode**: Can be launched with the `--test-export <path>` parameter
  - Creates a sample session with predefined interactions
  - Exports to all supported formats in the specified directory
  - Ideal for testing and demonstration purposes

### 2. Recording Process

- When "Start Recording" is clicked, the app:
  - Verifies necessary permissions
  - Initializes a new recording session
  - Starts event monitors for mouse and keyboard
  - Begins periodic screenshot capture (default: every 1 second)

- During recording, the app captures:
  - **Mouse Events**: Click, movement, scroll
  - **Keyboard Events**: Key presses, combinations
  - **UI Element Interactions**: When the user interacts with UI elements
  - **Screenshots**: Regular intervals and on significant events

### 3. UI Element Relationship Analysis

For each UI element interaction, the `UIElementRelationshipAnalyzer` performs:

- **Hierarchy Analysis**: Examines the DOM-like structure of the UI
  - Parent-child relationships
  - Sibling relationships
  - Container relationships (grandparents, etc.)

- **Spatial Analysis**: Examines physical layout
  - Position relationships (above, below, left, right)
  - Containment (elements inside other elements)
  - Overlap detection
  - Distance calculations

- **Functional Analysis**: Examines interaction patterns
  - Label-field associations
  - Button-form relationships
  - Control-container relationships
  - Action target identification

- **Logical Analysis**: Examines semantic connections
  - Elements with similar naming patterns
  - Elements that form logical groups
  - Sequential elements (steps, forms)
  - Potentially related elements based on behavior

Each relationship is assigned a relevance score (0.0-1.0) to indicate its importance, and relationships are sorted by this score.

### 4. Session Management

- When "Stop Recording" is clicked:
  - All monitoring components are stopped
  - The session is finalized with an end timestamp
  - Session data is saved to memory and disk
  - The UI updates to show export options
  - Session appears in the session list table

- Sessions are managed by the `SessionManager` which:
  - Maintains references to current and previous sessions
  - Handles saving/loading sessions from disk
  - Provides methods for creating and ending sessions
  - Facilitates export operations

### 5. Data Export

- When "Export Last Session" is clicked or the export button is pressed in the table:
  - User selects an export format and destination
  - `ExportManager` processes the session data
  - Creates a structured directory with all necessary files
  - Notifies when export is complete

- Export formats include:

  - **JSON**: Raw data with full details
    - `metadata.json`: Basic session information
    - `interactions.json`: All user interactions
    - `/screenshots`: Directory with all captured images
    - `/elements`: Directory with UI element hierarchies and relationships

  - **COCO**: Computer Vision format
    - `instances.json`: COCO-format annotation file
    - `/images`: Directory with all captured images
    - Categories for different UI element types
    - Bounding box coordinates and attributes

  - **YOLO**: Object Detection format
    - `classes.txt`: UI element class definitions
    - `/images`: Directory with all captured images
    - `/labels`: Directory with YOLO-format annotation files
    - Normalized coordinates for UI elements

### 6. Visualization

- Relationship data can be visualized as graphs:
  - Generated DOT files describe UI element relationships
  - Can be converted to images using GraphViz
  - Color-coding indicates relationship types
  - Supports interactive exploration of complex UI structures

## Permissions Configuration Guide

WeLabelDataRecorder requires specific system permissions to function properly. This section details how these permissions are configured and how to troubleshoot permission-related issues.

### Required Permissions

The application requires the following permissions:

1. **Screen Recording**: Essential for capturing screenshots and videos
2. **Accessibility**: Required for accessing UI element information
3. **File Access**: For saving recordings to disk

### How Permissions Are Configured

The application uses two key files to configure permissions:

1. **Info.plist**: Located at `complete_Info.plist`, this file contains usage descriptions required by macOS:
   ```xml
   <key>NSScreenCaptureUsageDescription</key>
   <string>Приложение требует разрешения для записи экрана, чтобы фиксировать взаимодействия с интерфейсом.</string>
   
   <key>NSAccessibilityUsageDescription</key>
   <string>Приложение нуждается в доступе к Accessibility для записи информации об UI элементах и отслеживания нажатий клавиш и мыши.</string>
   
   <key>NSAppleEventsUsageDescription</key>
   <string>Приложение нуждается в доступе к управлению другими приложениями для записи их взаимодействия с интерфейсом.</string>
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

### Permission Management Tools

The application includes several tools to manage permissions effectively:

1. **request_all_permissions.sh**: A helper script that guides the user through granting all necessary permissions:
   ```bash
   ./request_all_permissions.sh
   ```
   This script opens the system preference panels for each required permission and provides step-by-step instructions.

2. **check_permissions_status.swift**: A diagnostic tool that checks if the application has the correct permissions configuration:
   ```bash
   ./check_permissions_status.swift
   ```
   This reports on the existence and content of Info.plist, entitlements, and the application's signature.

3. **Visual Permission Indicators**: In the application's UI, colored indicators show the current status of each permission:
   - Green: Permission granted
   - Red: Permission missing

### Build Process For Correct Permissions

Our application uses a custom build script `build_app.sh` that ensures all permissions are properly configured:

1. Compiles the Swift package
2. Creates the app bundle structure
3. Copies the binary, entitlements, and Info.plist
4. Signs the app with the entitlements
5. Ensures a consistent bundle identifier

```bash
# Ensure bundle ID is consistent
echo "Ensuring bundle ID is consistent..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${APP_BUNDLE}/Contents/Info.plist"

# Copy entitlements file
echo "Copying entitlements file..."
cp "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" "${APP_BUNDLE}/Contents/Resources/"

# Sign application with entitlements
echo "Signing with entitlements..."
codesign --force --deep --sign - --entitlements "${ROOT_DIR}/WeLabelDataRecorder/Sources/WeLabelDataRecorder.entitlements" --identifier "${BUNDLE_ID}" "${APP_BUNDLE}"
```

### Troubleshooting Permission Issues

Common permission issues and their solutions:

1. **Screen Recording Not Working**:
   - Solution: Reset screen recording permissions using Terminal:
     ```bash
     tccutil reset ScreenCapture
     ```
   - Then restart the application and grant permission when prompted

2. **Accessibility Features Not Working**:
   - Solution: Reset accessibility permissions using Terminal:
     ```bash
     tccutil reset Accessibility
     ```
   - Then restart the application and grant permission when prompted

3. **Permission Prompts Not Appearing**:
   - Solution: Check system permissions manually in System Preferences → Security & Privacy → Privacy
   - Add the application manually to Screen Recording and Accessibility sections

4. **Permissions Reset After Rebuild**:
   - Solution: This is normal behavior when the app's identity changes
   - Use the `request_all_permissions.sh` script after each rebuild
   - The improved build script maintains a consistent app identity to minimize this issue

### Testing Permissions After Grant

After granting permissions, you can verify they are working with:

```bash
log show --predicate 'process == "WeLabelDataRecorder"' --last 2m | grep -i "error"
```

If no permission errors appear, the application is correctly configured.

## UI Element Relationship Analyzer

The UI Element Relationship Analyzer is a core component of the WeLabelDataRecorder application that identifies, analyzes, and scores relationships between UI elements. This component is critical for generating rich datasets that capture not just the visual appearance of UIs, but their underlying structure and semantic connections.

### Types of Relationships Analyzed

1. **Hierarchical Relationships**
   - **Parent**: The containing element directly above in the hierarchy
   - **Child**: Elements contained within the current element
   - **Sibling**: Elements that share the same parent
   - **Container**: Elements higher up in the hierarchy (grandparents, etc.)

2. **Spatial Relationships**
   - **Above/Below**: Elements positioned vertically relative to each other
   - **Left/Right**: Elements positioned horizontally relative to each other
   - **Contains/Contained**: Elements that spatially contain or are contained by others
   - **Overlapping**: Elements that visually overlap but don't fully contain each other

3. **Functional Relationships**
   - **Controls**: Buttons or elements that affect other elements
   - **Describes**: Labels that describe other UI elements
   - **Complements**: Elements that work together (like form fields and submit buttons)
   - **Acts On**: Elements that trigger actions on other elements

4. **Logical Relationships**
   - **Group**: Elements that form a logical group
   - **Sequence**: Elements used in a sequential workflow
   - **Alternative**: Elements that represent alternatives to each other
   - **Parallel**: Elements that represent parallel options

### Relationship Scoring System

Each identified relationship is assigned a relevance score between 0.0 and 1.0:

- **0.9 - 1.0**: Critical relationships (direct parent, primary label)
- **0.7 - 0.9**: Strong relationships (direct children, closely positioned elements)
- **0.5 - 0.7**: Moderate relationships (siblings, functionally related elements)
- **0.3 - 0.5**: Weak relationships (distant elements, potential connections)
- **< 0.3**: Not reported (too weak to be relevant)

Scores are calculated based on multiple factors:
- Proximity (closer elements score higher)
- Hierarchy level (direct relationships score higher)
- Visual properties (similar styling scores higher)
- Naming patterns (similar naming scores higher)
- Common UI patterns (recognized patterns score higher)

### Implementation

The analyzer is implemented in the `UIElementRelationshipAnalyzer` class:

```swift
class UIElementRelationshipAnalyzer {
    func analyzeRelationships(for targetElement: UIElementInfo) -> [RelatedElement] {
        var relatedElements: [RelatedElement] = []
        
        // Add hierarchical relationships
        relatedElements.append(contentsOf: findHierarchyRelationships(for: targetElement))
        
        // Add spatial relationships
        relatedElements.append(contentsOf: findSpatialRelationships(for: targetElement))
        
        // Add functional relationships
        relatedElements.append(contentsOf: findFunctionalRelationships(for: targetElement))
        
        // Add logical relationships
        relatedElements.append(contentsOf: findLogicalRelationships(for: targetElement))
        
        // Sort by relevance
        return relatedElements.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    // Individual analysis methods for each relationship type...
}
```

### Visualization Output

The analyzer can export relationships in DOT format for visualization:

```
digraph UIElementRelationships {
  // Graph of UI element relationships
  node [shape=box style=filled];

  // Central element
  "nameField" [label="AXTextField", fillcolor="lightblue"];

  // Related elements
  // Group: spatial
  "emailField" [label="AXTextField"];
  "nameField" -> "emailField" [label="spatial.below Distance: 50 px", color="blue", style="dashed"];
  
  // Group: parent
  "mainForm" [label="AXGroup Form"];
  "mainForm" -> "nameField" [label="parent", color="darkgreen", style="solid"];
}
```

## Export Formats in Detail

WeLabelDataRecorder supports multiple export formats to accommodate different use cases for the captured data.

### JSON Format

The JSON export is the most comprehensive format, containing full details about the recording session:

- **Structure**:
  - `metadata.json`: Session information (ID, timestamps, counts)
  - `interactions.json`: Array of all interactions with timestamps and details
  - `/screenshots`: Directory containing all captured images
  - `/elements`: Directory containing UI element hierarchies and relationship data
  
- **Sample metadata.json**:
  ```json
  {
    "id": "session-20230415-123456",
    "startTime": 1681558345.123,
    "endTime": 1681558400.456,
    "interactionCount": 42,
    "screenshotCount": 15,
    "uiElementCount": 23,
    "exportDate": 1681558410.789,
    "version": "1.0",
    "hierarchySupport": true
  }
  ```

- **Sample interactions.json** (simplified):
  ```json
  [
    {
      "type": "mouseClick",
      "timestamp": 1681558347.123,
      "x": 500,
      "y": 300,
      "button": 0,
      "clickCount": 1
    },
    {
      "type": "screenshot",
      "timestamp": 1681558348.234,
      "filename": "screenshot_001.png",
      "width": 1920,
      "height": 1080
    },
    {
      "type": "uiElement",
      "timestamp": 1681558350.345,
      "elementRole": "button",
      "elementTitle": "Submit",
      "x": 650,
      "y": 400,
      "elementHierarchyFile": "element_15.json",
      "elementRelationshipsFile": "element_15_relationships.json",
      "action": "click"
    }
  ]
  ```

### COCO Format

The COCO (Common Objects in Context) format is widely used in computer vision and object detection:

- **Structure**:
  - `instances.json`: COCO-format annotation file
  - `/images`: Directory containing numbered screenshots
  
- **Sample instances.json** (simplified):
  ```json
  {
    "info": {
      "version": "1.0",
      "description": "WeLabelDataRecorder Session Export",
      "contributor": "WeLabelDataRecorder",
      "date_created": "2023-04-15T12:40:10Z"
    },
    "images": [
      {
        "id": 0,
        "width": 1920,
        "height": 1080,
        "file_name": "000000.png",
        "license": 0,
        "date_captured": "2023-04-15T12:34:08Z"
      }
    ],
    "annotations": [
      {
        "id": 0,
        "image_id": 0,
        "category_id": 1,
        "bbox": [600, 380, 100, 40],
        "area": 4000,
        "iscrowd": 0,
        "attributes": {
          "role": "button",
          "title": "Submit",
          "enabled": true,
          "has_focus": true
        }
      }
    ],
    "categories": [
      {
        "id": 1,
        "name": "button",
        "supercategory": "ui_element"
      },
      {
        "id": 2,
        "name": "checkbox",
        "supercategory": "ui_element"
      }
    ]
  }
  ```

### YOLO Format

The YOLO (You Only Look Once) format is optimized for real-time object detection:

- **Structure**:
  - `classes.txt`: List of class names for UI elements
  - `/images`: Directory containing numbered screenshots
  - `/labels`: Directory containing annotation files for each image
  
- **Sample classes.txt**:
  ```
  button
  checkbox
  text_field
  menu
  menu_item
  window
  scroll_bar
  other
  ```
  
- **Sample label file (000000.txt)**:
  ```
  0 0.338542 0.37037 0.052083 0.037037
  2 0.234375 0.259259 0.104167 0.037037
  ```

  Each line contains: `class_id center_x center_y width height`
  where coordinates are normalized to [0,1] range.

## Test Export Mode

For quick testing and demonstration, WeLabelDataRecorder includes a test export mode:

```bash
./WeLabelDataRecorder.app/Contents/MacOS/WeLabelDataRecorder --test-export /path/to/export
```

This mode:
1. Creates a synthetic recording session with sample data
   - Mouse clicks at predefined positions
   - A test screenshot
   - UI element interactions with relationship data
2. Exports this session in all supported formats
3. Opens the export directory for inspection

A convenience script `run_test_export.sh` is provided:
```bash
#!/bin/bash
EXPORT_DIR="$(pwd)/test_export_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EXPORT_DIR"
./WeLabelDataRecorder.app/Contents/MacOS/WeLabelDataRecorder --test-export "$EXPORT_DIR"
open "$EXPORT_DIR"
```

## UI Relationship Visualization

WeLabelDataRecorder includes a powerful visualization feature for UI element relationships using the DOT graph description language. This feature allows developers and researchers to:

1. **Visualize UI Relationships**: Generate graphical representations of how UI elements relate to each other
2. **Analyze Interface Structure**: Understand hierarchical, spatial, and functional relationships
3. **Export for Documentation**: Create visual documentation of UI architecture

### Generating Relationship Graphs

The application automatically generates `.dot` files that can be viewed with GraphViz or similar tools:

```
digraph UIElementRelationships {
  // UI element relationship graph
  node [shape=box style=filled];

  // Central element
  "nameField" [label="AXTextField", fillcolor="lightblue"];

  // Related elements
  // Group: parent
  "mainForm" [label="AXGroup Form"];
  "mainForm" -> "nameField" [label="parent", color="darkgreen", style="solid", weight=9, dir="back"];

  // Group: spatial
  "emailField" [label="AXTextField"];
  "nameField" -> "emailField" [label="spatial.below Distance: 50 px", color="blue", style="dashed", weight=8, dir="both"];
  "nameLabel" [label="AXStaticText Name"];
  "nameField" -> "nameLabel" [label="spatial.leftOf Distance: 160 px", color="blue", style="dashed", weight=4, dir="both"];
}
```

### Visualization Color Coding

The relationship graphs use a consistent color scheme to indicate relationship types:
- **Green**: Hierarchical relationships (parent/child)
- **Blue**: Spatial relationships (above, below, left, right)
- **Orange**: Functional relationships
- **Purple**: Logical relationships

### Using the Visualization

To generate and view relationship visualizations:

1. Export a recording session with the "Include Visualizations" option enabled
2. Open the resulting `.dot` files with GraphViz:
   ```
   dot -Tpng ui_relationships.dot -o ui_relationships.png
   ```
3. Analyze the generated image to understand UI element relationships

This feature is especially valuable for:
- Accessibility testing and improvements
- UI automation development
- Interface design analysis
- Training machine learning models for UI understanding

## Developer Tools and Resources

The project includes several developer tools to help with testing, debugging, and extending the application:

### Developer Scripts

1. **build_app.sh**
   - Builds the application with proper entitlements and permissions
   - Creates a correctly structured app bundle
   - Ensures consistent bundle identity

2. **request_all_permissions.sh**
   - Interactive script for setting up all required permissions
   - Opens relevant system preference panels
   - Provides guidance for permission configuration

3. **check_permissions_status.swift**
   - Diagnostic tool for verifying permission setup
   - Checks Info.plist and entitlements files
   - Verifies application signing

4. **run_test_export.sh**
   - Creates and exports a sample recording session
   - Demonstrates the export formats
   - Useful for testing without recording actual sessions

### Debug Mode

Launch the application from Terminal to see debug output:

```bash
/path/to/WeLabelDataRecorder.app/Contents/MacOS/WeLabelDataRecorder
```

This will show console output with:
- UI initialization steps
- Permission status
- Recording events
- Export operations

### UI Component Architecture

The MainViewController implements several protocols:
- **RecordingManagerDelegate**: For handling recording events
- **NSTableViewDelegate**: For managing session list interactions
- **NSTableViewDataSource**: For providing session data to the table

Key UI components include:
- **SessionsTableView**: Displays recorded sessions with thumbnails and metadata
- **PermissionStatusView**: Shows visual indicators for permission status
- **RecordButton/ExportButton**: Primary action controls with visual feedback

## Support and Development

For issues, questions, or feature requests:

- Check the GitHub repository Issues section
- Contact the development team at support@welabeldatarecorder.example.com

## Contributing

We welcome contributions to the WeLabelDataRecorder project:

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Write tests for your implementation
5. Submit a pull request

Please follow the code style guidelines provided in the repository.