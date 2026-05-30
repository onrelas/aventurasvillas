#!/bin/bash

# Script purpose: Prepare an approved blog article for publishing to the Aventuras Villas blog.
# This script automates Git staging operations with strict safety rules, stopping before commit/push.

set -e # Exit immediately if a command exits with a non-zero status.

REPO_ROOT="/home/admintest/.openclaw/workspace/aventurasvillas"
APPROVED_DRAFT_PATH="$1"
PUBLISHED_ARTICLE_PATH="$2"

# --- Argument Validation ---
if [ -z "$APPROVED_DRAFT_PATH" ] || [ -z "$PUBLISHED_ARTICLE_PATH" ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <approved_draft_path> <published_article_path>"
    exit 1
fi

# --- 1. cd to /home/admintest/.openclaw/workspace/aventurasvillas ---
cd "$REPO_ROOT" || { echo "Error: Could not change directory to $REPO_ROOT"; exit 1; }
echo "# Current working directory: $(pwd)"

# --- 2. Verify the approved draft exists ---
if [ ! -f "$APPROVED_DRAFT_PATH" ]; then
    echo "Error: Approved draft file not found at $APPROVED_DRAFT_PATH"
    exit 1
fi
echo "# Approved draft found: $APPROVED_DRAFT_PATH"

# --- 3. Verify the published article path is inside blog/posts/ ---
if [[ "$PUBLISHED_ARTICLE_PATH" != blog/posts/* ]]; then
    echo "Error: Published article path must be inside 'blog/posts/'."
    exit 1
fi
echo "# Published article path is valid: $PUBLISHED_ARTICLE_PATH"

# --- Get initial status for index.html check ---
# Check if blog/index.html is already modified before we touch it
INITIAL_INDEX_STATUS=$(git status --short blog/index.html | grep -E "^ M |^M ")
INDEX_WAS_MODIFIED=false
if [ -n "$INITIAL_INDEX_STATUS" ]; then
    INDEX_WAS_MODIFIED=true
fi
echo "# Initial blog/index.html status (Modified): $INDEX_WAS_MODIFIED"

# --- 4. Copy approved draft to published article path ---
cp "$APPROVED_DRAFT_PATH" "$PUBLISHED_ARTICLE_PATH" || { echo "Error: Failed to copy draft to published path."; exit 1; }
echo "# Draft copied to: $PUBLISHED_ARTICLE_PATH"

# --- 5. Restore blog/automation/state.json if modified ---
if git status --short | grep -q "M blog/automation/state.json"; then
    echo "# Restoring blog/automation/state.json"
    git restore blog/automation/state.json || { echo "Error: Failed to restore blog/automation/state.json"; exit 1; }
else
    echo "# blog/automation/state.json is clean or untracked."
fi

# --- Stage only the published article path and potentially index.html ---
git add "$PUBLISHED_ARTICLE_PATH" || { echo "Error: Failed to stage $PUBLISHED_ARTICLE_PATH"; exit 1; }
echo "# Staged: $PUBLISHED_ARTICLE_PATH"

# Stage blog/index.html only if it's currently modified (and not automation/draft)
# The rule states: "stage blog/index.html only if already modified BEFORE the script stages files"
# We captured INITIAL_INDEX_STATUS. If it was modified and related to the new article, it should be staged.
CURRENT_INDEX_STATUS=$(git status --short blog/index.html | grep -E "^ M |^M ")
if [ "$INDEX_WAS_MODIFIED" = true ]; then
    # Ensure it's not actually an automation or draft file mistakenly named index.html
    if [[ "$PUBLISHED_ARTICLE_PATH" != blog/index.html ]] && [[ "$PUBLISHED_ARTICLE_PATH" != blog/automation/* ]] && [[ "$PUBLISHED_ARTICLE_PATH" != blog/drafts/* ]]; then
        echo "# Staging blog/index.html as it is modified."
        git add blog/index.html || { echo "Error: Failed to stage blog/index.html"; exit 1; }
    fi
else
    echo "# blog/index.html is not modified, skipping staging."
fi

# --- 8. Print staged files before commit ---
echo "# --- Staged Files Before Commit ---"
STAGED_FILES=$(git diff --name-only --cached)
echo "$STAGED_FILES"
echo "# ----------------------------------"

# --- 9. Fail if staged files include automation or drafts ---
if echo "$STAGED_FILES" | grep -qE "blog/automation/|blog/drafts/"; then
    echo "Error: Staged files include automation or draft files. Aborting script."
    exit 1
fi

# --- Print current git status for review ---
echo "# --- Current Git Status ---"
git status --short
echo "# --------------------------"

echo "# Script completed successfully: Files are prepared and staged for review/commit."
exit 0