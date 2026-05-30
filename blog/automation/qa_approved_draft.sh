#!/bin/bash

# Script purpose: Run deterministic QA on one draft file before founder approval.

set -e # Exit immediately if a command exits with a non-zero status.

REPO_ROOT="/home/admintest/.openclaw/workspace/aventurasvillas"
DRAFT_FILE_PATH="$1"

# --- Configuration for checks ---
BANNED_PHRASES=(
    "escape to paradise"
    "luxury awaits"
    "ultimate"
    "unforgettable"
    "dream vacation"
    "unparalleled"
    "magical"
    "seamless"
    "curated excursions"
    "private chef"
    "spa treatments"
    "concierge"
    "best rates"
    "guaranteed"
)

# New Banned Phrases for template/incomplete drafts
BANNED_TEMPLATE_PHRASES=(
    "Section outline"
    "Writing cues"
    "Hook:"
    "expand to full article"
    "Target 700"
    "Intent:"
    "Drafted"
    "optimized for conversion"
    "warm-host voice"
    "placeholder"
    "TODO"
    "lorem ipsum"
)

# Specific URLs that are considered unverified if they appear in the draft,
# as sub-paths of aventuravillas.com for specific villas are not in FACTS_CONTRACT.md
UNVERIFIED_VILLA_URLS=(
    "aventurasvillas.com/casa-aventura"
    "aventurasvillas.com/villa-sorella"
    # Note: aventuravillas.com/ is a base verified URL, but specific villa pages are not in contract
)

# --- File Paths ---
QUALITY_CONSTITUTION_PATH="${REPO_ROOT}/blog/automation/AVENTURAS_BLOG_QUALITY_CONSTITUTION.md"
FACTS_CONTRACT_PATH="${REPO_ROOT}/blog/automation/AVENTURAS_VILLAS_FACTS_CONTRACT.md"

# --- Argument Validation ---
if [ -z "$DRAFT_FILE_PATH" ]; then
    echo "Error: Missing draft file path."
    echo "Usage: $0 <draft_file_path>"
    exit 1
fi

# --- Change to repo root ---
cd "$REPO_ROOT" || { echo "Error: Could not change directory to $REPO_ROOT"; exit 1; }
echo "# Current working directory: $(pwd)"

# --- Verify Draft and Contract Files Exist ---
if [ ! -f "$DRAFT_FILE_PATH" ]; then
    echo "QA_RESULT: FAIL"
    echo "Reason: Draft file not found at $DRAFT_FILE_PATH"
    exit 0 # Exit with 0 to indicate script ran, but QA failed
fi
if [ ! -f "$QUALITY_CONSTITUTION_PATH" ]; then
    echo "QA_RESULT: FAIL"
    echo "Reason: Quality Constitution file not found at $QUALITY_CONSTITUTION_PATH"
    exit 0
fi
if [ ! -f "$FACTS_CONTRACT_PATH" ]; then
    echo "QA_RESULT: FAIL"
    echo "Reason: Facts Contract file not found at $FACTS_CONTRACT_PATH"
    exit 0
fi
echo "# All required input files found."

# Read the content of the draft file into a variable for multiple checks
DRAFT_CONTENT=$(cat "$DRAFT_FILE_PATH")

# --- Run QA Checks ---
QA_STATUS="PASS"
REASONS=()

# Existing checks
# Check for banned AI/travel phrases
for phrase in "${BANNED_PHRASES[@]}"; do
    if echo "$DRAFT_CONTENT" | grep -qEi "$phrase"; then
        QA_STATUS="FAIL"
        REASONS+=("Draft contains banned phrase: '$phrase'")
    fi
done

# Check for fake/unverified villa-specific URLs
for url_fragment in "${UNVERIFIED_VILLA_URLS[@]}"; do
    if echo "$DRAFT_CONTENT" | grep -q "$url_fragment"; then
        QA_STATUS="FAIL"
        REASONS+=("Draft contains unverified villa-specific URL fragment: '$url_fragment'")
    fi
done

