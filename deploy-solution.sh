#!/bin/bash
set -e

# Script to deploy a Power Platform solution
# Usage: ./deploy-solution.sh <solution_group> <app_name> <environment>

SOLUTION_GROUP=$1
APP_NAME=$2
ENVIRONMENT=$3

if [ -z "$SOLUTION_GROUP" ] || [ -z "$APP_NAME" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <solution_group> <app_name> <environment>"
  exit 1
fi

echo "=========================================="
echo "Deploying Solution: $SOLUTION_GROUP -> $APP_NAME to $ENVIRONMENT"
echo "=========================================="

# Define paths
SOLUTION_DIR="./SolutionGroups/$SOLUTION_GROUP"
SOLUTION_FILE="$SOLUTION_DIR/${APP_NAME}.zip"
SOURCE_DIR="$SOLUTION_DIR/${APP_NAME}_unmanaged"
DEPLOYMENT_SETTINGS_FILE="$SOLUTION_DIR/${APP_NAME}.${ENVIRONMENT}.json"

if [ "$ENVIRONMENT" = "Development" ]; then
  #
  # Development: Pack from source files and import as unmanaged
  #
  echo "Development deployment: using source files"

  # Check if source folder exists
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source folder not found: $SOURCE_DIR"
    echo "Please run the Export workflow first to generate the source folder."
    exit 1
  fi

  echo "Source folder: $SOURCE_DIR"

  # Pack source files into a temporary zip
  TEMP_ZIP=$(mktemp "/tmp/${APP_NAME}_packed_XXXXXX.zip")
  echo "Packing source files to: $TEMP_ZIP"
  pac solution pack \
    --zipfile "$TEMP_ZIP" \
    --folder "$SOURCE_DIR" \
    --packagetype Unmanaged

  # Import as unmanaged solution
  echo "Importing unmanaged solution..."
  pac solution import \
    --path "$TEMP_ZIP" \
    --force-overwrite \
    --publish-changes

  # Clean up temp zip
  rm -f "$TEMP_ZIP"
  echo "Solution import initiated successfully"

else
  #
  # QA/Stage/Production: Verify integrity then import managed zip
  #
  echo "Non-development deployment: using managed zip with integrity verification"

  # Verify that source folder matches the unmanaged zip
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  chmod +x "$SCRIPT_DIR/verify-solution-integrity.sh"
  "$SCRIPT_DIR/verify-solution-integrity.sh" "$SOLUTION_GROUP" "$APP_NAME"

  # Check if managed solution file exists
  if [ ! -f "$SOLUTION_FILE" ]; then
    echo "Error: Solution file not found: $SOLUTION_FILE"
    exit 1
  fi

  echo "Solution file: $SOLUTION_FILE"

  # Detect deployment settings file
  if [ -f "$DEPLOYMENT_SETTINGS_FILE" ]; then
    echo "Found deployment settings file: $DEPLOYMENT_SETTINGS_FILE"
    USE_DEPLOYMENT_SETTINGS=true
  else
    echo "No deployment settings file found."
    USE_DEPLOYMENT_SETTINGS=false
  fi

  # Import managed solution
  echo "Importing managed solution..."
  if [ "$USE_DEPLOYMENT_SETTINGS" = true ]; then
    pac solution import \
      --path "$SOLUTION_FILE" \
      --settings-file "$DEPLOYMENT_SETTINGS_FILE" \
      --publish-changes
  else
    pac solution import \
      --path "$SOLUTION_FILE" \
      --publish-changes
  fi

  echo "Solution import initiated successfully"
fi

echo "=========================================="
echo "Deployment completed successfully!"
echo "Solution: $APP_NAME"
echo "Environment: $ENVIRONMENT"
echo "=========================================="
