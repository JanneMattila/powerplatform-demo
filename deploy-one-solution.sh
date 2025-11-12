#!/bin/bash
set -e

# Script to deploy a Power Platform solution
# Usage: ./deploy-one-solution.sh <solution_group> <app_name> <environment> <environment_url> <client_id> <client_secret> <tenant_id>

SOLUTION_GROUP=$1
APP_NAME=$2
ENVIRONMENT=$3
ENVIRONMENT_URL=$4
CLIENT_ID=$5
CLIENT_SECRET=$6
TENANT_ID=$7

if [ -z "$SOLUTION_GROUP" ] || [ -z "$APP_NAME" ] || [ -z "$ENVIRONMENT" ] || [ -z "$ENVIRONMENT_URL" ] || [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$TENANT_ID" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <solution_group> <app_name> <environment> <environment_url> <client_id> <client_secret> <tenant_id>"
  exit 1
fi

echo "=========================================="
echo "Deploying Solution: $SOLUTION_GROUP -> $APP_NAME to $ENVIRONMENT"
echo "=========================================="

# Authenticate with Power Platform
echo "Authenticating with Power Platform..."
pac auth create \
  --environment "$ENVIRONMENT_URL" \
  --applicationId "$CLIENT_ID" \
  --clientSecret "$CLIENT_SECRET" \
  --tenant "$TENANT_ID"

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

pac auth clear

echo "=========================================="
echo "Deployment completed successfully!"
echo "Solution: $APP_NAME"
echo "Environment: $ENVIRONMENT"
echo "=========================================="
