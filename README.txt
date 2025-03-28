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

### flatten_files.sh

Moves all files from a directory and its subdirectories into a single directory.

```zsh
./flatten_files.sh
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

### git-prune-merged-branches.sh

Removes branches that have been merged into the main branch.

```zsh
./git-prune-merged-branches.sh [main-branch-name]
```

**Features:**
- Identifies fully merged branches
- Offers batch or selective deletion
- Optionally removes remote branches as well

### git-cleanup-large-files.sh

Finds and removes large files from Git history.

```zsh
./git-cleanup-large-files.sh [size-in-MB]
```

**Features:**
- Identifies files larger than the specified size (default: 10MB)
- Offers to remove them using git-filter-branch or BFG Repo Cleaner
- Provides detailed size information

### git-fix-author.sh

Corrects author information in Git commits.

```zsh
./git-fix-author.sh [--all|--specific]
```

**Features:**
- Updates author name/email for past commits
- Fixes all commits, specific commits, or commits by a specific author
- Handles complex Git filter-branch operations

### git-summarize-changes.sh

Creates reports of changes between Git references.

```zsh
./git-summarize-changes.sh [from-ref] [to-ref] [--markdown|--txt|--html]
```

**Features:**
- Generates formatted changelog between two references
- Categorizes commits (features, fixes, documentation, etc.)
- Creates statistics on contributors, files changed, and lines added/removed

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

## Input Handling

### input-capture.sh

Standalone script for running commands with input capturing across repositories.

```zsh
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
   echo 'export PATH="$PATH:$(pwd)"' >> ~/.zshrc
   source ~/.zshrc
   ```

## Usage Examples

### Cleaning up system files in all repositories

```zsh
cd ~/repos
./run-on-all-repos.sh git-clean-system-files.sh
```

### Archiving old branches in multiple repositories

```zsh
cd ~/repos
./run-on-all-repos.sh git-archive-old-branches.sh 6 --auto-respond
```

### Pulling updates for all repositories

```zsh
cd ~/repos
./run-on-all-repos.sh pull-from-github.sh
```

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
