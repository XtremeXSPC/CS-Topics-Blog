#!/usr/bin/env zsh

set -euo pipefail
trap 'error_exit "An unexpected error occurred. Check the log for details."' ERR

# ======================================================= #
# Function to show script usage

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  generate_file_hashes      Generate hashes for files in the destination directory"
    echo "  initialize_git            Initialize Git repository"
    echo "  sync_posts                Sync posts from source to destination"
    echo "  update_frontmatter        Update frontmatter in destination directory"
    echo "  process_markdown          Process Markdown files with images.py"
    echo "  build_hugo_site           Build the Hugo site"
    echo "  stage_and_commit_changes  Stage and commit changes in Git"
    echo "  push_to_main              Push changes to the main branch on GitHub"
    echo "  deploy_to_hostinger       Deploy the public folder to the hostinger branch"
    echo "  help                      Show this help message"
    exit 1
}

# ======================================================= #
# Logging

log() {
    echo "[INFO] $1"
}

# ======================================================= #
# Error handling

error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# ======================================================= #
# Check if a command exists

check_command() {
    local cmd=$1
    if ! command -v "$cmd" &>/dev/null; then
        error_exit "$cmd is not installed or not in PATH. Install it and try again."
    fi
}

# ======================================================= #
# Check if a directory exists

check_dir() {
    local dir=$1
    local type=$2
    if [ ! -d "$dir" ]; then
        error_exit "$type directory does not exist: $dir"
    fi
}

# ======================================================= #
# Initialize the Git repository

initialize_git() {
    log "Changing to repository directory: $repo_path"
    cd "$repo_path" || error_exit "Failed to change directory to $repo_path"
    if [ ! -d ".git" ]; then
        log "Initializing Git repository..."
        git init
        git remote add origin "$myrepo"
    else
        log "Git repository already initialized."
        if ! git remote get-url origin &>/dev/null; then
            log "Adding remote origin..."
            git remote add origin "$myrepo"
        fi
    fi
}

# ======================================================= #
# Sync posts from source to destination

sync_posts() {
    log "Syncing posts from source to destination..."
    check_dir "$sourcePath" "Source"
    check_dir "$destinationPath" "Destination"
    rsync -av --delete "${sourcePath}/" "${destinationPath}/"
}

# ======================================================= #
# Get the creation date of a file

get_creation_date() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        stat -f "%Sm" -t "%Y-%m-%d" "$1"
    else
        # Linux
        stat --format="%w" "$1" | awk '{print $1}'
    fi
}

# ======================================================= #
# Find an image file in the source directory

find_image() {
    local post_name="$1"
    find "$sourcePath" -type f -regex ".*/${post_name}\..*" | head -n 1
}

# ======================================================= #
# Generate hashes for files in the destination directory

generate_file_hashes() {
    log "Generating file hashes for destination directory: $destinationPath"
    check_command python3
    if [ ! -f "$hash_generator_script" ]; then
        error_exit "Hash generator script not found at $hash_generator_script"
    fi

    # Trova i file Markdown
    log "Finding Markdown files in $destinationPath"
    local files_to_hash
    files_to_hash=$(find "$destinationPath" -type f -name "*.md")

    if [ -z "$files_to_hash" ]; then
        error_exit "No Markdown files found in the destination directory."
    fi

    # Inizializza il file degli hash
    log "Writing hashes to $hash_file"
    > "$hash_file" || error_exit "Cannot write to $hash_file"

    for file in $files_to_hash; do
        log "Processing file: $file"
        python3 "$hash_generator_script" "$file" >> "$hash_file" 2>>error.log
        if [ $? -ne 0 ]; then
            error_exit "Failed to process $file. Check error.log for details."
        fi
    done

    log "File hashes successfully generated and saved to $hash_file"
}

# ======================================================= #
# Main logic for updating frontmatter (example placeholder)

update_frontmatter() {
    log "Updating frontmatter for files in $destinationPath"

    # Load hashes into an associative array
    typeset -A file_hashes
    if [[ -f "$hash_file" ]]; then
        while IFS=$'\t' read -r file hash; do
            file_hashes["$file"]=$hash
        done < "$hash_file"
    fi

    # Process each Markdown file in the destination directory
    local files_to_process
    files_to_process=$(find "$destinationPath" -type f -name "*.md")
    for file in $files_to_process; do
        local current_hash
        current_hash=$(python3 "$hash_generator_script" "$file" | awk '{print $2}')

        if [[ "${file_hashes[$file]}" != "$current_hash" ]]; then
            log "File $file has changed. Updating frontmatter..."
            # Here you would call a Python or Bash script to update the frontmatter
            # e.g., python3 update_frontmatter.py "$file"
            file_hashes["$file"]=$current_hash
        else
            log "File $file is up-to-date. Skipping."
        fi
    done

    # Write updated hashes back to the hash file
    > "$hash_file"
    for file in ${(k)file_hashes}; do
        echo -e "$file\t${file_hashes[$file]}" >> "$hash_file"
    done

    log "Frontmatter update completed."
}

