#!/bin/bash
#
# Sets up copilot-config agents in sibling repositories.
# Creates symlinks from sibling repos' .github/agents folders to this repo's agents.
#
# Usage:
#   ./setup-agents.sh                    # Auto-discovers and links all sibling repos
#   ./setup-agents.sh docs-ui feature-gap-wt  # Links specific repos only
#   ./setup-agents.sh --dry-run          # Preview changes without applying
#   ./setup-agents.sh --force            # Replace existing agents folders

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_SOURCE="$SCRIPT_DIR/.github/agents"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

DRY_RUN=false
FORCE=false
TARGET_REPOS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --force) FORCE=true; shift ;;
        *) TARGET_REPOS+=("$1"); shift ;;
    esac
done

if [[ ! -d "$AGENTS_SOURCE" ]]; then
    echo "Error: Agents source not found: $AGENTS_SOURCE" >&2
    exit 1
fi

echo "Copilot Agents Setup"
echo "==================="
echo "Source: $AGENTS_SOURCE"
echo ""

# Discover sibling repos if none specified
if [[ ${#TARGET_REPOS[@]} -eq 0 ]]; then
    for dir in "$PARENT_DIR"/*/; do
        repo_name=$(basename "$dir")
        if [[ "$repo_name" != "copilot-config" && -d "$dir/.git" ]]; then
            TARGET_REPOS+=("$dir")
        fi
    done
fi

if [[ ${#TARGET_REPOS[@]} -eq 0 ]]; then
    echo "No sibling repos found."
    exit 0
fi

echo "Found ${#TARGET_REPOS[@]} repos to configure:"
for repo in "${TARGET_REPOS[@]}"; do
    echo "  - $(basename "$repo")"
done
echo ""

created=0
skipped=0
errors=0

for repo in "${TARGET_REPOS[@]}"; do
    # Handle relative paths
    if [[ ! "$repo" = /* ]]; then
        repo="$PARENT_DIR/$repo"
    fi
    
    repo_name=$(basename "$repo")
    github_dir="$repo/.github"
    agents_target="$github_dir/agents"
    
    printf "[$repo_name] "
    
    # Ensure .github exists
    if [[ ! -d "$github_dir" ]]; then
        if $DRY_RUN; then
            echo -n "(would create .github) "
        else
            mkdir -p "$github_dir"
        fi
    fi
    
    # Check if agents folder already exists
    if [[ -e "$agents_target" || -L "$agents_target" ]]; then
        # Already a symlink pointing to our agents?
        if [[ -L "$agents_target" ]]; then
            link_target=$(readlink "$agents_target")
            if [[ "$link_target" == "$AGENTS_SOURCE" ]]; then
                echo "Already linked"
                ((skipped++))
                continue
            fi
        fi
        
        # Has content - don't overwrite unless forced
        if ! $FORCE; then
            existing_count=$(find "$agents_target" -name "*.agent.md" 2>/dev/null | wc -l)
            if [[ $existing_count -gt 0 ]]; then
                echo "Has existing agents ($existing_count files) - use --force to replace"
                ((skipped++))
                continue
            fi
        fi
        
        # Remove existing folder
        if $DRY_RUN; then
            echo -n "(would remove existing) "
        else
            rm -rf "$agents_target"
        fi
    fi
    
    # Create symlink
    if $DRY_RUN; then
        echo "Would create symlink"
        ((created++))
    else
        if ln -s "$AGENTS_SOURCE" "$agents_target" 2>/dev/null; then
            echo "Symlink created"
            ((created++))
        else
            echo "Failed"
            ((errors++))
        fi
    fi
done

echo ""
echo "Summary: $created created, $skipped skipped, $errors errors"

if $DRY_RUN; then
    echo "(Dry run - no changes made)"
fi
