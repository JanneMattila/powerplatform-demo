#!/bin/bash
set -e

# Script to verify that the _unmanaged.zip matches the source folder.
# This ensures developers haven't edited source files without re-exporting the zip.
# Usage: ./verify-solution-integrity.sh <solution_group> <app_name>

SOLUTION_GROUP=$1
APP_NAME=$2

if [ -z "$SOLUTION_GROUP" ] || [ -z "$APP_NAME" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <solution_group> <app_name>"
  exit 1
fi

echo "=========================================="
echo "Verifying Solution Integrity: $SOLUTION_GROUP -> $APP_NAME"
echo "=========================================="

# Define paths
SOURCE_DIR="./SolutionGroups/$SOLUTION_GROUP/${APP_NAME}"
ZIP_FILE="./SolutionGroups/$SOLUTION_GROUP/${APP_NAME}_unmanaged.zip"

# Check if source folder exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source folder not found: $SOURCE_DIR"
  echo "The solution has not been exported with source unpacking."
  echo "Please run the Export workflow first to generate the source folder."
  exit 1
fi

# Check if zip file exists
if [ ! -f "$ZIP_FILE" ]; then
  echo "Error: Unmanaged zip file not found: $ZIP_FILE"
  echo "Please run the Export workflow first to generate the zip file."
  exit 1
fi

# Create temp directory for unpacking
TEMP_DIR=$(mktemp -d)
echo "Unpacking zip to temp directory: $TEMP_DIR"

# Unpack the zip file to temp directory
pac solution unpack \
  --zipfile "$ZIP_FILE" \
  --folder "$TEMP_DIR" \
  --allowDelete \
  --allowWrite \
  --clobber

echo "Comparing unpacked zip with source folder..."

# Compare the unpacked zip with the source folder
# Use diff -rq for a summary (file names only) to keep CI logs readable
DIFF_OUTPUT=$(diff -rq "$TEMP_DIR" "$SOURCE_DIR" 2>&1 || true)

# Clean up temp directory
rm -rf "$TEMP_DIR"

if [ -n "$DIFF_OUTPUT" ]; then
  echo ""
  echo "=========================================="
  echo "INTEGRITY CHECK FAILED"
  echo "=========================================="
  echo ""
  echo "The _unmanaged.zip does not match the source folder."
  echo "This means source files have been edited without re-exporting,"
  echo "or the zip was updated without unpacking."
  echo ""
  echo "Differences found:"
  echo "$DIFF_OUTPUT"
  echo ""
  echo "To resolve this:"
  echo "  1. Deploy your source changes to the Development environment first"
  echo "  2. Then run the Export workflow to re-export and sync the zip files"
  echo "  3. Commit the updated zip files and try again"
  echo ""
  echo "=========================================="
  exit 1
fi

echo ""
echo "=========================================="
echo "✓ Integrity check passed!"
echo "  Source folder and zip file are in sync."
echo "=========================================="
