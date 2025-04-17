#!/bin/bash

# Script to remove all Gemfile.lock files from a directory and its subdirectories
# Usage: ./remove_gemfile_locks.sh [directory]

# Set default directory to current directory if not provided
TARGET_DIR="${1:-.}"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' does not exist"
  exit 1
fi

# Find all Gemfile.lock files in the target directory and subdirectories
FOUND_FILES=$(find "$TARGET_DIR" -name "Gemfile.lock" -type f)

# Count the number of files found
NUM_FILES=$(echo "$FOUND_FILES" | grep -c "Gemfile.lock" || echo 0)

# If no files found, exit
if [ "$NUM_FILES" -eq 0 ]; then
  echo "No Gemfile.lock files found in '$TARGET_DIR'"
  exit 0
fi

# Display the files that will be removed
echo "Found $NUM_FILES Gemfile.lock files to remove:"
echo "$FOUND_FILES" | sed 's/^/- /'

# Ask for confirmation before proceeding
read -p "Do you want to proceed with removal? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Operation cancelled"
  exit 0
fi

# Ask if backup is desired
read -p "Would you like to create a backup of these files? (y/n): " BACKUP_CONFIRM

if [[ "$BACKUP_CONFIRM" =~ ^[Yy]$ ]]; then
  # Default backup location
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  DEFAULT_BACKUP="gemfile_locks_backup_$TIMESTAMP"
  
  # Ask for backup location
  read -p "Enter backup directory path (default: $DEFAULT_BACKUP): " BACKUP_DIR
  BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_BACKUP}"
  
  # Create backup directory
  mkdir -p "$BACKUP_DIR"
  echo "Backing up files to $BACKUP_DIR..."
  
  # Backup each file
  while IFS= read -r file; do
    # Create the destination directory structure in the backup
    rel_path=$(realpath --relative-to="$TARGET_DIR" "$(dirname "$file")")
    mkdir -p "$BACKUP_DIR/$rel_path"
    
    # Copy the file to the backup
    cp "$file" "$BACKUP_DIR/$rel_path/"
  done <<< "$FOUND_FILES"
  
  echo "Backup completed to: $BACKUP_DIR"
fi

# Remove each file
echo "Removing Gemfile.lock files..."
while IFS= read -r file; do
  rm "$file"
  echo "Removed: $file"
done <<< "$FOUND_FILES"

echo "Operation completed successfully. Removed $NUM_FILES Gemfile.lock files."
