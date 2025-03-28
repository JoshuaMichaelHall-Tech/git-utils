# Repository Utility Scripts

This repository contains utility scripts to help with common repository maintenance tasks:

1. **git-clean-system-files.sh** - Remove common system files and update `.gitignore`
2. **flatten_files.sh** - Move all files from subdirectories to a single directory

## Problems & Solutions

### System Files in Git Repositories

#### Problem
Various operating systems automatically create hidden system files:
- macOS creates `.DS_Store` files in directories browsed in Finder
- Windows creates `Thumbs.db` and other cache files
- Linux creates backup files ending with `~`
- Editors like Vim create `.swp` files

These files:
- Are system-specific and shouldn't be in version control
- Create unnecessary noise in commits
- Cause merge conflicts when users with different operating systems work together
- Reveal your directory structure to others when committed

#### Solution: git-clean-system-files.sh
1. Removes all existing system files from your repository
2. Creates a `.gitignore` file if it doesn't exist
3. Adds common system files patterns to the `.gitignore`
4. Commits and pushes these changes

### Nested Files in Complex Directory Structures

#### Problem
- Files scattered across many subdirectories can be difficult to manage
- Finding specific files within complex directory structures is time-consuming
- Moving files between nested directories can disrupt relative paths
- Analyzing or processing all files at once is challenging

#### Solution: flatten_files.sh
1. Creates a single directory to contain all files
2. Moves all files from subdirectories into the single directory
3. Preserves unique filenames by adding identifiers when needed
4. Simplifies file management and analysis

## Scripts

### git-clean-system-files.sh

Removes common system files from your Git repository, updates your `.gitignore` to prevent them from being tracked in the future, and commits these changes.

### flatten_files.sh

Moves all files from a directory and its subdirectories into a new directory called `current_files` in the location where the script is run. Handles naming conflicts by appending a timestamp and random number to duplicate filenames.

## Installation

### git-clean-system-files.sh

1. Download the script:
   ```zsh
   curl -o git-clean-system-files.sh https://raw.githubusercontent.com/yourusername/yourrepo/main/git-clean-system-files.sh
   ```

2. Make it executable:
   ```zsh
   chmod +x git-clean-system-files.sh
   ```

3. Optionally, move it somewhere in your PATH for easy access:
   ```zsh
   mv git-clean-system-files.sh /usr/local/bin/git-clean-system-files
   ```

### flatten_files.sh

1. Download the script:
   ```zsh
   curl -o flatten_files.sh https://raw.githubusercontent.com/yourusername/yourrepo/main/flatten_files.sh
   ```

2. Make it executable:
   ```zsh
   chmod +x flatten_files.sh
   ```

3. Optionally, move it somewhere in your PATH for easy access:
   ```zsh
   mv flatten_files.sh /usr/local/bin/flatten_files
   ```

## Usage

### git-clean-system-files.sh

Run the script from anywhere within a Git repository:

```zsh
./git-clean-system-files.sh
```

Or if you moved it to your PATH:

```zsh
git-clean-system-files
```

### flatten_files.sh

Run the script in the directory where you want the files to be flattened:

```zsh
./flatten_files.sh
```

Or if you moved it to your PATH:

```zsh
flatten_files
```

## What They Do

### git-clean-system-files.sh

The script will:
- Check if you're in a Git repository
- Find and delete common system files
- Create a `.gitignore` file if one doesn't exist
- Add system file patterns to `.gitignore`
- Commit and push the changes

### flatten_files.sh

The script will:
- Create a `current_files` directory in the current location
- Find all files in the current directory and its subdirectories
- Move each file to the `current_files` directory
- Handle filename conflicts by creating unique names

## System Files Handled

The `git-clean-system-files.sh` script handles the following system files:

### macOS
- `.DS_Store` - Directory metadata files
- `.DS_Store?` - Variant metadata files
- `._*` - Resource fork metadata
- `.Spotlight-V100` - Spotlight metadata
- `.Trashes` - Trash folder metadata

### Windows
- `Thumbs.db` - Thumbnail cache
- `ehthumbs.db` - Enhanced thumbnail cache
- `desktop.ini` - Folder configuration

### Linux
- `.directory` - KDE directory metadata
- `*~` - Backup files

### Editors
- `.*.swp` - Vim swap files
- `.*.swo` - Vim backup swap files

## Sample Output

### git-clean-system-files.sh

```
🧹 Starting system files cleanup script...
📍 Working in git repository root: /Users/username/projects/myrepo
🔍 Finding and removing system files...
✅ All system files have been removed.
📝 .gitignore file already exists.
📝 Updating .gitignore with system file patterns...
✅ System files patterns added to .gitignore.
🔄 Adding changes to git...
💾 Committing changes...
🚀 Pushing changes to remote repository...
✨ All done! Repository cleaned and changes pushed.
```

### flatten_files.sh

```
Files have been moved to current_files directory
```

## Requirements

### git-clean-system-files.sh
- zsh (default shell on modern macOS)
- Git
- Write access to the repository

### flatten_files.sh
- zsh (default shell on modern macOS)
- Write access to the directory

## License

MIT

## Author

Joshua Michael Hall
contact@joshuamichaelhall.com
https://joshuamichaelhall.com

