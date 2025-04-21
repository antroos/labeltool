# Changelog

All notable changes to the WeLabelDataRecorder project will be documented in this file.

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