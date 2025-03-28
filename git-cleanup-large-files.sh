#!/bin/zsh

# Script to find and remove large files from git history
# Usage: ./git-cleanup-large-files.sh [size-in-MB]

echo "🧹 Starting git large file cleanup script..."

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

echo "📍 Working in git repository root: $ROOT_DIR"

# Set the size threshold (default: 10MB)
SIZE_THRESHOLD=${1:-10}
SIZE_THRESHOLD_BYTES=$((SIZE_THRESHOLD * 1024 * 1024))

echo "🔍 Looking for files larger than ${SIZE_THRESHOLD}MB in the repository history..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
LARGE_FILES_LIST="$TEMP_DIR/large_files.txt"

# Find large files in git history
echo "⏳ Analyzing git objects... (this may take a while)"
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  awk '/^blob/ && $3 >= '"$SIZE_THRESHOLD_BYTES"' { print $2, $3, $4 }' |
  sort -k2nr > "$LARGE_FILES_LIST"

# Check if we found any large files
if [[ ! -s "$LARGE_FILES_LIST" ]]; then
  echo "✅ No files larger than ${SIZE_THRESHOLD}MB found in the repository history."
  rm -rf "$TEMP_DIR"
  exit 0
fi

# Display large files
echo "📋 Found large files in repository history:"
echo "------------------------------------------------"
echo "| Size (MB) | File Path |"
echo "------------------------------------------------"
while read -r HASH SIZE PATH; do
  SIZE_MB=$(echo "scale=2; $SIZE / 1048576" | bc)
  printf "| %-9s | %-50s |\n" "$SIZE_MB" "$PATH"
done < "$LARGE_FILES_LIST"
echo "------------------------------------------------"

# Ask user what they want to do
echo ""
echo "These files are taking up space in your repository history."
echo "What would you like to do?"
echo "   1. Remove files from history using git-filter-branch (slow but built-in)"
echo "   2. Remove files from history using BFG Repo Cleaner (faster but requires Java)"
echo "   3. Exit without removing any files"
read "choice?Choose an option (1/2/3): "

case $choice in
  1)
    echo "⚠️  WARNING: This operation will rewrite git history."
    echo "    All team members will need to reclone or rebase their repositories."
    read "confirm?Are you sure you want to proceed? (y/n): "
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Operation canceled."
      rm -rf "$TEMP_DIR"
      exit 0
    fi
    
    # Backup branch references
    echo "📦 Backing up references..."
    mkdir -p "$TEMP_DIR/backup-refs"
    git for-each-ref --format="%(refname)" refs/heads/ | while read ref; do
      git show-ref --hash $ref > "$TEMP_DIR/backup-refs/${ref//\//_}"
    done
    
    # Extract file paths to remove
    PATHS_TO_REMOVE=()
    while read -r HASH SIZE PATH; do
      PATHS_TO_REMOVE+=("$PATH")
    done < "$LARGE_FILES_LIST"
    
    # Create a filter expression for git-filter-branch
    FILTER_EXPRESSION=""
    for path in "${PATHS_TO_REMOVE[@]}"; do
      if [[ -n "$FILTER_EXPRESSION" ]]; then
        FILTER_EXPRESSION="$FILTER_EXPRESSION || "
      fi
      FILTER_EXPRESSION="${FILTER_EXPRESSION}rm -rf \"\$GIT_WORK_TREE/$path\""
    done
    
    # Run git-filter-branch
    echo "🔄 Removing large files from history... (this will take a long time)"
    git filter-branch --force --prune-empty --index-filter \
      "git ls-files -s | sed \"s|\t\\\"*|\t|\" | GIT_INDEX_FILE=\$GIT_INDEX_FILE.new git update-index --index-info && if [ -f \$GIT_INDEX_FILE.new ]; then mv \$GIT_INDEX_FILE.new \$GIT_INDEX_FILE; fi; $FILTER_EXPRESSION" \
      --tag-name-filter cat -- --all
    
    # Clean up
    echo "🧹 Cleaning up..."
    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
    echo "✅ Large files have been removed from history."
    echo "⚠️  You need to force push these changes to update the remote repository:"
    echo "    git push origin --force --all"
    echo "⚠️  Team members will need to reclone or carefully rebase their repositories."
    ;;
    
  2)
    # Check if Java is installed
    if ! command -v java &> /dev/null; then
      echo "❌ Error: Java is required for BFG Repo Cleaner but was not found."
      echo "   Please install Java or use option 1 instead."
      rm -rf "$TEMP_DIR"
      exit 1
    fi
    
    # Check if BFG is installed
    BFG_PATH=""
    if command -v bfg &> /dev/null; then
      BFG_PATH="bfg"
    elif [[ -f "$HOME/bin/bfg.jar" ]]; then
      BFG_PATH="java -jar $HOME/bin/bfg.jar"
    else
      echo "⬇️  Downloading BFG Repo Cleaner..."
      curl -L -o "$TEMP_DIR/bfg.jar" "https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar"
      BFG_PATH="java -jar $TEMP_DIR/bfg.jar"
    fi
    
    echo "⚠️  WARNING: This operation will rewrite git history."
    echo "    All team members will need to reclone or rebase their repositories."
    read "confirm?Are you sure you want to proceed? (y/n): "
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Operation canceled."
      rm -rf "$TEMP_DIR"
      exit 0
    fi
    
    # Create a mirror clone of the repository
    echo "🔄 Creating a mirror clone of the repository..."
    MIRROR_DIR="$TEMP_DIR/repo-mirror.git"
    git clone --mirror "$ROOT_DIR" "$MIRROR_DIR"
    
    # Extract file paths to remove
    PATHS_FILE="$TEMP_DIR/paths-to-remove.txt"
    while read -r HASH SIZE PATH; do
      echo "$PATH" >> "$PATHS_FILE"
    done < "$LARGE_FILES_LIST"
    
    # Run BFG to remove large files
    echo "🔄 Removing large files from history..."
    cd "$MIRROR_DIR"
    $BFG_PATH --strip-blobs-bigger-than "${SIZE_THRESHOLD}M" --no-blob-protection
    
    # Clean up the repository
    echo "🧹 Cleaning up..."
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
    # Return to the original repository
    cd "$ROOT_DIR"
    
    echo "✅ Large files have been removed from the mirror repository."
    echo ""
    echo "To complete the process, run the following commands:"
    echo "   cd $MIRROR_DIR"
    echo "   git push --mirror"
    echo "   cd $ROOT_DIR"
    echo "   git fetch"
    echo "   git reset --hard origin/main # or your main branch"
    echo ""
    echo "⚠️  Team members will need to reclone or carefully rebase their repositories."
    ;;
    
  3)
    echo "❌ Operation canceled. No files were removed."
    ;;
    
  *)
    echo "❌ Invalid option. No files were removed."
    ;;
esac

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "✨ All done!"
