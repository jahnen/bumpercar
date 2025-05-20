#!/bin/bash
set -e

echo "[bumpercar] Starting bumpercar..."

# 0. Mark the GitHub workspace as a safe Git directory
git config --global --add safe.directory /github/workspace

# 1. Set the path to the DESCRIPTION file
DESC_PATH="${INPUT_PATH:-DESCRIPTION}"
echo "[bumpercar] Using DESCRIPTION file at: $DESC_PATH"

# 2. Run the bumpercar R script to update dependencies
Rscript /usr/local/bin/bumpercar.R "$DESC_PATH"

# 3. Check if the DESCRIPTION file was modified
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git diff --quiet "$DESC_PATH"; then
        echo "[bumpercar] No changes detected. Exiting."
        exit 0
    fi
else
    echo "[bumpercar] Not inside a Git repository. Exiting."
    exit 1
fi

# 4. Configure Git user identity
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

# 5. Create a new branch and commit the changes
DATE=$(date +'%Y%m%d')
BRANCH="bumpercar/update-$DATE"
git checkout -b "$BRANCH"
git add "$DESC_PATH"
git commit -m "chore: update DESCRIPTION dependencies"
git push origin "$BRANCH"

# 6. Authenticate GitHub CLI with GITHUB_TOKEN
echo "$GITHUB_TOKEN" | gh auth login --with-token

# 7. Create a pull request
echo "[bumpercar] Creating pull request..."
gh pr create \
    --title "Update DESCRIPTION dependencies" \
    --body "This PR updates the DESCRIPTION file to the latest compatible CRAN versions." \
    --head "$BRANCH" \
    --base "main" \
    --label dependencies \
    --repo "$GITHUB_REPOSITORY"

echo "[bumpercar] ✅ Pull request created successfully."
