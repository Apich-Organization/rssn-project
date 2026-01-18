#!/bin/bash

export PROJECT_ROOT_DIR=$(pwd)
export TIMESTAMP=$(date +%Y%m%d_%H%M%S)
export FINAL_OUTPUT_DIR="$PROJECT_ROOT_DIR/analysis_$TIMESTAMP"

mkdir -p "$FINAL_OUTPUT_DIR"

# --- Function for the Root Project ---
echo "----------------------------------------------------"
echo "ANALYZING ROOT PROJECT"
# Use a static name "ROOT" for the main repo files
git-of-theseus-analyze --outdir "$FINAL_OUTPUT_DIR/ROOT_raw" --interval 5400 "."
cd "$FINAL_OUTPUT_DIR/ROOT_raw"
[ -f cohorts.json ] && git-of-theseus-stack-plot cohorts.json --outfile "../ROOT_cohorts.png"
[ -f authors.json ] && git-of-theseus-stack-plot authors.json --outfile "../ROOT_authors.png"
[ -f exts.json ]    && git-of-theseus-stack-plot exts.json    --outfile "../ROOT_exts.png"
cd "$PROJECT_ROOT_DIR"

# --- Analyze Submodules with Clean Names ---
git submodule update --init --recursive
git submodule foreach --recursive '
    # Get just the folder name (e.g., "rssn") instead of path
    CLEAN_NAME=$(basename "$displaypath")

    # Calculate local timeline
    FIRST=$(git log --reverse --format=%ct | head -1)
    LAST=$(git log -1 --format=%ct)
    AGE=$((LAST - FIRST))

    # Set interval: 1/100th of age or minimum 5400 seconds
    INT=$((AGE / 100))
    if [ "$INT" -lt 5400 ]; then INT=5400; fi

    echo "----------------------------------------------------"
    echo "ANALYZING SUBMODULE: $CLEAN_NAME"

    OUT_DIR="$FINAL_OUTPUT_DIR/${CLEAN_NAME}_data"
    mkdir -p "$OUT_DIR"

    # Run analysis
    git-of-theseus-analyze --outdir "$OUT_DIR" --interval "$INT" --all-filetypes "."

    # Generate Plots with Clean Filenames
    cd "$OUT_DIR"
    [ -f cohorts.json ] && git-of-theseus-stack-plot cohorts.json --outfile "../${CLEAN_NAME}_cohorts.png"
    [ -f authors.json ] && git-of-theseus-stack-plot authors.json --outfile "../${CLEAN_NAME}_authors.png"
    [ -f exts.json ]    && git-of-theseus-stack-plot exts.json    --outfile "../${CLEAN_NAME}_exts.png"
'

echo "----------------------------------------------------"
echo "SUCCESS: Check your results in: $FINAL_OUTPUT_DIR"
ls -1 "$FINAL_OUTPUT_DIR"/*.png
