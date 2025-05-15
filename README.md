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

## Path Handling and Script Usage

The scripts in this collection can be used in two ways:

1. **Individual Repository Mode**: Run scripts directly inside a specific repository
   ```zsh
   cd ~/repos/my-project
   ~/repos/git-repository-utilities/git-fix-author.sh
   # or if git-repository-utilities is in your PATH
   git-fix-author.sh
   ```

2. **Batch Mode**: Run scripts on multiple repositories from a parent directory
   ```zsh
   cd ~/repos
   ./git-repository-utilities/run-on-all-repos.sh git-repository-utilities/git-clean-system-files.sh
   ```

All scripts use relative paths instead of absolute paths, allowing them to be used from any location. The scripts intelligently determine their locations relative to each other, making them flexible for various directory structures.

Helper scripts like `fix-author-wrapper.sh` automatically locate their dependencies whether run from within the utilities directory or from a parent directory containing multiple repositories.

## Core Utility Scripts

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

**Examples:**

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

**Examples:**

```zsh
# Run on repositories in the parent directory
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-clean-system-files.sh

# Run with automatic response saving
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-prune-merged-branches.sh --auto-respond
```

### make-executable.sh

Makes all shell scripts in the repository executable.

```zsh
./make-executable.sh [--parent-dir]
```

**Features:**
- Finds all .sh files and sets executable permissions
- Can process scripts in the parent directory with the `--parent-dir` flag

**Examples:**

```zsh
# Make all scripts in current directory executable
./make-executable.sh

# Make scripts in both current and parent directory executable
./make-executable.sh --parent-dir
```

## File Management Scripts

### git-clean-system-files.sh

Removes common system files from Git repositories and updates `.gitignore` to prevent them from being tracked.

```zsh
./git-clean-system-files.sh
```

**Features:**
- Removes typical system files that should not be tracked:
  - macOS: `.DS_Store`, `.Spotlight-V100`, etc.
  - Windows: `Thumbs.db`, `desktop.ini`, etc.
  - Linux: `.directory`, backup files (`*~`), etc.
  - Editors: Vim swap files (`.*.swp`), etc.
- Updates .gitignore to exclude these files in the future
- Commits and pushes the changes

**Examples:**

```zsh
# Clean a single repository
cd ~/repos/my-project
./git-clean-system-files.sh

# Clean all repositories from within the utilities repo
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-clean-system-files.sh
```

### flatten_files.sh

Moves all files from a directory and its subdirectories into a single directory.

```zsh
./flatten_files.sh [directory_path]
```

**Features:**
- Recursively finds all files in subdirectories
- Moves them to a single "current_files" directory
- Appends unique identifiers to prevent filename collisions

**Examples:**

```zsh
# Flatten files in the current directory
cd ~/Documents/nested-folders
./flatten_files.sh

# Flatten files in a specific directory
./flatten_files.sh ~/Pictures/vacation-photos
```

### git-cleanup-large-files.sh

Identifies and removes large files from Git history to reduce repository size.

```zsh
./git-cleanup-large-files.sh [size-in-MB]
```

**Features:**
- Finds files larger than a specified size (default: 10MB) in repository history
- Offers to remove them using git-filter-branch or BFG Repo Cleaner
- Creates backups before history rewriting

**Examples:**

```zsh
# Find and remove files larger than 10MB (default) from a single repository
cd ~/repos/my-project
./git-cleanup-large-files.sh

# Find and remove files larger than 50MB
cd ~/repos/my-project
./git-cleanup-large-files.sh 50

# Clean up large files in all repositories
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-cleanup-large-files.sh 20
```

## Branch Management Scripts

### git-archive-old-branches.sh

Identifies and archives or deletes inactive branches.

```zsh
./git-archive-old-branches.sh [months] [--delete]
```

**Features:**
- Finds branches not modified in X months (default: 3)
- Archives them to refs/archived/ or deletes them with confirmation
- Protects system branches (main, master, develop, etc.)

**Examples:**

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
- Automatically detects main branch if not specified

**Examples:**

```zsh
# Prune merged branches from a single repository
cd ~/repos/my-project
./git-prune-merged-branches.sh

# Specify a different main branch
cd ~/repos/my-project
./git-prune-merged-branches.sh develop

# Prune merged branches in all repositories
cd ~/repos/git-repository-utilities
./run-parent-repos.sh git-prune-merged-branches.sh
```

## Repository Synchronization Scripts

### pull-from-github.sh

Updates a local repository from its GitHub remote with intelligent error handling.

```zsh
./pull-from-github.sh
```

**Features:**
- Handles uncommitted changes by offering to stash them
- Deals with branches that don't exist on remote
- Checks for remote changes and handles conflicts

**Examples:**

```zsh
# Pull updates for a single repository
cd ~/repos/my-project
./pull-from-github.sh

# Pull updates for all repositories
cd ~/repos
./run-on-all-repos.sh pull-from-github.sh
```

### batch-pull-from-github.sh

Pulls updates for multiple repositories from GitHub in batch mode.

```zsh
./batch-pull-from-github.sh [path/to/root/directory] [--auto-stash] [--yes|-y]
```

