#!/bin/bash
# Usage: ./clone_docs.sh <repository_url>

# Check if repository URL is provided
if [ -z "$1" ]; then
  echo "Error: No repository URL provided."
  echo "Usage: $0 <repository_url>"
  exit 1
fi

REPO_URL="$1"
TEMP_DIR="temp"
DOCS_DIR="docs"

# Extract repository name from URL
REPO_NAME=$(basename -s .git "$REPO_URL")

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Clone the repository with sparse checkout
git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$REPO_NAME" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Error: Failed to clone repository '$REPO_URL'."
  cd ..
  rm -rf "$TEMP_DIR"
  exit 1
fi

cd "$REPO_NAME" || exit 1

# Initialize sparse checkout and set to include 'docs' directory and 'README.md'
git sparse-checkout init --cone
git sparse-checkout set README.md docs

# Go back to the root directory
cd ../../

# Set destination directory
DEST_DIR="$DOCS_DIR/$REPO_NAME"
mkdir -p "$DEST_DIR"

# Copy the README.md file if it exists
if [ -f "$TEMP_DIR/$REPO_NAME/README.md" ]; then
  cp "$TEMP_DIR/$REPO_NAME/README.md" "$DEST_DIR/"
  echo "Copied 'README.md' from '$REPO_URL' to '$DEST_DIR/'."
else
  echo "Warning: 'README.md' not found in repository '$REPO_URL'."
fi

# Copy the 'docs' content if it exists
if [ -d "$TEMP_DIR/$REPO_NAME/docs" ]; then
  cp -r "$TEMP_DIR/$REPO_NAME/docs/"* "$DEST_DIR/"
  echo "Copied 'docs' folder from '$REPO_URL' to '$DEST_DIR/'."
else
  echo "Warning: 'docs' folder not found in repository '$REPO_URL'."
fi

# Clean up temporary directory
rm -rf "$TEMP_DIR/$REPO_NAME"

echo "Completed processing repository '$REPO_URL'."
