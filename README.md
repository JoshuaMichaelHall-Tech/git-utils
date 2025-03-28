# System Files Cleanup Script

A zsh script to remove common system files from your Git repository, update your `.gitignore` to prevent them from being tracked in the future, and commit these changes.

## Problem

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

## Solution

This script:
1. Removes all existing system files from your repository
2. Creates a `.gitignore` file if it doesn't exist
3. Adds common system files patterns to the `.gitignore`
4. Commits and pushes these changes

## Installation

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

## Usage

Run the script from anywhere within a Git repository:

```zsh
./git-clean-system-files.sh
```

Or if you moved it to your PATH:

```zsh
git-clean-system-files
```

## What It Does

The script will:
- Check if you're in a Git repository
- Find and delete common system files
- Create a `.gitignore` file if one doesn't exist
- Add system file patterns to `.gitignore`
- Commit and push the changes

## System Files Handled

The script handles the following system files:

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

## Requirements

- zsh (default shell on modern macOS)
- Git
- Write access to the repository

## License

MIT

## Author

YOUR NAME HERE
