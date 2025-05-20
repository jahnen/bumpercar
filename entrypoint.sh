#!/bin/bash
set -e

# Mark GitHub workspace as safe
git config --global --add safe.directory "$GITHUB_WORKSPACE"

echo "[bumpercar] Starting bumpercar..."

# 1. Resolve DESCRIPTION file path from input (default is DESCRIPTION)
DESC_PATH="${INPUT_PATH:-DESCRIPTION}"
echo "[bumpercar] Using DESCRIPTION path: $DESC_PATH"

# 2. Run the R script
Rscript /usr/local/bin/bumpercar.R "$DESC_PATH"

# 3. Check if DESCRIPTION was modified
if git diff --quiet "$DESC_PATH"; then
    echo "[bumpercar] No changes detected in $DESC_PATH. Exiting."
    exit 0
fi

# 4. Git identity setup
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

# 5. Create new branch
DATE=$(date +'%Y%m%d')
BRANCH="bumpercar/update-$DATE"
git checkout -b "$BRANCH"
git add "$DESC_PATH"
git commit -m "chore: update DESCRIPTION dependencies"
git push origin "$BRANCH"

# 6. Authenticate GitHub CLI using token
echo "[bumpercar] Authenticating with GitHub CLI..."
echo "$GITHUB_TOKEN" | gh auth login --with-token

# 7. Create pull request
echo "[bumpercar] Creating pull request..."
gh pr create \
    --title "Update DESCRIPTION dependencies" \
    --body "This PR updates the DESCRIPTION file to the latest compatible CRAN versions." \
    --head "$BRANCH" \
    --label dependencies

echo "[bumpercar] Pull request created successfully."