**Features:**
- Processes all git repositories found in a directory
- Tracks successful and failed operations
- Can automatically stash uncommitted changes with the `--auto-stash` flag
- Handles branches that don't exist on remote
- Provides detailed summary of operations

**Examples:**

```zsh
# Pull updates for all repositories in current directory
cd ~/repos
./batch-pull-from-github.sh

# Pull updates for repositories in a specific directory
./batch-pull-from-github.sh ~/projects

# Pull updates with automatic stashing of changes
./batch-pull-from-github.sh ~/repos --auto-stash

# Pull updates with automatic confirmation
./batch-pull-from-github.sh ~/repos --yes
```

### patch-rebase-pull-from-github.sh

Pull updates using a patch-rebase strategy that preserves local changes.

```zsh
./patch-rebase-pull-from-github.sh [--create-patch] [--apply-only]
```

**Features:**
- Creates a patch of local changes before pulling
- Updates the codebase with remote changes
- Reapplies local changes on top of the updated codebase
- Can be used to just create a patch (with `--create-patch`)
- Can be used to just apply a previously created patch (with `--apply-only`)
- Useful when you have local changes and want to incorporate upstream changes

**Examples:**

```zsh
# Perform patch-rebase-pull operation
cd ~/repos/my-project
./patch-rebase-pull-from-github.sh

# Only create a patch file of local changes
cd ~/repos/my-project
./patch-rebase-pull-from-github.sh --create-patch

# Apply a previously created patch
cd ~/repos/my-project
./patch-rebase-pull-from-github.sh --apply-only
```

### push-to-github.sh

Sends local changes to GitHub with interactive staging and conflict handling.

```zsh
./push-to-github.sh
```

**Features:**
- Offers options for adding changes (all, specific files, interactive)
- Handles branches without upstream
- Detects potential conflicts with remote changes
- Properly reports when no changes are needed

**Examples:**

```zsh
# Push changes from a single repository
cd ~/repos/my-project
./push-to-github.sh

# Push changes from all repositories
cd ~/repos
./run-on-all-repos.sh push-to-github.sh
```

### batch-push-to-github.sh

Non-interactive version of push-to-github.sh for automated batch operations.

```zsh
./batch-push-to-github.sh [commit-message] [--yes|-y]
```

**Features:**
- Automatically adds all changes without prompting
- Uses provided commit message or a default message
- Handles potential conflicts by automatically pulling changes
- Ideal for use with run-on-all-repos.sh for batch updates
- Properly reports when no changes are needed

**Examples:**

```zsh
# Push all changes from a single repository with default message
cd ~/repos/my-project
./batch-push-to-github.sh

# Push all changes with a custom commit message
cd ~/repos/my-project
./batch-push-to-github.sh "Update documentation"

# Push changes from all repositories with the same message
cd ~/repos
./run-on-all-repos.sh batch-push-to-github.sh "Update dependencies" --auto-respond

# Push changes with automatic confirmation
cd ~/repos/my-project
./batch-push-to-github.sh "Update documentation" --yes
```

### batch-force-push-to-github.sh

Force pushes multiple repositories to GitHub in batch mode.

```zsh
./batch-force-push-to-github.sh [path/to/root/directory] [--no-backup] [--yes|-y]
```

**Features:**
- Processes all git repositories found in a directory
- Creates backups before force pushing (unless `--no-backup` is specified)
- Tracks successful, failed, and skipped operations
- Shows detailed summary of operations
- Warns about potential data loss and requires explicit confirmation
- Accepts `--yes` or `-y` flag to auto-confirm all prompts (useful for scripts)

**Examples:**

```zsh
# Force push all repositories in current directory
cd ~/repos
./batch-force-push-to-github.sh

# Force push repositories in a specific directory
./batch-force-push-to-github.sh ~/projects

# Force push without creating backups
./batch-force-push-to-github.sh ~/repos --no-backup

# Force push with automatic confirmation (no prompts)
./batch-force-push-to-github.sh ~/repos --yes
```

### git-add-commit-push.sh

Combines add, commit, and push operations with interactive options.

```zsh
./git-add-commit-push.sh [commit-message] [--all]
```

**Features:**
- Offers various options for staging changes
- Allows passing a commit message directly as an argument
- Handles remote conflicts intelligently

**Examples:**

```zsh
# Interactive add, commit, and push for a single repository
cd ~/repos/my-project
./git-add-commit-push.sh

# Add all changes, commit with message, and push
cd ~/repos/my-project
./git-add-commit-push.sh "Update documentation" --all

# Run on all repositories
cd ~/repos
./run-on-all-repos.sh git-add-commit-push.sh "Update dependencies" --all
```

### force-push-to-remote.sh

Safely performs force-push operations with backup creation.

```zsh
./force-push-to-remote.sh [remote-name] [--skip-backup] [--yes|-y]
```

**Features:**
- Creates backup bundle before force-pushing
- Requires explicit confirmation
- Shows differences between local and remote

**Examples:**

