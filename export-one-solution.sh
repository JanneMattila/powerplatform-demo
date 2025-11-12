#!/bin/bash
set -e

# Script to export a Power Platform solution
# Usage: ./export-one-solution.sh <solution_group> <app_name> <environment_url> <client_id> <client_secret> <tenant_id>

SOLUTION_GROUP=$1
APP_NAME=$2
ENVIRONMENT_URL=$3
CLIENT_ID=$4
CLIENT_SECRET=$5
TENANT_ID=$6

if [ -z "$SOLUTION_GROUP" ] || [ -z "$APP_NAME" ] || [ -z "$ENVIRONMENT_URL" ] || [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$TENANT_ID" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <solution_group> <app_name> <environment_url> <client_id> <client_secret> <tenant_id>"
  exit 1
fi

echo "=========================================="
echo "Exporting Solution: $SOLUTION_GROUP -> $APP_NAME"
echo "=========================================="

# Authenticate with Power Platform
echo "Authenticating with Power Platform..."
pac auth create \
  --environment "$ENVIRONMENT_URL" \
  --applicationId "$CLIENT_ID" \
  --clientSecret "$CLIENT_SECRET" \
  --tenant "$TENANT_ID"

# Get current solution version and auto-increment
echo "Getting current solution version..."
SOLUTION_LIST=$(pac solution list)

# Parse the table output to find the solution and extract version
# Table format: Unique Name | Friendly Name | Version | Managed
CURRENT_VERSION=$(echo "$SOLUTION_LIST" | grep "^$APP_NAME\s" | awk '{print $3}')

if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: Could not find solution '$APP_NAME'"
  exit 1
fi

echo "Current solution version: $CURRENT_VERSION"

# Parse version components (e.g., 1.0.0.5 -> 1 0 0 5)
IFS='.' read -r MAJOR MINOR BUILD REVISION <<< "$CURRENT_VERSION"

# Handle cases where version might be incomplete (e.g., "1.0" instead of "1.0.0.0")
MAJOR=${MAJOR:-1}
MINOR=${MINOR:-0}
BUILD=${BUILD:-0}
REVISION=${REVISION:-0}

# Increment revision number
NEW_REVISION=$((REVISION + 1))
NEW_VERSION="$MAJOR.$MINOR.$BUILD.$NEW_REVISION"

echo "New solution version: $NEW_VERSION"

# Update solution version online
echo "Updating solution version to $NEW_VERSION..."
pac solution online-version --solution-name "$APP_NAME" --solution-version "$NEW_VERSION"

# Create target directory if it doesn't exist
TARGET_DIR="./SolutionGroups/$SOLUTION_GROUP"
mkdir -p "$TARGET_DIR"

# Export unmanaged solution
echo "Exporting unmanaged solution..."
pac solution export \
  --path "$TARGET_DIR/${APP_NAME}_unmanaged.zip" \
  --name "$APP_NAME" \
  --managed false \
  --overwrite

echo "Unmanaged solution exported successfully"

# Export managed solution
echo "Exporting managed solution..."
pac solution export \
  --path "$TARGET_DIR/${APP_NAME}.zip" \
  --name "$APP_NAME" \
  --managed true \
  --overwrite

echo "Managed solution exported successfully"

# Create export metadata file
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
METADATA_FILE="$TARGET_DIR/${APP_NAME}.md"

echo "Creating metadata file: $METADATA_FILE"

cat > "$METADATA_FILE" << EOF
# Export Metadata

**Solution:** $APP_NAME

**Solution Group:** $SOLUTION_GROUP

**Version:** $NEW_VERSION

**Exported:** $TIMESTAMP

**Exported by:** ${USER:-unknown}

**Branch:** ${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")}
EOF

echo "Metadata file created successfully"

echo "=========================================="
echo "Export completed successfully!"
echo "Version: $NEW_VERSION"
echo "Location: $TARGET_DIR"
echo "=========================================="
