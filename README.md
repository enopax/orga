# Enopax Project Structure

This repository manages the Enopax organisation's project structure using auto-discovery and distributed configuration.

## Quick Start

```bash
./setup.sh
```

This will:
1. Auto-discover all projects (folders with `.repos` files)
2. Generate `.gitignore` based on discovered repositories
3. Clone all configured repositories from each project's `.repos` file

## How It Works

### Convention over Configuration

**No central config file needed!** The script automatically discovers projects by scanning for directories containing a `.repos` file.

### Project Structure

```
enopax/
├── setup.sh              # Setup script
├── .gitignore            # Auto-generated
├── CLAUDE.md             # Organisation overview
├── Platform/
│   ├── CLAUDE.md         # Project documentation
│   ├── .repos            # Repository configuration (marks this as a project)
│   └── platform/         # Cloned repository
├── ResourceAPI/
│   ├── CLAUDE.md         # Project documentation
│   ├── .repos            # Repository configuration (marks this as a project)
│   ├── resource-api/
│   └── resource-api-frontend/
└── ...
```

## Configuration

Each project manages its own repositories via a `.repos` file.

**Format:** `<git_url> <folder_name>` (space-separated)

### Example `.repos` file:

```
# Repository configuration
# Format: <git_url> <folder_name>

git@github.com:enopax/platform.git platform
git@github.com:enopax/other-repo.git custom-folder
```

## Adding a New Project

```bash
# 1. Create project directory
mkdir NewProject

# 2. Create .repos file (marks it as a project)
cat > NewProject/.repos << 'EOF'
# Repository configuration
# Format: <git_url> <folder_name>

git@github.com:enopax/new-repo.git repo-name
EOF

# 3. (Optional) Create CLAUDE.md for documentation
echo "# NewProject" > NewProject/CLAUDE.md

# 4. Run setup
./setup.sh
```

## Adding a Repository to Existing Project

```bash
# Edit the project's .repos file
echo "git@github.com:enopax/another-repo.git another-folder" >> Platform/.repos

# Run setup
./setup.sh
```

## Git Tracking

- ✅ Tracked: `setup.sh`, `CLAUDE.md`, `README.md`
- ✅ Tracked: `<Project>/CLAUDE.md` files
- ✅ Tracked: `<Project>/.repos` files
- ❌ Ignored: All repository contents (auto-generated in `.gitignore`)

## Requirements

- **bash**: Available on macOS and Linux
- **git**: For cloning repositories
- **SSH keys**: Configured for GitHub access

**Note:** No `jq` or JSON parsing required!

## Features

✅ **Auto-discovery** - Projects found automatically (folders with `.repos` files)
✅ **Distributed config** - Each project manages its own `.repos` file
✅ **No central config** - No `projects.json` to maintain
✅ **Simple format** - Space-separated text, no JSON
✅ **Idempotent** - Safe to run multiple times
✅ **Incremental .gitignore** - Updates without overwriting manual edits
✅ **Works from anywhere** - Portable, no hardcoded paths

## Workflow

### Initial Setup (New Machine)

```bash
git clone git@github.com:enopax/orga.git enopax
cd enopax
./setup.sh
```

### Syncing Changes

```bash
git pull
./setup.sh  # Discovers new projects and clones repos
```

### Adding a Project

```bash
mkdir MyProject
cat > MyProject/.repos << 'EOF'
git@github.com:enopax/my-repo.git my-repo
EOF

./setup.sh

git add MyProject/.repos
git commit -m "feat: add MyProject"
git push
```

## How Discovery Works

The script scans for directories containing `.repos`:
- Finds: `Platform/.repos` → Project: Platform
- Finds: `ResourceAPI/.repos` → Project: ResourceAPI
- Skips: `docs/` (no .repos file)
- Skips: `.git/` (hidden directory)

## Customisation

The script automatically:
- Discovers projects (folders with `.repos` files)
- Reads each project's `.repos` file
- Clones repositories only if they don't exist
- Updates `.gitignore` incrementally with repository paths
- Only processes projects that have a `.repos` file

## Notes

- **Project marker**: A folder must have `.repos` file to be considered a project
- **SSH URLs**: Use `git@github.com:user/repo.git` format
- **Custom names**: Second parameter in `.repos` allows custom folder names (optional)
- **Comments**: Lines starting with `#` in `.repos` are ignored
- **Empty lines**: Ignored in `.repos` files
- **No jq**: Pure bash, no external JSON parsers needed
- **No .repos creation**: Script does not create `.repos` files, only discovers existing ones

## Troubleshooting

### Project not discovered?
- Ensure folder has `.repos` file
- Check folder is not hidden (doesn't start with `.`)

### Repository not cloning?
- Check `.repos` file exists and has correct format
- Verify SSH keys are configured: `ssh -T git@github.com`
- Check URL format: `<git_url> <folder_name>`

### .gitignore not updating?
- Run `./setup.sh` - it updates incrementally on every run
- Check `.repos` files are formatted correctly

---

*This setup uses convention over configuration - folders with `.repos` files are automatically discovered as projects!*
