#!/bin/zsh

# Wrapper script for git-fix-author.sh to use with run-on-all-repos.sh
# This script automatically applies the fix-author operation with --all flag
# Usage: ./run-on-all-repos.sh fix-author-wrapper.sh --auto-respond

# Find the git-fix-author.sh script - works whether run from git-repository-utilities or parent dir
SCRIPT_NAME="git-fix-author.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try local directory first
if [[ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]]; then
  FIX_AUTHOR_SCRIPT="$SCRIPT_DIR/$SCRIPT_NAME"
# Then try the git-repository-utilities dir if run from parent 
elif [[ -f "$SCRIPT_DIR/git-repository-utilities/$SCRIPT_NAME" ]]; then
  FIX_AUTHOR_SCRIPT="$SCRIPT_DIR/git-repository-utilities/$SCRIPT_NAME"
# Finally try parent directory if run from git-repository-utilities
elif [[ -f "$SCRIPT_DIR/../$SCRIPT_NAME" ]]; then
  FIX_AUTHOR_SCRIPT="$SCRIPT_DIR/../$SCRIPT_NAME"
else
  # If all else fails, try to find it in PATH
  FIX_AUTHOR_SCRIPT=$(which "$SCRIPT_NAME" 2>/dev/null)
fi

# Check if the script exists
if [[ ! -f "$FIX_AUTHOR_SCRIPT" ]]; then
  echo "❌ Error: git-fix-author.sh not found at $FIX_AUTHOR_SCRIPT"
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

# Create a temporary expect script to automatically answer 'yes' to the confirmation prompt
TEMP_EXPECT_SCRIPT=$(mktemp)

cat > "$TEMP_EXPECT_SCRIPT" << 'EOF'
#!/usr/bin/expect -f
set timeout -1
spawn $env(FIX_AUTHOR_SCRIPT) --all

# Handle name/email prompts
expect "New Name (default:"
send "\r"
expect "New Email (default:"
send "\r"

# Handle confirmation prompt
expect "Are you sure you want to proceed? (y/n):"
send "y\r"

# Stay for the rest of the process
expect eof
EOF

chmod +x "$TEMP_EXPECT_SCRIPT"

# Run the expect script with the environment variable for the fix-author script
export FIX_AUTHOR_SCRIPT
"$TEMP_EXPECT_SCRIPT"

# Clean up
rm -f "$TEMP_EXPECT_SCRIPT"