```zsh
# Force push to origin with backup
cd ~/repos/my-project
./force-push-to-remote.sh

# Force push to a specific remote
cd ~/repos/my-project
./force-push-to-remote.sh upstream

# Force push without creating a backup
cd ~/repos/my-project
./force-push-to-remote.sh origin --skip-backup

# Force push with automatic confirmation (no prompts)
cd ~/repos/my-project
./force-push-to-remote.sh origin --yes
```

## Repository Maintenance Scripts

### git-backup-repo.sh

Creates full or incremental backups of Git repositories.

```zsh
./git-backup-repo.sh [backup-dir] [--upload]
```

**Features:**
- Creates complete repository backups as tar.gz and bundle files
- Offers incremental backups to save space
- Can upload backups to cloud storage (using rclone or scp)
- Includes repository metadata and statistics

**Examples:**

```zsh
# Create a backup of a single repository
cd ~/repos/my-project
./git-backup-repo.sh

# Create a backup and upload it to remote storage
cd ~/repos/my-project
./git-backup-repo.sh ~/backups --upload

# Backup all repositories
cd ~/repos
./run-on-all-repos.sh git-backup-repo.sh
```

### git-fix-author.sh

Corrects author information in Git commits.

```zsh
./git-fix-author.sh [--all|--specific]
```

**Features:**
- Can fix all commits, specific commits, or commits by a specific author
- Preserves commit messages and other metadata
- Creates backups before history rewriting

**Examples:**

```zsh
# Fix author information interactively
cd ~/repos/my-project
./git-fix-author.sh

# Fix all commits with incorrect author information
cd ~/repos/my-project
./git-fix-author.sh --all

# Fix specific commits
cd ~/repos/my-project
./git-fix-author.sh --specific

# Fix author information in all repositories
cd ~/repos/git-repository-utilities
./run-parent-repos.sh fix-author-wrapper.sh
```

### fix-author-wrapper.sh

Wrapper script for git-fix-author.sh to use with run-on-all-repos.sh.

```zsh
./run-on-all-repos.sh fix-author-wrapper.sh --auto-respond
```

**Features:**
- Automatically applies the fix-author operation with --all flag
- Designed to work with run-on-all-repos.sh

**Examples:**

```zsh
# Fix author information in all repositories
cd ~/repos
./run-on-all-repos.sh fix-author-wrapper.sh --auto-respond
```

### git-summarize-changes.sh

Creates formatted summaries of changes between Git versions.

```zsh
./git-summarize-changes.sh [from-ref] [to-ref] [--markdown|--txt|--html]
```

**Features:**
- Generates comprehensive change reports in markdown, text, or HTML
- Categorizes commits by type (features, bugfixes, docs, etc.)
- Includes statistics and contributor information

**Examples:**

```zsh
# Generate a changelog between two tags
cd ~/repos/my-project
./git-summarize-changes.sh v1.0 v1.1

# Generate HTML-formatted changelog
cd ~/repos/my-project
./git-summarize-changes.sh HEAD~50 HEAD --html

# Generate changelogs for all repositories
cd ~/repos
./run-on-all-repos.sh git-summarize-changes.sh HEAD~20 HEAD
```

### git-setup-hooks.sh

Installs useful Git hooks for code quality.

```zsh
./git-setup-hooks.sh [language]
```

**Features:**
- Creates pre-commit hooks for linting and formatting
- Sets up commit message validation
- Prevents accidental pushes to protected branches
- Supports multiple programming languages

**Examples:**

```zsh
# Set up Git hooks for a Ruby repository
cd ~/repos/my-ruby-project
./git-setup-hooks.sh ruby

# Automatically detect language and set up hooks
cd ~/repos/my-project
./git-setup-hooks.sh

# Set up hooks for all repositories
cd ~/repos
./run-on-all-repos.sh git-setup-hooks.sh
```

## Utility Scripts for Multi-Repository Operations

### input-capture.sh

Advanced script for capturing and reusing user input across multiple repositories.

```zsh
./input-capture.sh
```

**Features:**
- More sophisticated alternative to run-on-all-repos.sh
- Captures and saves all user inputs
- Creates wrapper scripts to reuse responses

**Examples:**

```zsh
# Run with input capture
cd ~/repos
./input-capture.sh
# Then follow the prompts to specify which script to run
```

### input-handler.sh

Helper script for transforming scripts to use automated input handling.

```zsh
./input-handler.sh script_to_modify responses_file
```

**Features:**
- Transforms scripts to use automated input handling
- Creates a processed version of the script with input handling

**Examples:**

```zsh
# Process a script for automated input handling
./input-handler.sh git-clean-system-files.sh ~/responses.txt
```

## Acknowledgements

This project was developed with assistance from Anthropic's Claude AI assistant, which helped with:
- Documentation writing and organization
- Code structure suggestions
- Troubleshooting and debugging assistance

Claude was used as a development aid while all final implementation decisions and code review were performed by Joshua Michael Hall.

## Disclaimer

These scripts are provided "as is", without warranty of any kind. Use them at your own risk. The author is not responsible for any data loss or damage caused by the use of these scripts. Always make backups before performing operations that modify Git history.

If you encounter any issues or have suggestions for improvements, please open an issue on the GitHub repository.
