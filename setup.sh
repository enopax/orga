#!/bin/bash

# Enopax Project Setup Script
# This script creates the Enopax project structure and clones all repositories
# Configuration is read from projects.json

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
CONFIG_FILE="$BASE_DIR/projects.json"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE} Project Setup${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo -e "Please install jq to parse JSON:"
    echo -e "  macOS: brew install jq"
    echo -e "  Linux: apt-get install jq or yum install jq"
    exit 1
fi

# Check if projects.json exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: projects.json not found${NC}"
    echo -e "Expected location: $CONFIG_FILE"
    exit 1
fi

echo -e "${BLUE}Reading configuration from projects.json${NC}\n"

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

# Step 1: Create .gitignore
echo -e "${BLUE}Step 1: Creating .gitignore${NC}\n"

GITIGNORE_FILE="$BASE_DIR/.gitignore"
if [ ! -f "$GITIGNORE_FILE" ]; then
    echo -e "${GREEN}✓${NC} Creating .gitignore"

    # Start with header
    cat > "$GITIGNORE_FILE" << 'EOF'
# Enopax Project Structure
# This file ignores all project folders but keeps CLAUDE.md files tracked

EOF

    # Add entries for each project from JSON
    jq -r '.projects[].name' "$CONFIG_FILE" | while read -r project; do
        echo "# ${project} Project" >> "$GITIGNORE_FILE"
        echo "${project}/" >> "$GITIGNORE_FILE"
        echo "!${project}/CLAUDE.md" >> "$GITIGNORE_FILE"
        echo "" >> "$GITIGNORE_FILE"
    done
else
    echo -e "${YELLOW}→${NC} .gitignore already exists"
fi

# Step 2: Create project directories
echo -e "\n${BLUE}Step 2: Creating project directories${NC}\n"

jq -r '.projects[].name' "$CONFIG_FILE" | while read -r project; do
    create_dir "$BASE_DIR/$project"
done

# Step 3: Create CLAUDE.md files
echo -e "\n${BLUE}Step 3: Creating CLAUDE.md files${NC}\n"

jq -r '.projects[].name' "$CONFIG_FILE" | while read -r project; do
    create_claude_md "$BASE_DIR/$project/CLAUDE.md"
done

# Step 4: Clone repositories
echo -e "\n${BLUE}Step 4: Cloning repositories${NC}\n"

# Parse JSON and clone repositories
jq -c '.projects[]' "$CONFIG_FILE" | while read -r project_obj; do
    project_name=$(echo "$project_obj" | jq -r '.name')

    echo -e "${BLUE}Project: $project_name${NC}"

    echo "$project_obj" | jq -c '.repositories[]' | while read -r repo_obj; do
        repo_name=$(echo "$repo_obj" | jq -r '.name')
        repo_url=$(echo "$repo_obj" | jq -r '.url')
        target_dir="$BASE_DIR/$project_name/$repo_name"

        clone_repo "$repo_url" "$target_dir" "$repo_name"
    done

    echo ""
done

# Summary
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Display the structure dynamically
jq -c '.projects[]' "$CONFIG_FILE" | while read -r project_obj; do
    project_name=$(echo "$project_obj" | jq -r '.name')
    repo_count=$(echo "$project_obj" | jq '.repositories | length')

    echo -e "├── $project_name/"
    echo -e "│   ├── CLAUDE.md"

    echo "$project_obj" | jq -c '.repositories[]' | while read -r repo_obj; do
        repo_name=$(echo "$repo_obj" | jq -r '.name')
        echo -e "│   └── $repo_name/"
    done
done

echo ""
echo -e "${GREEN}✓${NC} Setup complete! All projects configured from projects.json"
echo -e "${YELLOW}Tip:${NC} Edit projects.json to add or modify projects and repositories\n"
