# Changelog

All notable changes to the WeLabelDataRecorder project will be documented in this file.

## [1.1.0] - 2025-04-22

### Fixed
- Fixed session export functionality when attempting to export recordings
- Resolved serialization issues with AppKit/CoreGraphics types (NSPoint, CGRect)
- Added robust session storage with both disk and memory backups
- Improved error handling and debug logging throughout the application

### Added
- Added build script (`build_app.sh`) for easier application bundling
- Implemented direct session reference in MainViewController for reliable export
- Added helper structures for proper Codable support (CodablePoint, CodableRect)
- Added comprehensive error logging during encoding/decoding operations

### Changed
- Refactored UserInteraction models to support proper serialization
- Enhanced export process with multiple fallback mechanisms
- Improved MainViewController's export logic to check multiple session sources

## [1.0.0] - 2025-04-15

### Added
- Initial release of WeLabelDataRecorder
- Basic screen recording functionality
- Mouse and keyboard event capture
- Screenshot capture at intervals and on interaction
- Simple export capabilities
- Permission handling for screen recording and accessibility 