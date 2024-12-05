#!/bin/bash

# ULTRACOMPARE SCRIPT FOR EXTRACTING DIFFERING FILES
# COMPARE 'ORIGINAL' AND 'MODIFIED'
# CREATE 'DIFF' WITH ONLY 'MODIFIED' FILES, THAT DON'T MATCH 'ORIGINAL'

# Prompt user for original and modified paths
read -p "Enter the path to the original directory: " ORIGINAL_PATH
read -p "Enter the path to the modified directory: " MODIFIED_PATH

# Verify paths exist
if [ ! -d "$ORIGINAL_PATH" ]; then
    echo "Error: Original directory '$ORIGINAL_PATH' does not exist."
    exit 1
fi

if [ ! -d "$MODIFIED_PATH" ]; then
    echo "Error: Modified directory '$MODIFIED_PATH' does not exist."
    exit 1
fi

# Log files
ORIGINAL_LOG="original-log.txt"
MODIFIED_LOG="modified-log.txt"
DIFF_LOG="diff-log.txt"

# Output directories
DIFF_DIR="diff"
OLD_DIR="old"

# Create a timestamped folder for cleanup
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
ARCHIVE_DIR="$OLD_DIR/$TIMESTAMP"

# Ensure the old/ directory exists
mkdir -p "$ARCHIVE_DIR"

# Function to generate log with relative paths and SHA-256 hashes
generate_log() {
    local base_path="$1"
    local log_file="$2"
    find "$base_path" -type f | while read -r file; do
        # Get relative path and hash
        relative_path="${file#$base_path/}" # Remove base path prefix
        hash=$(sha256sum "$file" | awk '{print $1}')
        # Write to log file
        echo "$relative_path | $hash" >> "$log_file"
    done
}

# Generate logs for original and modified paths
echo "Generating log for original path..."
> "$ORIGINAL_LOG" # Clear previous log
generate_log "$ORIGINAL_PATH" "$ORIGINAL_LOG"

echo "Generating log for modified path..."
> "$MODIFIED_LOG" # Clear previous log
generate_log "$MODIFIED_PATH" "$MODIFIED_LOG"

# Copy the entire modified directory structure to the diff directory
echo "Creating diff directory from modified path..."
rm -rf "$DIFF_DIR"
cp -a "$MODIFIED_PATH" "$DIFF_DIR"

# Create diff-log.txt from modified-log.txt
cp "$MODIFIED_LOG" "$DIFF_LOG"

# Final step: Remove all matching lines from diff-log.txt
echo "Finalizing diff-log.txt by removing matches from original-log.txt..."
while IFS= read -r original_line; do
    # Extract relative path and hash from the original log
    original_relative_path=$(echo "$original_line" | cut -d'|' -f1 | xargs)
    original_hash=$(echo "$original_line" | cut -d'|' -f2 | xargs)

    # Create the matching pattern and remove it from diff-log.txt
    grep_pattern="^${original_relative_path//./\\.} | $original_hash$"
    sed -i "/$grep_pattern/d" "$DIFF_LOG"
done <"$ORIGINAL_LOG"

# Remove matching files from the diff directory
echo "Removing matching files from diff directory..."
while IFS= read -r original_line; do
    original_relative_path=$(echo "$original_line" | cut -d'|' -f1 | xargs)
    target_file="$DIFF_DIR/$original_relative_path"
    if [ -f "$target_file" ]; then
        rm -f "$target_file"
    fi
done <"$ORIGINAL_LOG"

# Clean up empty directories in the diff directory
find "$DIFF_DIR" -type d -empty -delete

# Move logs and diff directory to the archive
echo "Archiving logs and diff directory..."
mv "$ORIGINAL_LOG" "$ARCHIVE_DIR/"
mv "$MODIFIED_LOG" "$ARCHIVE_DIR/"
mv "$DIFF_LOG" "$ARCHIVE_DIR/"
mv "$DIFF_DIR" "$ARCHIVE_DIR/"

echo "Process complete. Logs and diff directory archived in $ARCHIVE_DIR."
