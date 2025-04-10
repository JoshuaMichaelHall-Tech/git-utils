#!/bin/zsh

# Check if directory is provided
if [[ $# -eq 0 ]]; then
  # Use current directory if no argument is passed
  TARGET_DIR="."
else
  TARGET_DIR="$1"
fi

# Find all .sh files and make them executable
find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Count how many files were modified
COUNT=$(find "$TARGET_DIR" -type f -name "*.sh" | wc -l)

# Display results
echo "Made $COUNT shell scripts executable in $TARGET_DIR and subdirectories."
