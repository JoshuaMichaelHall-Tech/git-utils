# Git Repository Utility Scripts

A comprehensive collection of utility scripts for maintaining and managing multiple Git repositories efficiently.

## Overview

This project provides a suite of scripts to help with common Git repository maintenance tasks:

1. Running scripts across multiple repositories
2. Managing system files in repositories
3. Organizing files in complex directories
4. Archiving inactive branches
5. Cleaning up merged branches
6. Removing large files from history
7. Fixing author information
8. Generating change summaries
9. Creating repository backups
10. Setting up Git hooks
11. Synchronizing with remote repositories

All scripts use zsh (the default shell on modern macOS) and are designed to work with a terminal-centric workflow.

## Main Scripts

### run-on-all-repos.sh

Runs a script on all first-level subdirectories, with automatic input handling and logging.

```zsh
./run-on-all-repos.sh script_to_run.sh [--auto-respond]
```

**Features:**
- Processes every first-level directory that contains a Git repository
- Creates detailed logs of script output
- Captures user input and offers to reuse answers across repositories
- Reports success/failure statistics

**Example Usage:**
```zsh
# Run with manual confirmation for each saved response
cd ~/repos
./run-on-all-repos.sh git-clean-system-files.sh

# Run with automatic response saving (saves all inputs without asking)
cd ~/repos
./run-on-all-repos.sh git-prune-merged-branches.sh --auto-respond

# Generate logs of all pull operations
cd ~/repos
./run-on-all-repos.sh pull-from-github.sh
```

### git-clean-system-files.sh

Removes common system files from Git repositories and updates `.gitignore` to prevent them from being tracked.

```zsh
./git-clean-system-files.sh
```

**Handles:**
- macOS: `.DS_Store`, `.Spotlight-V100`, etc.
- Windows: `Thumbs.db`, `desktop.ini`, etc.
- Linux: `.directory`, backup files (`*~`), etc.
- Editors: Vim swap files (`.*.swp`), etc.

**Example Usage:**
```zsh
# Clean a single repository
cd ~/repos/my-project
./git-clean-system-files.sh

# View files that would be removed without actually removing them
cd ~/repos/my-project
./git-clean-system-files.sh --dry-run

# Clean and update .gitignore
cd ~/repos/my-project
./git-clean-system-files.sh --update-gitignore
```

### flatten_files.sh

Moves all files from a directory and its subdirectories into a single directory.

```zsh
./flatten_files.sh
```

**Example Usage:**
```zsh
# Flatten files in the current directory
cd ~/Documents/nested-folders
./flatten_files.sh

# Flatten files in a specific directory
./flatten_files.sh ~/Pictures/vacation-photos

# Flatten with a custom naming scheme to prevent conflicts
./flatten_files.sh --rename-prefix="folder-"
```

## Repository Management Scripts

### git-archive-old-branches.sh

Identifies and archives or deletes inactive branches.

```zsh
./git-archive-old-branches.sh [months] [--delete]
```

**Features:**
- Finds branches not modified in X months (default: 3)
- Archives them to refs/archived/ or deletes them with confirmation
- Protects system branches (main, master, develop, etc.)

**Example Usage:**
```zsh
# Archive branches not modified in the last 3 months
cd ~/repos/my-project
./git-archive-old-branches.sh

# Archive branches older than 6 months
cd ~/repos/my-project
./git-archive-old-branches.sh 6

# Delete branches older than 12 months
cd ~/repos/my-project
./git-archive-old-branches.sh 12 --delete
```

### git-prune-merged-branches.sh

Removes branches that have been merged into the main branch.

```zsh
./git-prune-merged-branches.sh [main-branch-name]
```

**Features:**
- Identifies fully merged branches
- Offers batch or selective deletion
- Optionally removes remote branches as well

**Example Usage:**
```zsh
# Prune branches merged into main
cd ~/repos/my-project
./git-prune-merged-branches.sh

# Prune branches merged into development
cd ~/repos/my-project
./git-prune-merged-branches.sh development

# Prune branches merged into a specific feature branch
cd ~/repos/my-project
./git-prune-merged-branches.sh feature/authentication
```

