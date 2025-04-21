#!/bin/bash

echo "Running WeLabelDataRecorder in test export mode..."

# Create a temporary directory for the test export
EXPORT_DIR="$(pwd)/test_export_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EXPORT_DIR"

echo "Export directory: $EXPORT_DIR"

# Run the app in test export mode
./WeLabelDataRecorder.app/Contents/MacOS/WeLabelDataRecorder --test-export "$EXPORT_DIR"

echo "Test export completed. Results are in: $EXPORT_DIR"
echo "Opening the export directory..."
open "$EXPORT_DIR" 