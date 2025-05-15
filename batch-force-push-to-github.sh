#!/bin/zsh

# Script to force push multiple repositories to GitHub
# Helps manage batch updates across multiple related repositories
# Usage: ./batch-force-push-to-github.sh [path/to/root/directory] [--no-backup]

# Set defaults
ROOT_DIR=${1:-$(pwd)}
BACKUP_FLAG=""
AUTO_CONFIRM=false

# Process arguments
for arg in "$@"; do
  if [[ "$arg" == "--no-backup" ]]; then
    BACKUP_FLAG="--skip-backup"
  elif [[ "$arg" == "--yes" || "$arg" == "-y" ]]; then
    AUTO_CONFIRM=true
  fi
done

echo "🚀 Batch Force Push to GitHub 🚀"
echo "=================================="
echo ""
echo "This script will force push all git repositories in:"
echo "📁 $ROOT_DIR"
echo ""

# Confirmation
if [[ "$AUTO_CONFIRM" != true ]]; then
  echo "⚠️  WARNING: This will force push ALL repositories found in the directory."
  echo "    Force pushing overwrites remote history and cannot be undone."
  echo -n "Are you absolutely sure you want to proceed? (yes/y/no/n): "
  read confirm

  if [[ ! "$confirm" =~ ^(yes|y)$ ]]; then
    echo "❌ Batch force push aborted."
    exit 1
  fi
else
  echo "⚠️  Auto-confirmed with --yes flag. Proceeding with force push."
fi

# Find all git repositories in the specified directory
echo "🔍 Finding git repositories..."
REPOS=()
while IFS= read -r repo; do
  REPOS+=("$repo")
done < <(find "$ROOT_DIR" -name ".git" -type d -prune | sed 's/\/.git$//')

REPO_COUNT=${#REPOS[@]}

if [[ $REPO_COUNT -eq 0 ]]; then
  echo "❌ No git repositories found in $ROOT_DIR"
  exit 1
fi

echo "✅ Found $REPO_COUNT repositories to process."
echo ""

# Process each repository
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_REPOS=()
SKIPPED_COUNT=0
SKIPPED_REPOS=()

for repo in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$repo")
  echo "⬆️  Processing: $REPO_NAME"
  echo "    Path: $repo"
  
  # Enter repository
  pushd "$repo" > /dev/null
  
  # Check if there are any changes to push
  if ! git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
    echo "    ⚠️  No upstream branch set. Skipping."
    SKIPPED_REPOS+=("$REPO_NAME (no upstream)")
    ((SKIPPED_COUNT++))
    popd > /dev/null
    continue
  fi
  
  # Check if there are any commits to push
  git fetch origin
  AHEAD=$(git rev-list --count @{upstream}..HEAD)
  BEHIND=$(git rev-list --count HEAD..@{upstream})
  
  if [[ $AHEAD -eq 0 && $BEHIND -eq 0 ]]; then
    echo "    ✅ Already in sync with remote. Skipping."
    SKIPPED_REPOS+=("$REPO_NAME (in sync)")
    ((SKIPPED_COUNT++))
    popd > /dev/null
    continue
  fi
  
  # Execute the force push
  CURRENT_BRANCH=$(git branch --show-current)
  echo "    🔄 Force pushing branch '$CURRENT_BRANCH'..."
  
  # Use our existing force push script
  $(dirname "$0")/force-push-to-remote.sh origin $BACKUP_FLAG --yes
  
  # Check result
  if [[ $? -eq 0 ]]; then
    echo "    ✅ Force push successful."
    SUCCESS_COUNT=$((SUCCESS_COUNT+1))
  else
    echo "    ❌ Force push failed."
    FAILED_REPOS+=("$REPO_NAME")
    ((FAILED_COUNT++))
  fi
  
  # Return to original directory
  popd > /dev/null
  echo ""
done

# Summary
echo "📊 Batch Force Push Summary:"
echo "=============================="
echo "✅ Successfully processed: $SUCCESS_COUNT/$REPO_COUNT repositories"

if [[ $SKIPPED_COUNT -gt 0 ]]; then
  echo "⏩ Skipped repositories: $SKIPPED_COUNT"
  for repo in "${SKIPPED_REPOS[@]}"; do
    echo "   - $repo"
  done
fi

if [[ $FAILED_COUNT -gt 0 ]]; then
  echo "❌ Failed repositories: $FAILED_COUNT"
  for repo in "${FAILED_REPOS[@]}"; do
    echo "   - $repo"
  done
  echo ""
  echo "Please check error messages above or process these repositories individually."
fi

# Verify that our counts match up with the total
if [[ $((SUCCESS_COUNT + SKIPPED_COUNT + FAILED_COUNT)) -ne $REPO_COUNT ]]; then
  echo "⚠️  Warning: Count mismatch detected!"
  echo "   Total repositories: $REPO_COUNT"
  echo "   Success + Skipped + Failed = $((SUCCESS_COUNT + SKIPPED_COUNT + FAILED_COUNT))"
fi

echo ""
echo "✨ Batch operation completed!"