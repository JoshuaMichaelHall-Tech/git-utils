#!/bin/zsh

# Wrapper script that runs scripts on repositories in the parent directory
# Usage: ./run-parent-repos.sh script_to_run.sh [--auto-respond]

# Check if a script was provided
if [[ $# -lt 1 ]]; then
  echo "❌ Error: Missing script parameter."
  echo "Usage: ./run-parent-repos.sh script_to_run.sh [--auto-respond]"
  exit 1
fi

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pass all arguments to run-on-all-repos.sh with the --parent-dir flag added
"$SCRIPT_DIR/run-on-all-repos.sh" "$@" --parent-dir
