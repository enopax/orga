# Enopax Project Structure

This repository manages the Enopax organisation's project structure using a configuration-driven approach.

## Quick Start

```bash
./setup.sh
```

This will:
1. Create `.gitignore` based on projects in `projects.json`
2. Create project directories
3. Create empty `CLAUDE.md` files in each project folder
4. Clone all configured repositories

## Configuration

All projects and repositories are defined in `projects.json`:

```json
{
  "projects": [
    {
      "name": "Platform",
      "repositories": [
        {
          "name": "platform",
          "url": "https://github.com/enopax/platform.git"
        }
      ]
    }
  ]
}
```

### Adding a New Project

1. Edit `projects.json`
2. Add a new project object:
```json
{
  "name": "NewProject",
  "repositories": [
    {
      "name": "repo-name",
      "url": "https://github.com/enopax/repo-name.git"
    }
  ]
}
```
3. Run `./setup.sh`

### Adding a Repository to Existing Project

1. Edit `projects.json`
2. Add a repository to the project's `repositories` array
3. Run `./setup.sh`

## Structure

```
enopax/
├── projects.json          # Configuration file
├── setup.sh              # Setup script
├── .gitignore            # Auto-generated from projects.json
├── CLAUDE.md             # Organisation overview
├── Platform/
│   ├── CLAUDE.md         # Project-specific documentation
│   └── platform/         # Repository (ignored by git)
├── ResourceAPI/
│   ├── CLAUDE.md
│   ├── resource-api/
│   └── resource-api-frontend/
└── ...
```

## Git Tracking

- ✅ Tracked: `projects.json`, `setup.sh`, `CLAUDE.md`, `README.md`
- ✅ Tracked: `ProjectName/CLAUDE.md` files
- ❌ Ignored: All repository contents (defined in `.gitignore`)

## Requirements

- **bash**: Available on macOS and Linux
- **jq**: JSON parser
  - macOS: `brew install jq`
  - Linux: `apt-get install jq` or `yum install jq`
- **git**: For cloning repositories

## Features

- ✅ Configuration-driven (no hardcoded values)
- ✅ Idempotent (safe to run multiple times)
- ✅ Automatic `.gitignore` generation
- ✅ Colored output with status indicators
- ✅ Dynamic directory structure display
- ✅ Works from any directory

## Workflow

### Initial Setup (New Machine)
```bash
git clone <this-repo-url> enopax
cd enopax
./setup.sh
```

### Adding a New Project
```bash
# Edit projects.json to add new project
./setup.sh
git add projects.json
git commit -m "feat: add NewProject configuration"
git push
```

### Syncing Changes
```bash
git pull
./setup.sh  # Sets up any new projects/repos
```

## Customisation

The script automatically:
- Detects its own location (works from anywhere)
- Creates project folders
- Creates empty CLAUDE.md files (content managed separately)
- Clones repositories only if they don't exist
- Generates `.gitignore` based on configuration

## Notes

- Repository URLs in `projects.json` can be HTTPS or SSH
- The script preserves existing repositories and files
- CLAUDE.md files are created empty - add content as needed
- Each project can have multiple repositories
