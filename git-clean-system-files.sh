#!/bin/zsh

# Script to remove common system files from a git repository,
# update .gitignore to ignore them in the future, and commit changes

echo "🧹 Starting system files cleanup script..."

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

echo "📍 Working in git repository root: $ROOT_DIR"

# Define common system files to be removed
SYSTEM_FILES=(
  ".DS_Store"
  ".DS_Store?"
  "._*"
  ".Spotlight-V100"
  ".Trashes"
  "ehthumbs.db"
  "Thumbs.db"
  "desktop.ini"
  ".directory"
  "*~"
  ".*.swp"
  ".*.swo"
)

# Find and delete system files
echo "🔍 Finding and removing system files..."
for PATTERN in "${SYSTEM_FILES[@]}"; do
  # Use find with appropriate pattern
  if [[ "$PATTERN" == *"*"* ]]; then
    # Pattern has wildcards, handle differently
    find . -name "$PATTERN" -type f -delete 2>/dev/null
  else
    # Standard file pattern
    find . -name "$PATTERN" -type f -delete
  fi
done
echo "✅ All system files have been removed."

# Check if .gitignore exists, create it if it doesn't
if [ ! -f .gitignore ]; then
  echo "📝 Creating .gitignore file..."
  touch .gitignore
  echo "✅ .gitignore created."
else
  echo "📝 .gitignore file already exists."
fi

# Add all system files patterns to .gitignore if not already there
echo "📝 Updating .gitignore with system file patterns..."

# Check if we already have a system files section
if ! grep -q "# System Files" .gitignore; then
  # Ensure there's a newline at the end of the file
  if [ -s .gitignore ] && [ "$(tail -c 1 .gitignore)" != "" ]; then
    echo "" >> .gitignore
  fi
  
  # Add system files section
  echo "# System Files" >> .gitignore
  for PATTERN in "${SYSTEM_FILES[@]}"; do
    echo "$PATTERN" >> .gitignore
  done
  
  # Add OS-specific sections
  echo "" >> .gitignore
  echo "# Linux" >> .gitignore
  echo ".directory" >> .gitignore
  echo "*~" >> .gitignore
  
  echo "" >> .gitignore
  echo "# Windows" >> .gitignore
  echo "Thumbs.db" >> .gitignore
  echo "ehthumbs.db" >> .gitignore
  echo "desktop.ini" >> .gitignore
  
  echo "" >> .gitignore
  echo "# macOS" >> .gitignore
  echo ".DS_Store" >> .gitignore
  echo ".DS_Store?" >> .gitignore
  echo "._*" >> .gitignore
  echo ".Spotlight-V100" >> .gitignore
  echo ".Trashes" >> .gitignore
  
  echo "" >> .gitignore
  echo "# Vim" >> .gitignore
  echo ".*.swp" >> .gitignore
  echo ".*.swo" >> .gitignore
  
  echo "✅ System files patterns added to .gitignore."
else
  echo "ℹ️ System files section already exists in .gitignore."
fi

# Add changes to git
echo "🔄 Adding changes to git..."
git add .gitignore
git add -u  # Add all tracked files (to register deletions)

# Commit changes
echo "💾 Committing changes..."
git commit -m "Remove system files and update .gitignore to exclude them"

# Push changes
echo "🚀 Pushing changes to remote repository..."
git push

echo "✨ All done! Repository cleaned and changes pushed."
