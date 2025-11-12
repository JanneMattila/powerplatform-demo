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
SOLUTION_FILE="./SolutionGroups/$SOLUTION_GROUP/${APP_NAME}.zip"
DEPLOYMENT_SETTINGS_FILE="./SolutionGroups/$SOLUTION_GROUP/${APP_NAME}.${ENVIRONMENT}.json"

# Check if solution file exists
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

echo "=========================================="
echo "Deployment completed successfully!"
echo "Solution: $APP_NAME"
echo "Environment: $ENVIRONMENT"
echo "=========================================="
