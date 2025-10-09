#!/bin/bash

# Enopax Project Setup Script
# This script discovers projects and clones their repositories
# Each project folder should contain CLAUDE.md and .repos files

# Note: We don't use 'set -e' to allow the script to continue if git clone fails

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"
GITIGNORE_FILE="$BASE_DIR/.gitignore"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Enopax Project Setup${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Function to extract repository name from Git URL
extract_repo_name() {
    local url=$1
    # Extract repo name: git@github.com:user/repo.git -> repo
    basename "$url" .git
}

# Function to add entry to .gitignore if not already present
add_to_gitignore() {
    local entry=$1

    # Create .gitignore if it doesn't exist
    if [ ! -f "$GITIGNORE_FILE" ]; then
        cat > "$GITIGNORE_FILE" << 'EOF'
# Enopax Project Structure
# Repository folders are ignored

EOF
    fi

    # Check if entry already exists
    if ! grep -qxF "$entry" "$GITIGNORE_FILE"; then
        echo "$entry" >> "$GITIGNORE_FILE"
        echo -e "${GREEN}✓${NC} Added to .gitignore: $entry"
    fi
}

# Function to clone repository if it doesn't exist
clone_repo() {
    local repo_url=$1
    local target_dir=$2
    local repo_name=$3

    if [ ! -d "$target_dir/.git" ]; then
        echo -e "${GREEN}✓${NC} Cloning $repo_name..."
        if git clone "$repo_url" "$target_dir" 2>&1; then
            echo -e "${GREEN}✓${NC} Successfully cloned: $repo_name"
        else
            echo -e "${RED}✗${NC} Failed to clone: $repo_name (continuing...)"
            return 1
        fi
    else
        echo -e "${YELLOW}→${NC} Repository already cloned: $repo_name"
    fi
}

echo -e "${BLUE}Discovering projects...${NC}\n"

# Find all directories with CLAUDE.md (these are project folders)
PROJECTS=()
for dir in "$BASE_DIR"/*/ ; do
    if [ -f "${dir}CLAUDE.md" ]; then
        project_name=$(basename "$dir")
        # Skip hidden directories
        if [[ ! "$project_name" =~ ^\. ]]; then
            PROJECTS+=("$project_name")
        fi
    fi
done

if [ ${#PROJECTS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No projects found (directories with CLAUDE.md)${NC}"
    echo -e "${YELLOW}Create a directory with CLAUDE.md and .repos to define a project${NC}\n"
    exit 0
fi

echo -e "${BLUE}Found ${#PROJECTS[@]} project(s):${NC} ${PROJECTS[*]}\n"

# Step 1: Update .gitignore and clone repositories
echo -e "${BLUE}Processing projects...${NC}\n"

for project in "${PROJECTS[@]}"; do
    project_dir="$BASE_DIR/$project"
    repos_file="$project_dir/.repos"

    echo -e "${BLUE}Project: $project${NC}"

    # Create .repos file if it doesn't exist
    if [ ! -f "$repos_file" ]; then
        echo -e "${YELLOW}→${NC} No .repos file, creating empty one"
        cat > "$repos_file" << 'EOF'
# Repository configuration
# Format: <git_url> [folder_name]
# If folder_name is omitted, uses repository name from URL

EOF
        echo ""
        continue
    fi

    # Read .repos file and process repositories
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse: git_url [folder_name]
        read -r git_url folder_name <<< "$line"

        # Use repo name from URL if folder_name not provided
        if [ -z "$folder_name" ]; then
            folder_name=$(extract_repo_name "$git_url")
        fi

        if [ -n "$git_url" ] && [ -n "$folder_name" ]; then
            # Add to .gitignore
            add_to_gitignore "$project/$folder_name/"

            # Clone repository
            target_dir="$project_dir/$folder_name"
            clone_repo "$git_url" "$target_dir" "$folder_name"
        fi
    done < "$repos_file"

    echo ""
done

# Summary
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}=====================================${NC}\n"

echo -e "${GREEN}✓${NC} Projects discovered and repositories cloned"
echo -e "${YELLOW}Tip:${NC} Edit <project>/.repos to add or modify repositories\n"