### git-cleanup-large-files.sh

Finds and removes large files from Git history.

```zsh
./git-cleanup-large-files.sh [size-in-MB]
```

**Features:**
- Identifies files larger than the specified size (default: 10MB)
- Offers to remove them using git-filter-branch or BFG Repo Cleaner
- Provides detailed size information

**Example Usage:**
```zsh
# Find files larger than 10MB (default)
cd ~/repos/my-project
./git-cleanup-large-files.sh

# Find files larger than 5MB
cd ~/repos/my-project
./git-cleanup-large-files.sh 5

# Use with run-on-all-repos to scan all repositories
cd ~/repos
./run-on-all-repos.sh git-cleanup-large-files.sh
```

### git-fix-author.sh

Corrects author information in Git commits.

```zsh
./git-fix-author.sh [--all|--specific]
```

**Features:**
- Updates author name/email for past commits
- Fixes all commits, specific commits, or commits by a specific author
- Handles complex Git filter-branch operations

**Example Usage:**
```zsh
# Fix author info interactively
cd ~/repos/my-project
./git-fix-author.sh

# Fix author info for all commits
cd ~/repos/my-project
./git-fix-author.sh --all

# Fix author info for specific commits
cd ~/repos/my-project
./git-fix-author.sh --specific
```

### git-summarize-changes.sh

Creates reports of changes between Git references.

```zsh
./git-summarize-changes.sh [from-ref] [to-ref] [--markdown|--txt|--html]
```

**Features:**
- Generates formatted changelog between two references
- Categorizes commits (features, fixes, documentation, etc.)
- Creates statistics on contributors, files changed, and lines added/removed

**Example Usage:**
```zsh
# Create a markdown summary between the current state and the latest tag
cd ~/repos/my-project
./git-summarize-changes.sh $(git describe --tags --abbrev=0) HEAD

# Create an HTML report for a release
cd ~/repos/my-project
./git-summarize-changes.sh v1.0.0 v2.0.0 --html

# Generate a report between two specific commits
cd ~/repos/my-project
./git-summarize-changes.sh a1b2c3d4 e5f6g7h8 --txt
```

### git-backup-repo.sh

Creates full backups of Git repositories.

```zsh
./git-backup-repo.sh [backup-dir] [--upload]
```

**Features:**
- Makes complete backups including all branches and history
- Supports full and incremental backups
- Implements retention policies
- Optionally uploads to remote storage (rclone, SCP)

**Example Usage:**
```zsh
# Create a backup with default settings
cd ~/repos/my-project
./git-backup-repo.sh

# Specify a backup directory
cd ~/repos/my-project
./git-backup-repo.sh ~/backups/git-repos

# Create a backup and upload it to remote storage
cd ~/repos/my-project
./git-backup-repo.sh --upload

# Back up all repositories
cd ~/repos
./run-on-all-repos.sh git-backup-repo.sh ~/backups/git-repos
```

### git-setup-hooks.sh

Installs useful Git hooks for code quality.

```zsh
./git-setup-hooks.sh [language]
```

**Features:**
- Sets up pre-commit hooks for linting and formatting
- Configures commit message templates
- Adds safeguards for protected branches
- Supports multiple programming languages

**Example Usage:**
```zsh
# Set up hooks with automatic language detection
cd ~/repos/my-project
./git-setup-hooks.sh

# Set up hooks for a specific language
cd ~/repos/my-project
./git-setup-hooks.sh ruby

# Set up hooks for all repositories
cd ~/repos
./run-on-all-repos.sh git-setup-hooks.sh
```

## Remote Sync Scripts

### pull-from-github.sh

Updates a local repository from its GitHub remote.

```zsh
./pull-from-github.sh
```

**Features:**
- Handles uncommitted changes (stash, commit, abort)
- Manages branches that don't exist on remote
- Safely restores stashed changes after pull

**Example Usage:**
```zsh
# Pull updates for the current repository
cd ~/repos/my-project
./pull-from-github.sh

# Pull updates for all repositories
cd ~/repos
./run-on-all-repos.sh pull-from-github.sh
```

