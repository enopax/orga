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

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Enopax Project Setup${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Function to create directory if it doesn't exist
create_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} Creating directory: $(basename "$dir")"
        mkdir -p "$dir"
    else
        echo -e "${YELLOW}→${NC} Directory already exists: $(basename "$dir")"
    fi
}

# Function to create empty CLAUDE.md if it doesn't exist
create_claude_md() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Creating: $(basename "$(dirname "$file")")/CLAUDE.md"
        touch "$file"
    else
        echo -e "${YELLOW}→${NC} File already exists: $(basename "$(dirname "$file")")/CLAUDE.md"
    fi
}

# Function to create empty .repos if it doesn't exist
create_repos_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Creating: $(basename "$(dirname "$file")")/.repos"
        cat > "$file" << 'EOF'
# Repository configuration
# Format: <git_url> [folder_name]
# If folder_name is omitted, uses repository name from URL

EOF
    else
        echo -e "${YELLOW}→${NC} File already exists: $(basename "$(dirname "$file")")/.repos"
    fi
}

# Function to extract repository name from Git URL
extract_repo_name() {
    local url=$1
    # Extract repo name: git@github.com:user/repo.git -> repo
    # Remove .git suffix and extract last part after /
    basename "$url" .git
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
fi

echo -e "${BLUE}Found ${#PROJECTS[@]} project(s):${NC} ${PROJECTS[*]}\n"

# Step 1: Create .gitignore
echo -e "${BLUE}Step 1: Creating .gitignore${NC}\n"

GITIGNORE_FILE="$BASE_DIR/.gitignore"
echo -e "${GREEN}✓${NC} Generating .gitignore"

# Start with header
cat > "$GITIGNORE_FILE" << 'EOF'
# Enopax Project Structure
# This file ignores repository folders but tracks project structure files

EOF

# Add entries for each project
for project in "${PROJECTS[@]}"; do
    project_dir="$BASE_DIR/$project"
    repos_file="$project_dir/.repos"

    if [ -f "$repos_file" ]; then
        echo "# $project Project" >> "$GITIGNORE_FILE"

        # Read .repos file and extract folder names
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            # Parse: git_url [folder_name]
            read -r git_url folder_name <<< "$line"

            # Use repo name from URL if folder_name not provided
            if [ -z "$folder_name" ]; then
                folder_name=$(extract_repo_name "$git_url")
            fi

            if [ -n "$folder_name" ]; then
                echo "$project/$folder_name/" >> "$GITIGNORE_FILE"
            fi
        done < "$repos_file"

        echo "" >> "$GITIGNORE_FILE"
    fi
done

# Step 2: Ensure project directories exist
echo -e "\n${BLUE}Step 2: Creating project directories${NC}\n"

for project in "${PROJECTS[@]}"; do
    create_dir "$BASE_DIR/$project"
    create_claude_md "$BASE_DIR/$project/CLAUDE.md"
    create_repos_file "$BASE_DIR/$project/.repos"
done

# Step 3: Clone repositories
echo -e "\n${BLUE}Step 3: Cloning repositories${NC}\n"

for project in "${PROJECTS[@]}"; do
    project_dir="$BASE_DIR/$project"
    repos_file="$project_dir/.repos"

    echo -e "${BLUE}Project: $project${NC}"

    if [ ! -f "$repos_file" ]; then
        echo -e "${YELLOW}  No .repos file found, skipping${NC}\n"
        continue
    fi

    # Read .repos file and clone repositories
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

# Display the structure dynamically
for project in "${PROJECTS[@]}"; do
    project_dir="$BASE_DIR/$project"
    repos_file="$project_dir/.repos"

    echo -e "├── $project/"
    echo -e "│   ├── CLAUDE.md"
    echo -e "│   ├── .repos"

    if [ -f "$repos_file" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            read -r git_url folder_name <<< "$line"

            # Use repo name from URL if folder_name not provided
            if [ -z "$folder_name" ]; then
                folder_name=$(extract_repo_name "$git_url")
            fi

            if [ -n "$folder_name" ]; then
                echo -e "│   └── $folder_name/"
            fi
        done < "$repos_file"
    fi
done

echo ""
echo -e "${GREEN}✓${NC} Setup complete! Projects auto-discovered from directories with CLAUDE.md"
echo -e "${YELLOW}Tip:${NC} Edit <project>/.repos to add or modify repositories\n"
