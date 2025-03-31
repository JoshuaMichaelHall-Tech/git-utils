#!/bin/zsh

# Wrapper script for git-fix-author.sh to use with run-on-all-repos.sh
# This script automatically applies the fix-author operation with --all flag
# Usage: ./run-on-all-repos.sh fix-author-all.sh --auto-respond

# Find the actual location of git-fix-author.sh
# First check if it's in the same directory as this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/git-fix-author.sh" ]]; then
  FIX_AUTHOR_SCRIPT="$SCRIPT_DIR/git-fix-author.sh"
# Otherwise check if it's in the PATH
elif command -v git-fix-author.sh &> /dev/null; then
  FIX_AUTHOR_SCRIPT="$(command -v git-fix-author.sh)"
else
  echo "❌ Error: git-fix-author.sh not found in directory or PATH"
  exit 1
fi

# Get the current Git user information for defaults
CURRENT_NAME=$(git config user.name)
CURRENT_EMAIL=$(git config user.email)

echo "🔄 Running fix-author with --all flag"
echo "👤 Will use current Git user as default:"
echo "   Name: $CURRENT_NAME"
echo "   Email: $CURRENT_EMAIL"
echo ""

# Run the fix-author script with the --all flag
# The script will handle the prompts for name/email and we rely on auto-respond
# from run-on-all-repos.sh to handle the responses
"$FIX_AUTHOR_SCRIPT" --all
