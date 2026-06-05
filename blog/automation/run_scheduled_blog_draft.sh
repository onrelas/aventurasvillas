#!/bin/bash

# Script purpose: Validate a provided blog draft, run QA, and report status.
# This script does NOT generate a new draft using an LLM.

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

# --- Handle Draft File Path Argument ---
if [ -z "$1" ]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "reason: no draft path provided"
    echo "publish status: blocked"
    exit 0
fi

DRAFT_FILE_PATH="$1"
echo "Aventuras-only draft path or no draft found: $DRAFT_FILE_PATH"

# Validate provided draft path
if [ ! -f "$DRAFT_FILE_PATH" ]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "reason: provided draft path does not exist: $DRAFT_FILE_PATH"
    echo "publish status: blocked"
    exit 0
fi

# Ensure path is absolute for consistent checks
DRAFT_FILE_PATH_ABS=$(readlink -f "$DRAFT_FILE_PATH")

if [[ ! "$DRAFT_FILE_PATH_ABS" == "${DRAFTS_DIR}"* ]]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "reason: provided draft path is not inside $DRAFTS_DIR: $DRAFT_FILE_PATH"
    echo "publish status: blocked"
    exit 0
fi

if [[ ! "$DRAFT_FILE_PATH_ABS" == *.html ]]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "reason: provided draft file must end in .html: $DRAFT_FILE_PATH"
    echo "publish status: blocked"
    exit 0
fi

if [[ "$DRAFT_FILE_PATH_ABS" == *.md ]]; then
    echo "qa script ran yes/no: no"
    echo "full QA output:"
    echo "QA_RESULT: FAIL"
    echo "reason: provided draft file must not be .md: $DRAFT_FILE_PATH"
    echo "publish status: blocked"
    exit 0
fi

# --- Run QA script on the provided draft ---
QA_TEMP_OUTPUT=$(bash "$QA_SCRIPT" "$DRAFT_FILE_PATH")
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
