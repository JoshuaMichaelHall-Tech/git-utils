#!/bin/zsh

# Script to pull updates from GitHub using patch-rebase strategy
# This approach preserves local changes while applying remote updates cleanly
# Useful when you have local changes and want to incorporate upstream changes
# Usage: ./patch-rebase-pull-from-github.sh [--create-patch] [--apply-only]

# Parse arguments
CREATE_PATCH=false
APPLY_ONLY=false

for arg in "$@"; do
  case $arg in
    --create-patch)
      CREATE_PATCH=true
      ;;
    --apply-only)
      APPLY_ONLY=true
      ;;
  esac
done

echo "🧩 Patch-Rebase Pull from GitHub 🧩"
echo "=================================="
echo ""

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get repository information
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
CURRENT_BRANCH=$(git branch --show-current)
REPO_ROOT=$(git rev-parse --show-toplevel)
PATCH_DIR="$REPO_ROOT/.git/patches"
PATCH_FILE="$PATCH_DIR/local_changes_$(date +%Y%m%d_%H%M%S).patch"

echo "📍 Repository: $REPO_NAME"
echo "📍 Current branch: $CURRENT_BRANCH"
echo ""

# Create patches directory if it doesn't exist
mkdir -p "$PATCH_DIR"

# Check if we have any local changes
if git diff --quiet && git diff --cached --quiet; then
  if [[ "$CREATE_PATCH" == true ]]; then
    echo "❌ No local changes to create a patch from."
    exit 1
  elif [[ "$APPLY_ONLY" == false ]]; then
    echo "ℹ️  No local changes detected. Performing a standard pull instead."
    git pull origin $CURRENT_BRANCH
    
    if [[ $? -eq 0 ]]; then
      echo "✅ Pull successful."
    else
      echo "❌ Pull failed. See error message above."
      exit 1
    fi
    
    echo "✨ All done!"
    exit 0
  fi
fi

# Handle the create-patch-only case
if [[ "$CREATE_PATCH" == true ]]; then
  echo "📄 Creating patch of local changes..."
  git diff > "$PATCH_FILE"
  
  if [[ $? -eq 0 && -s "$PATCH_FILE" ]]; then
    echo "✅ Patch file created: $PATCH_FILE"
  else
    echo "❌ Failed to create patch file or patch is empty."
    rm -f "$PATCH_FILE"
    exit 1
  fi
  
  echo "✨ Patch creation completed!"
  exit 0
fi

# Handle the apply-only case
if [[ "$APPLY_ONLY" == true ]]; then
  # List available patches
  PATCHES=($(ls -1t "$PATCH_DIR"/*.patch 2>/dev/null))
  
  if [[ ${#PATCHES[@]} -eq 0 ]]; then
    echo "❌ No patch files found in $PATCH_DIR"
    exit 1
  fi
  
  echo "📋 Available patches:"
  for i in {1..${#PATCHES[@]}}; do
    echo "$i: $(basename ${PATCHES[$i-1]})"
  done
  
  read "patch_index?Enter patch number to apply: "
  
  if ! [[ "$patch_index" =~ ^[0-9]+$ ]] || [[ $patch_index -lt 1 ]] || [[ $patch_index -gt ${#PATCHES[@]} ]]; then
    echo "❌ Invalid selection."
    exit 1
  fi
  
  SELECTED_PATCH=${PATCHES[$patch_index-1]}
  
  echo "🧩 Applying patch: $(basename $SELECTED_PATCH)"
  git apply "$SELECTED_PATCH"
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Patch applied successfully."
  else
    echo "❌ Failed to apply patch. There might be conflicts."
    exit 1
  fi
  
  echo "✨ Patch application completed!"
  exit 0
fi

# Normal patch-rebase-pull flow
echo "📄 Creating patch of local changes..."
git diff > "$PATCH_FILE"

if [[ $? -ne 0 || ! -s "$PATCH_FILE" ]]; then
  echo "❌ Failed to create patch file or patch is empty."
  rm -f "$PATCH_FILE"
  exit 1
fi

echo "✅ Local changes saved to patch file."

# Reset the working directory
echo "🔄 Resetting working directory..."
git reset --hard HEAD

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to reset working directory."
  echo "ℹ️  Your local changes are saved in: $PATCH_FILE"
  exit 1
fi

# Pull the latest changes
echo "⬇️  Pulling latest changes from GitHub..."
git pull origin $CURRENT_BRANCH

if [[ $? -ne 0 ]]; then
  echo "❌ Pull failed."
  echo "ℹ️  Your local changes are saved in: $PATCH_FILE"
  echo "    You can apply them later with: git apply $PATCH_FILE"
  exit 1
fi

echo "✅ Latest changes pulled successfully."

# Apply the patch
echo "🧩 Applying local changes on top of the updated codebase..."
git apply "$PATCH_FILE"

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to apply local changes. There might be conflicts."
  echo "ℹ️  Your local changes are saved in: $PATCH_FILE"
  echo "    You may need to apply them manually and resolve conflicts."
  exit 1
fi

echo "✅ Local changes applied successfully."

# Show status
echo "📊 Current status:"
git status -s

echo ""
echo "✨ Patch-rebase-pull completed successfully!"
echo "ℹ️  Your local changes were preserved in: $PATCH_FILE"
echo "    If you wish to commit these changes, use git add and git commit as usual."