# Check if draft assigns Starlink to Casa Aventura (not in Facts Contract)
STARLINK_CASA_AVENTURA_PATTERNS=(
    "Casa Aventura offers Starlink"
    "Casa Aventura includes Starlink"
    "Casa Aventura has Starlink"
    "Starlink at Casa Aventura"
    "Starlink internet at Casa Aventura"
)
for pattern in "${STARLINK_CASA_AVENTURA_PATTERNS[@]}"; do
    if echo "$DRAFT_CONTENT" | grep -qEi "$pattern"; then
        QA_STATUS="FAIL"
        REASONS+=("Draft assigns Starlink to Casa Aventura (not in Facts Contract) with phrase: '$pattern'")
        break # Exit loop on first match
    fi
done

# Check if draft *positively* says Villa Tikal is a rental villa (incorrect)
VILLA_TIKAL_RENTAL_PATTERNS=(
    "Villa Tikal is a rental villa"
    "Villa Tikal for rent"
    "rent Villa Tikal"
    "rental property is Villa Tikal"
    "rental Villa Tikal"
    "Villa Tikal a rental"
)
for pattern in "${VILLA_TIKAL_RENTAL_PATTERNS[@]}"; do
    if echo "$DRAFT_CONTENT" | grep -qEi "$pattern"; then
        QA_STATUS="FAIL"
        REASONS+=("Draft refers to Villa Tikal as a rental villa (it's an investment project) with phrase: '$pattern'")
        break # Exit loop on first match
    fi
done

# New checks for incomplete/template drafts

# Check for banned template phrases
for phrase in "${BANNED_TEMPLATE_PHRASES[@]}"; do
    if echo "$DRAFT_CONTENT" | grep -qFi "$phrase"; then # -F for fixed string, -i for case-insensitive
        QA_STATUS="FAIL"
        REASONS+=("Draft contains template phrase: '$phrase'")
    fi
done

# Minimum word count (800 words)
WORD_COUNT=$(echo "$DRAFT_CONTENT" | wc -w)
if [ "$WORD_COUNT" -lt 800 ]; then
    QA_STATUS="FAIL"
    REASONS+=("Draft has less than 800 words (current: $WORD_COUNT)")
fi

# Minimum H2 count (4 H2 tags)
H2_COUNT=$(echo "$DRAFT_CONTENT" | grep -cE '<h2[^>]*>')
if [ "$H2_COUNT" -lt 4 ]; then
    QA_STATUS="FAIL"
    REASONS+=("Draft has less than 4 H2 headings (current: $H2_COUNT)")
fi

# Must contain a meta description tag
if ! echo "$DRAFT_CONTENT" | grep -qE '<meta[^>]*name="description"[^>]*content="[^"]+"[^>]*>'; then
    QA_STATUS="FAIL"
    REASONS+=("Draft is missing a valid meta description tag")
fi

# Must contain at least one CTA link (assuming CTA links have class="btn")
if ! echo "$DRAFT_CONTENT" | grep -qE '<a[^>]*class="[^"]*btn[^"]*"[^>]*href="https?://[^"]+"[^>]*>'; then
    QA_STATUS="FAIL"
    REASONS+=("Draft is missing at least one CTA button link")
fi

# Must contain either FAQ or Frequently Asked Questions
if ! echo "$DRAFT_CONTENT" | grep -qEi '(FAQ|Frequently Asked Questions)'; then
    QA_STATUS="FAIL"
    REASONS+=("Draft does not contain 'FAQ' or 'Frequently Asked Questions'")
fi

# Must not contain "QA pass" inside the draft body
if echo "$DRAFT_CONTENT" | grep -qFi "QA pass"; then
    QA_STATUS="FAIL"
    REASONS+=("Draft body contains 'QA pass'")
fi


# --- Output QA Result ---
if [ "$QA_STATUS" = "PASS" ]; then
    echo "QA_RESULT: PASS"
else
    echo "QA_RESULT: FAIL"
    echo "Reasons:"
    for reason in "${REASONS[@]}"; do
        echo "- $reason"
    done
fi

exit 0 # Always exit 0 if script ran without internal errors, QA_RESULT indicates pass/fail
