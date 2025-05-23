#!/bin/bash
set -e

# Mark GitHub workspace as safe (required for actions in GitHub runners)
git config --global --add safe.directory "$GITHUB_WORKSPACE"
git config --global --add safe.directory /github/workspace

echo "[bumpercar] Starting bumpercar..."

# Set the path to the DESCRIPTION file
DESC_PATH="${INPUT_PATH:-DESCRIPTION}"
echo "[bumpercar] Using DESCRIPTION file at: $DESC_PATH"

# Update dependencies in DESCRIPTION using bumpercar R script
Rscript /usr/local/bin/bumpercar.R "$DESC_PATH"

# Check if the DESCRIPTION file was modified; exit if not
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git diff --quiet "$DESC_PATH"; then
        echo "[bumpercar] No changes detected. Exiting."
        exit 0
    fi
else
    echo "[bumpercar] Not inside a Git repository. Exiting."
    exit 1
fi

# ---------------------------------------------------------
# Compatibility check (build and test the updated package)
# ---------------------------------------------------------

# Install dependencies via pak
echo "[bumpercar] Installing dependencies via pak..."
Rscript -e "install.packages('pak', repos='https://cran.rstudio.com'); pak::pkg_install('local::./', dependencies = TRUE)"

# Build the package
echo "[bumpercar] Building the package..."
R CMD build .

### TO TEST R CMD check failed, comment R CMD build .

# Find the latest built tar.gz file
TARBALL=$(ls -t *.tar.gz | head -n 1)
echo "[bumpercar] Found built package: $TARBALL"

# Extract changed packages and versions (before commit)
UPDATED_PKGS=$(git diff "$DESC_PATH" | grep -E '^\+\s{4,}' | grep -Ev '^\+\+\+')

# Run R CMD check on the built tar.gz file
echo "[bumpercar] Running R CMD check..."
R CMD check "$TARBALL" >bumpercar_check.log 2>&1 || {
    echo "[bumpercar] ❌ R CMD check failed. Showing bumpercar_check.log below:"
    cat bumpercar_check.log
    CHECKDIR="${TARBALL%.tar.gz}.Rcheck"
    if [ -f "$CHECKDIR/00check.log" ]; then
        echo "[bumpercar] ==== 00check.log ===="
        cat "$CHECKDIR/00check.log"
    fi

    # Create GitHub Issue on failure
    if [ -n "$GITHUB_REPOSITORY" ] && command -v gh >/dev/null 2>&1; then
        # Create 'bumpercar' label if it does not exist
        if ! gh label list --repo "$GITHUB_REPOSITORY" | grep -q '^bumpercar'; then
            gh label create bumpercar --color cc5b72 --description "R CMD check failed: Compatibility issue detected by bumpercar" --repo "$GITHUB_REPOSITORY"
        fi
        echo "[bumpercar] Creating GitHub Issue for R CMD check failure..."

        # Use the UPDATED_PKGS variable saved before commit
        ISSUE_BODY=$(
            cat <<EOF
R CMD check failed with updated package on branch \`$GITHUB_REF\`.

### Updated packages and versions:
\`\`\`
$UPDATED_PKGS
\`\`\`

See below for the error log:

\`\`\`
$(tail -n 50 bumpercar_check.log)
\`\`\`
EOF
        )

        gh issue create \
            --title "R CMD check failed in bumpercar" \
            --body "$ISSUE_BODY" \
            --label "bumpercar" \
            --repo "$GITHUB_REPOSITORY"
    fi

    exit 1
}
echo "[bumpercar] ✅ R CMD check passed."

# Configure git user identity for commits
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Create a new branch for the update and commit the changes
DATE=$(date +'%Y%m%d')
BRANCH="bumpercar/update-$DATE"
git checkout -b "$BRANCH"
git add "$DESC_PATH"
git commit -m "chore: update DESCRIPTION dependencies"
git push origin "$BRANCH"

# Authenticate GitHub CLI with GITHUB_TOKEN
export GITHUB_TOKEN="$GITHUB_TOKEN"

# Updated packages and versions
UPDATED_PKGS=$(git diff HEAD~1 "$DESC_PATH" | grep '^+' | grep -Ev '^\+\+\+|^+\s*$' | sed 's/^+//')

PR_BODY="This PR updates the DESCRIPTION file to the latest compatible CRAN versions and has passed R CMD check.

### Updated packages and versions:
\`\`\`
$UPDATED_PKGS
\`\`\`
"

# Ensure the 'dependencies' label exists in the repository
if ! gh label list --repo "$GITHUB_REPOSITORY" | grep -q '^dependencies'; then
    gh label create dependencies --color 0366d6 --description "Pull requests that update a dependency file" --repo "$GITHUB_REPOSITORY"
fi

# Check if a pull request for this branch already exists
EXISTING_PR=$(gh pr list --head "$BRANCH" --state open --json number --repo "$GITHUB_REPOSITORY" | jq length)

# Create the pull request if it does not already exist
if [ "$EXISTING_PR" -eq 0 ]; then
    echo "[bumpercar] Creating pull request..."
    if gh pr create \
        --title "Update DESCRIPTION dependencies" \
        --body "$PR_BODY" \
        --head "$BRANCH" \
        --base "main" \
        --label dependencies \
        --repo "$GITHUB_REPOSITORY"; then
        echo "[bumpercar] ✅ Pull request created successfully."
    else
        echo "[bumpercar] ❌ Failed to create pull request."
        gh pr status --repo "$GITHUB_REPOSITORY"
        exit 1
    fi
else
    echo "[bumpercar] 🚫 Pull request already exists for branch: $BRANCH"
fi