### push-to-github.sh

Updates a GitHub repository from local changes.

```zsh
./push-to-github.sh
```

**Features:**
- Interactive file selection
- Supports adding all, specific, or interactive staging
- Detects conflicts with remote changes
- Handles upstream configuration

**Example Usage:**
```zsh
# Push changes from the current repository
cd ~/repos/my-project
./push-to-github.sh

# Push changes from multiple repositories (be careful!)
cd ~/repos
./run-on-all-repos.sh push-to-github.sh --auto-respond
```

## Input Handling

### input-capture.sh

Standalone script for running commands with input capturing across repositories.

```zsh
./input-capture.sh
```

**Example Usage:**
```zsh
# Run the script and follow the interactive prompts
cd ~/repos
./input-capture.sh
```

## Installation

1. Clone this repository:
   ```zsh
   git clone https://github.com/yourusername/git-repository-utilities.git
   ```

2. Make the scripts executable:
   ```zsh
   cd git-repository-utilities
   chmod +x *.sh
   ```

3. Optionally, add the directory to your PATH for easy access:
   ```zsh
   echo 'export PATH="$PATH:$HOME/tech_repos/git-repository-utilities"' >> ~/.zshrc
   source ~/.zshrc
   ```

## Credits and Resources

This project utilizes and references several external tools and resources:

- **BFG Repo-Cleaner**: The `git-cleanup-large-files.sh` script offers integration with the BFG Repo-Cleaner by Roberto Tyley, a faster alternative to git-filter-branch for removing large files.
  - Website: [https://rtyley.github.io/bfg-repo-cleaner/](https://rtyley.github.io/bfg-repo-cleaner/)
  - License: GPL-3.0

- **Git Documentation**: Many scripts are based on best practices from the official Git documentation.
  - Website: [https://git-scm.com/doc](https://git-scm.com/doc)

- **ShellCheck**: Recommended for validating shell scripts, and used in the `git-setup-hooks.sh` script.
  - Website: [https://www.shellcheck.net/](https://www.shellcheck.net/)
  - License: GPL-3.0

- **rclone**: Used in the `git-backup-repo.sh` script for cloud storage uploads.
  - Website: [https://rclone.org/](https://rclone.org/)
  - License: MIT

## Known Issues and Workarounds

### Passing Arguments to Scripts with run-on-all-repos.sh

When using `run-on-all-repos.sh`, there's a limitation in how arguments are passed to subscripts. If you try to pass arguments to both the main script and the subscript, they may not be correctly separated.

**Issue Example:**
```zsh
# This doesn't work as expected
./run-on-all-repos.sh git-fix-author.sh --all --auto-respond
```

The `--all` flag is intended for `git-fix-author.sh`, but `run-on-all-repos.sh` will try to interpret it as its own flag.

**Workarounds:**

1. **Use wrapper scripts:** Create simple wrapper scripts that include the arguments for the subscript.

   Example using the included wrapper for fixing author information:
   ```zsh
   # This works correctly
   ./run-on-all-repos.sh fix-author-all.sh --auto-respond
   ```
   
   The `fix-author-all.sh` wrapper script automatically runs `git-fix-author.sh --all`.

2. **Quote the command with arguments:**
   ```zsh
   # This works if your shell supports it
   ./run-on-all-repos.sh "git-fix-author.sh --all" --auto-respond
   ```

3. **Use environment variables** to pass settings to subscripts.

### Using Default Values with git-fix-author.sh

When using `git-fix-author.sh`, it will show your current Git configuration (name and email) as defaults:

```
Current git config:
   Name: Your Name
   Email: your.email@example.com
```

To use these defaults:
- Simply press Enter at the prompts for new author information
- The script will use your current Git configuration

When used with `run-on-all-repos.sh --auto-respond`, you'll need to provide the answers only once, and they'll be reused for all repositories.

## Requirements

- zsh (default shell on modern macOS)
- Git
- Write access to the repositories

## License

MIT

## Author

Joshua Michael Hall
contact@joshuamichaelhall.com
https://joshuamichaelhall.com
