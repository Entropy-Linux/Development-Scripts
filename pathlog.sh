#!/bin/bash

# Log entire tree and contents of a path recursively into a pathlog.txt log file.
# Log all files by `path/filename | sha256-hash`
# Specify path with `$0 /path` or proceed with `/` as default path if none specified.

# Set default scan path to /
SCAN_PATH="/"
EXCLUDE_PATHS=("/proc" "/sys" "/dev" "/run" "/tmp" "/var/tmp")
OUTPUT_FILE=~/pathlog.txt

# Check if the user provided a path
if [ -n "$1" ]; then
  SCAN_PATH=$1
fi

# Check if the path exists
if [ ! -d "$SCAN_PATH" ]; then
  echo "Error: Path '$SCAN_PATH' does not exist or is not a directory."
  exit 1
fi

# Create or overwrite the output file
echo "Creating log file at $OUTPUT_FILE..."
> "$OUTPUT_FILE"

# Add metadata to the log
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
echo "# Pathlog $DATETIME" >> "$OUTPUT_FILE"

# Append tree output to the log
echo "# Directory structure:" >> "$OUTPUT_FILE"
if command -v tree &> /dev/null; then
  tree "$SCAN_PATH" >> "$OUTPUT_FILE" 2>/dev/null
else
  echo "Warning: 'tree' command not found. Skipping directory structure." >> "$OUTPUT_FILE"
fi

echo >> "$OUTPUT_FILE"

# Generate a find exclude list
EXCLUDE_ARGS=""
for path in "${EXCLUDE_PATHS[@]}"; do
  EXCLUDE_ARGS="$EXCLUDE_ARGS -path $path -prune -o"
done

# Process files recursively
echo "Processing files in $SCAN_PATH (excluding ${EXCLUDE_PATHS[*]})..."
find "$SCAN_PATH" $EXCLUDE_ARGS -type f -print | while read -r FILE; do
  HASH=$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')
  if [ -n "$HASH" ]; then
    echo "$FILE | $HASH" >> "$OUTPUT_FILE"
  fi
done

echo "Log saved to $OUTPUT_FILE"
