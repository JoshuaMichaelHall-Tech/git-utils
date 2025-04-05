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
./run-on-all-repos.sh script_to_run.sh [--auto-respond] [--parent-dir]
```

**Features:**
- Processes every first-level directory that contains a Git repository
- Can operate on repositories in the current directory or parent directory (with `--parent-dir` flag)
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

# Run on repositories in the parent directory
cd ~/repos/git-repository-utilities
./run-on-all-repos.sh git-clean-system-files.sh --parent-dir
```

### run-parent-repos.sh

A convenience wrapper that runs scripts on repositories in the parent directory.

```zsh
./run-parent-repos.sh script_to_run.sh [--auto-respond]
```

**Features:**
- Automatically adds the `--parent-dir` flag to run-on-all-repos.sh
- Useful when you want to run scripts on repositories from within the git-repository-utilities directory
- Passes all other arguments to run-on-all-repos.sh

**Example Usage:**
```zsh
# Run on repositories in the parent directory
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-clean-system-files.sh

# Run with automatic response saving
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-prune-merged-branches.sh --auto-respond
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

# Clean all repositories from within the utilities repo
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-clean-system-files.sh
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

# Archive branches in all repositories from the utilities directory
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-archive-old-branches.sh 6
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
```