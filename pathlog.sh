#!/bin/bash

# Create detailed log and file audit for a specified path
# Usage: $0 [sudo] [SCAN_PATH] [--logto /custom/path/or/filename]

# Default hash algorithm
HASH_ALGORITHM="md5sum"  # Change to 'sha256sum' for SHA-256

# Function to log error messages
log_error() {
  echo "Error: $1"
  exit 1
}

# Function to calculate hash for a file
calculate_hash() {
  local file=$1
  $HASH_ALGORITHM "$file" 2>/dev/null | awk '{print $1}'
}

# Function to parse arguments and set options
parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --logto)
        shift
        CUSTOM_PATH_LOG="$1"
        if [[ -z "$CUSTOM_PATH_LOG" ]]; then
          log_error "Missing value for --logto flag."
        fi
        ;;
      *)
        if [[ -z "$SCAN_PATH" ]]; then
          SCAN_PATH="$1"
        else
          log_error "Unexpected argument: $1"
        fi
        ;;
    esac
    shift
  done
}

# Initialize variables
SCAN_PATH=""
CUSTOM_PATH_LOG=""
parse_args "$@"

# Set default scan path if not provided
SCAN_PATH="${SCAN_PATH:-/}"

# Check if the path exists and is a directory
[ -d "$SCAN_PATH" ] || log_error "Path '$SCAN_PATH' does not exist or is not a directory."

# Determine the user's home directory
if [ -n "$SUDO_USER" ]; then
  USER_HOME=$(eval echo "~$SUDO_USER")
else
  USER_HOME="$HOME"
fi

# Prepare the default log directory and filename
LOG_DIR="$USER_HOME/szmelc/logs/pathlog"
mkdir -p "$LOG_DIR" || log_error "Failed to create log directory '$LOG_DIR'."

DATETIME=$(date '+%Y-%m-%d_%H-%M-%S')
SANITIZED_PATH=$(echo "$SCAN_PATH" | sed 's/[\/:]/_/g')
OUTPUT_FILE="$LOG_DIR/${SANITIZED_PATH}-${DATETIME}.txt"

# Create or overwrite the output file
echo "Creating log file at $OUTPUT_FILE..."
: > "$OUTPUT_FILE"

# Add metadata to the log
echo "# Pathlog $DATETIME" >> "$OUTPUT_FILE"
echo "# Scanned Path: $SCAN_PATH" >> "$OUTPUT_FILE"
echo "# Hash Algorithm: $HASH_ALGORITHM" >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# Append tree output to the log if available
if command -v tree &>/dev/null; then
  echo "# Directory structure:" >> "$OUTPUT_FILE"
  tree "$SCAN_PATH" >> "$OUTPUT_FILE" 2>/dev/null
else
  echo "Warning: 'tree' command not found. Skipping directory structure." >> "$OUTPUT_FILE"
fi

echo >> "$OUTPUT_FILE"

# Process files recursively and log path/hash
echo "Processing files in '$SCAN_PATH'..."
find "$SCAN_PATH" -type f -print | while read -r FILE; do
  HASH=$(calculate_hash "$FILE")
  if [ -n "$HASH" ]; then
    echo "$FILE | $HASH" >> "$OUTPUT_FILE"
  else
    echo "Failed to hash: $FILE" >> "$OUTPUT_FILE"
  fi
done

# Handle custom log path if specified
if [ -n "$CUSTOM_PATH_LOG" ]; then
  if [ -d "$CUSTOM_PATH_LOG" ]; then
    CUSTOM_PATH_LOG="${CUSTOM_PATH_LOG%/}/${SANITIZED_PATH}-${DATETIME}.txt"
  fi

  echo "Moving log file to custom location: $CUSTOM_PATH_LOG..."
  cp "$OUTPUT_FILE" "$CUSTOM_PATH_LOG" || log_error "Failed to move log file to '$CUSTOM_PATH_LOG'."
  OUTPUT_FILE="$CUSTOM_PATH_LOG"
fi

echo "Log saved to $OUTPUT_FILE"
