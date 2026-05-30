#!/bin/bash

# Script purpose: Deterministically find the newest blog draft, run QA, and report status.
# This version does NOT generate a new draft using an LLM.

set -e # Exit immediately if a command exits with a non-zero status.

REPO_ROOT="/home/admintest/.openclaw/workspace/aventurasvillas"
QA_SCRIPT="${REPO_ROOT}/blog/automation/qa_approved_draft.sh"
QUALITY_CONSTITUTION_PATH="${REPO_ROOT}/blog/automation/AVENTURAS_BLOG_QUALITY_CONSTITUTION.md"
FACTS_CONTRACT_PATH="${REPO_ROOT}/blog/automation/AVENTURAS_VILLAS_FACTS_CONTRACT.md"
DRAFTS_DIR="${REPO_ROOT}/blog/drafts/"

# --- Change to repo root ---
cd "$REPO_ROOT" || { echo "Error: Could not change directory to $REPO_ROOT"; exit 1; }

echo "working directory: $(pwd)"

# --- Verify Required Files Exist and are Executable ---
QUALITY_CONSTITUTION_FOUND="no"
if [ -f "$QUALITY_CONSTITUTION_PATH" ]; then
    QUALITY_CONSTITUTION_FOUND="yes"
fi
echo "quality constitution found yes/no: $QUALITY_CONSTITUTION_FOUND"

FACTS_CONTRACT_FOUND="no"
if [ -f "$FACTS_CONTRACT_PATH" ]; then
    FACTS_CONTRACT_FOUND="yes"
fi
echo "facts contract found yes/no: $FACTS_CONTRACT_FOUND"

QA_SCRIPT_FOUND="no"
QA_SCRIPT_EXECUTABLE="no"
if [ -f "$QA_SCRIPT" ]; then
    QA_SCRIPT_FOUND="yes"
    if [ -x "$QA_SCRIPT" ]; then
        QA_SCRIPT_EXECUTABLE="yes"
    fi
fi
echo "qa script found yes/no: $QA_SCRIPT_FOUND"
echo "qa script executable yes/no: $QA_SCRIPT_EXECUTABLE"

# Exit if any critical files are missing or QA script is not executable
if [ "$QUALITY_CONSTITUTION_FOUND" != "yes" ] || \
   [ "$FACTS_CONTRACT_FOUND" != "yes" ] || \
   [ "$QA_SCRIPT_FOUND" != "yes" ] || \
   [ "$QA_SCRIPT_EXECUTABLE" != "yes" ]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "Reasons: Required files for QA are missing or QA script is not executable."
    echo "publish status: blocked"
    exit 0
fi

# --- Find the newest draft in blog/drafts/ ---
NEWEST_DRAFT_PATH=""
if [ -d "$DRAFTS_DIR" ]; then
    # Use printf and sort for robust finding of the newest file by modification time
    # This handles filenames with spaces correctly.
    NEWEST_DRAFT_PATH=$(find "$DRAFTS_DIR" -maxdepth 1 -type f -printf '%T@ %p\n' 2>/dev/null | sort -k1 -nr | head -n 1 | cut -d' ' -f2-)
fi

echo "newest draft path: ${NEWEST_DRAFT_PATH:-\"no draft found\"}" # Handle empty case

if [ -z "$NEWEST_DRAFT_PATH" ]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "reason: no draft found in $DRAFTS_DIR"
    echo "publish status: blocked"
    exit 0
fi

# --- Run QA script on the newest draft ---
QA_TEMP_OUTPUT=$(bash "$QA_SCRIPT" "$NEWEST_DRAFT_PATH")
QA_EXIT_CODE=$?

echo "qa script ran yes/no: yes"
echo "full QA output:
$QA_TEMP_OUTPUT"

# Determine publish status based on QA output
if echo "$QA_TEMP_OUTPUT" | grep -q "QA_RESULT: PASS"; then
    echo "publish status: blocked until founder approval"
else
    echo "publish status: blocked"
fi

exit 0