# ======================================================= #
# Process Markdown files with images.py

process_markdown() {
    log "Processing Markdown files with images.py..."
    if [ ! -f "$images_script" ]; then
        error_exit "Python script images.py not found."
    fi
    python3 "$images_script"
}

# ======================================================= #
# Build the Hugo site

build_hugo_site() {
    log "Building the Hugo site..."
    if ! hugo --source "$blog_dir"; then
        error_exit "Hugo build failed."
    fi
    if [ ! -d "$blog_dir/public" ]; then
        error_exit "Hugo build completed, but 'public' directory was not created."
    fi
}

# ======================================================= #
# Stage and commit changes in Git

stage_and_commit_changes() {
    log "Staging changes for Git..."
    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        log "No changes to stage or commit."
    else
        git add .
        local commit_message="New Blog Post on $(date +'%Y-%m-%d %H:%M:%S')"
        log "Committing changes with message: $commit_message"
        git commit -m "$commit_message"
    fi
}

# ======================================================= #
# Push changes to the main branch on GitHub

push_to_main() {
    log "Pushing changes to the main branch on GitHub..."
    if git rev-parse --verify main &>/dev/null; then
        git checkout main
    else
        error_exit "Main branch does not exist locally."
    fi

    git push origin main
}

# ======================================================= #
# Deploy the public folder to the hostinger branch

deploy_to_hostinger() {
    log "Deploying the public folder to the hostinger branch..."
    if git rev-parse --verify hostinger-deploy &>/dev/null; then
        git branch -D hostinger-deploy
    fi

    git subtree split --prefix "CS-Topics/public" -b hostinger-deploy
    git push origin hostinger-deploy:hostinger --force
    git branch -D hostinger-deploy
}

# ======================================================= #
# Project variables

blog_dir="${BLOG_DIR:-$HOME/04_LCS.Blog/CS-Topics}"
sourcePath="${SOURCE_PATH:-$HOME/Documents/Obsidian-Vault/XSPC-Vault/Blog/posts}"
blog_images="${BLOG_IMAGES:-$HOME/Documents/Obsidian-Vault/XSPC-Vault/Blog/images}"
destinationPath="${DESTINATION_PATH:-$HOME/04_LCS.Blog/CS-Topics/content/posts}"
images_script="${IMAGES_SCRIPT_PATH:-$HOME/04_LCS.Blog/Automatic-Updates/images.py}"
hash_file=".file_hashes"

# Percorso dello script Python per la generazione degli hash
hash_generator_script="${HASH_GENERATOR_SCRIPT:-$HOME/04_LCS.Blog/Automatic-Updates/generate_hashes.py}"

# ======================================================= #
# GitHub repository variables

repo_path="${REPO_PATH:-/Users/lcs-dev/04_LCS.Blog}"
myrepo="${MY_REPO:-git@github.com:XtremeXSPC/LCS.Dev-Blog.git}"
logFile="./script.log"

# ======================================================= #
# Load hashes from the hash_file

typeset -A file_hashes

if [[ -f "$hash_file" ]]; then
    while IFS=$'\t' read -r file hash; do
        file_hashes["$file"]=$hash
    done < "$hash_file"
fi

# Aggiungi log per verificare il caricamento degli hash
log "Loaded file hashes:"
for key in ${(k)file_hashes}; do
    log "$key: ${file_hashes[$key]}"
done

# ======================================================= #
# Parse arguments and call functions

if [[ $# -gt 0 ]]; then
    case "$1" in
        generate_file_hashes|initialize_git|sync_posts|update_frontmatter|process_markdown|build_hugo_site|stage_and_commit_changes|push_to_main|deploy_to_hostinger)
            "$1"
            exit 0
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown command '$1'"
            usage
            ;;
    esac
fi

# ======================================================= #
# Execute main logic if no arguments are provided

# Logging
exec > >(tee -a "$logFile") 2>&1

log "Starting script..."

for cmd in git rsync python3 hugo; do
    check_command "$cmd"
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || error_exit "Failed to change to script directory"

initialize_git
sync_posts
update_frontmatter
process_markdown
build_hugo_site
stage_and_commit_changes
push_to_main
deploy_to_hostinger

# ======================================================= #
# Log and exit
log "All done! Site synced, processed, committed, built, and deployed successfully."
