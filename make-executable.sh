#!/bin/zsh

# Script to make all shell scripts in the repository executable
# Usage: ./make-scripts-executable.sh [--parent-dir]

echo "🔧 Making all shell scripts executable..."

# Check if we should look in the parent directory
PARENT_DIR=false
if [[ "$1" == "--parent-dir" ]]; then
  PARENT_DIR=true
  echo "🔍 Looking for scripts in parent directory as well"
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make all .sh files in the current directory executable
echo "📂 Making scripts in $SCRIPT_DIR executable..."
find "$SCRIPT_DIR" -name "*.sh" -type f | while read -r script; do
  echo "   🔑 Setting executable permission on: $(basename "$script")"
  chmod +x "$script"
done

# Check if we should also process the parent directory
if [[ "$PARENT_DIR" == true ]]; then
  PARENT_DIR="$(dirname "$SCRIPT_DIR")"
  echo "📂 Making scripts in $PARENT_DIR executable..."
  find "$PARENT_DIR" -maxdepth 1 -name "*.sh" -type f | while read -r script; do
    # Skip scripts in the utilities directory (we already did those)
    if [[ "$script" != "$SCRIPT_DIR"/* ]]; then
      echo "   🔑 Setting executable permission on: $(basename "$script")"
      chmod +x "$script"
    fi
  done
fi

# Count how many files were made executable
SCRIPT_COUNT=$(find "$SCRIPT_DIR" -name "*.sh" -type f | wc -l | tr -d ' ')
if [[ "$PARENT_DIR" == true ]]; then
  PARENT_SCRIPT_COUNT=$(find "$PARENT_DIR" -maxdepth 1 -name "*.sh" -type f | grep -v "$SCRIPT_DIR" | wc -l | tr -d ' ')
  TOTAL_COUNT=$((SCRIPT_COUNT + PARENT_SCRIPT_COUNT))
  echo "✅ Made $TOTAL_COUNT scripts executable ($SCRIPT_COUNT in utilities directory, $PARENT_SCRIPT_COUNT in parent directory)"
else
  echo "✅ Made $SCRIPT_COUNT scripts executable"
fi

echo "✨ All done!"
