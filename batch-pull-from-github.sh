#!/bin/zsh

# Script to pull updates for multiple repositories from GitHub
# Helps manage batch updates across multiple related repositories
# Usage: ./batch-pull-from-github.sh [path/to/root/directory] [--auto-stash]

# Set defaults
ROOT_DIR=${1:-$(pwd)}
AUTO_STASH=false
AUTO_CONFIRM=false

# Process arguments
for arg in "$@"; do
  if [[ "$arg" == "--auto-stash" ]]; then
    AUTO_STASH=true
  elif [[ "$arg" == "--yes" || "$arg" == "-y" ]]; then
    AUTO_CONFIRM=true
  fi
done

echo "⬇️  Batch Pull from GitHub ⬇️"
echo "=============================="
echo ""
echo "This script will pull updates for all git repositories in:"
echo "📁 $ROOT_DIR"
echo ""

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
  echo "⬇️  Processing: $REPO_NAME"
  echo "    Path: $repo"
  
  # Enter repository
  pushd "$repo" > /dev/null
  
  # Get current branch
  CURRENT_BRANCH=$(git branch --show-current)
  echo "    📂 Current branch: $CURRENT_BRANCH"
  
  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    if [[ "$AUTO_STASH" == true ]]; then
      echo "    📦 Auto-stashing uncommitted changes..."
      STASH_MESSAGE="Auto-stash before batch pull on $(date)"
      git stash push -m "$STASH_MESSAGE"
      STASHED=true
    else
      echo "    ⚠️  Uncommitted changes present. Skipping repository."
      SKIPPED_REPOS+=("$REPO_NAME (uncommitted changes)")
      ((SKIPPED_COUNT++))
      popd > /dev/null
      continue
    fi
  else
    STASHED=false
  fi
  
  # Check if branch exists on remote
  if ! git ls-remote --heads origin $CURRENT_BRANCH | grep -q $CURRENT_BRANCH; then
    echo "    ⚠️  Branch '$CURRENT_BRANCH' does not exist on remote. Skipping."
    SKIPPED_REPOS+=("$REPO_NAME (no remote branch)")
    ((SKIPPED_COUNT++))
    popd > /dev/null
    continue
  fi
  
  # Perform the pull
  echo "    🔄 Pulling latest changes from GitHub..."
  git pull origin $CURRENT_BRANCH
  
  # Check result
  if [[ $? -eq 0 ]]; then
    echo "    ✅ Pull successful."
    SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    
    # Restore stashed changes if needed
    if [[ "$STASHED" == true ]]; then
      echo "    📦 Restoring stashed changes..."
      git stash pop
      
      # Check for conflicts
      if [[ $? -ne 0 ]]; then
        echo "    ⚠️  Merge conflicts occurred when restoring stashed changes."
        echo "        Please resolve conflicts manually in: $repo"
      else
        echo "    ✅ Stashed changes restored successfully."
      fi
    fi
  else
    echo "    ❌ Pull failed."
    FAILED_REPOS+=("$REPO_NAME")
    ((FAILED_COUNT++))
  fi
  
  # Return to original directory
  popd > /dev/null
  echo ""
done

# Summary
echo "📊 Batch Pull Summary:"
echo "======================="
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