# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-04-22

### Added
- Enhanced user interface with session list and thumbnails
- Permission status indicators in the main window
- Disk space usage indicator
- Visual feedback during recording (animation)
- Table view for session management with metrics
- Improved buttons with icon support
- Helper script for permission requests (`request_all_permissions.sh`)
- Consistent application identity across builds

### Changed
- Improved application build process for better permission handling
- Enhanced permission management system
- Removed unnecessary camera and microphone permission requests
- Updated documentation with UI and permission details
- Restructured main window layout for better usability

### Fixed
- Permission reset issues when rebuilding the application
- UI elements positioning and constraints
- Visual feedback when recording starts and stops
- Session list refresh after recording completion

## [1.1.0] - 2025-03-15

### Added
- UI Element Relationship Analyzer
- Support for hierarchical, spatial, functional, and logical relationships
- Relationship visualization using DOT format
- Export of relationship data in JSON, COCO, and YOLO formats
- Relevance scoring for relationship prioritization

### Changed
- Improved UI element detection during recording
- Enhanced export formats with relationship data
- Updated documentation with relationship analysis details

### Fixed
- Screen recording permission handling
- Session data serialization for AppKit/CoreGraphics types

## [1.0.0] - 2025-02-01

### Added
- Initial release of WeLabelDataRecorder
- Screen recording and screenshot capture
- Mouse and keyboard event tracking
- UI element detection via Accessibility API
- Export in JSON, COCO, and YOLO formats
- Basic application UI
- Test export mode

### Changed
- N/A (initial release)

### Fixed
- N/A (initial release)

## Version 1.1.0 (Current)

### New Features
- Accessibility integration for UI element detection
- Advanced UI element metadata collection
- Basic relationship detection between UI elements
- Multiple export formats support (JSON, COCO, YOLO)
- Improved session management with auto-save capability

### Bug Fixes
- Fixed permissions issues for screen recording and accessibility
- Updated Info.plist with proper usage descriptions
- Optimized entitlements configuration for macOS security requirements
- Fixed serialization issues with AppKit/CoreGraphics types
- Improved application bundling process

### Technical Improvements
- Enhanced logging system for better debugging
- Optimized screenshot capture process
- Implemented permissions checking utility
- Improved build system with proper Info.plist and entitlements handling

## Version 1.0.0

### Features
- Basic screen recording functionality
- Mouse movement and click tracking
- Keyboard input recording
- Screenshot capture at regular intervals
- Manual session export to JSON
- Simple session playback

## Planned for Version 1.2.0

### In Progress
- Complete UI Element Relationship Analyzer
  - Enhanced hierarchy detection
  - Relationship tracking between UI elements
  - Visualization tools for element hierarchies

- Finalize COCO and YOLO export formats
  - Complete UI element category mapping
  - Generate valid annotation formats for ML training
  - Include metadata for complex relationships

### Upcoming
- Performance & Stability Improvements
  - Optimize memory usage during long recording sessions
  - Implement robust auto-save functionality
  - Reduce CPU load during intensive recording
  
- UX Enhancements
  - Redesigned session management interface
  - Recording filtering capabilities
  - Preview functionality for recorded sessions

## Future Roadmap (v2.0.0)

- Web Interface Integration
  - Simple web viewer for recorded sessions
  - Annotation capabilities in web interface
  - Cloud storage integration

- Machine Learning Integration
  - Basic model training capabilities
  - Feedback loop for improving annotations
  - Pre-trained models for common UI elements

- Multi-device Support
  - iOS companion app for mobile testing
  - Cross-platform session viewing
  - Synchronized multi-device recording 