#!/bin/bash
set -e

echo "[bumpercar] Running bumpercar to update DESCRIPTION..."

# 1. Run the R script to update DESCRIPTION
Rscript /usr/local/bin/bumpercar.R

# 2. Check for changes in DESCRIPTION
if git diff --quiet DESCRIPTION; then
    echo "[bumpercar] No changes to DESCRIPTION. Exiting."
    exit 0
fi

# 3. Git identity setup
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

# 4. Create new branch
DATE=$(date +'%Y%m%d')
BRANCH="bumpercar/update-$DATE"
git checkout -b "$BRANCH"
git add DESCRIPTION
git commit -m "chore: update DESCRIPTION dependencies"
git push origin "$BRANCH"

# 5. Authenticate GitHub CLI (assumes GITHUB_TOKEN is available)
echo "[bumpercar] Creating pull request..."

gh auth login --with-token <<<"$GITHUB_TOKEN"
gh pr create \
    --title "Update DESCRIPTION dependencies" \
    --body "This PR updates the DESCRIPTION file to the latest compatible CRAN versions." \
    --head "$BRANCH" \
    --label dependencies

echo "[bumpercar] Pull request created successfully."
