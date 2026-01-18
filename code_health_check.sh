#!/bin/bash

export PROJECT_ROOT_DIR=$(pwd)
export TIMESTAMP=$(date +%Y%m%d_%H%M%S)
export FINAL_OUTPUT_DIR="$PROJECT_ROOT_DIR/high_res_analysis_$TIMESTAMP"

mkdir -p "$FINAL_OUTPUT_DIR"

# --- Function to handle plotting ---
run_plots() {
    local d=$1
    local n=$2
    cd "$d" || return

    # 1. Growth (Total LOC)
    [ -f cohorts.json ] && git-of-theseus-stack-plot cohorts.json --outfile "../${n}_growth.png"
    # 2. Age Mix (%)
    [ -f cohorts.json ] && git-of-theseus-stack-plot cohorts.json --normalize --outfile "../${n}_age_mix.png"
    # 3. Authors
    [ -f authors.json ] && git-of-theseus-stack-plot authors.json --outfile "../${n}_authors.png"
    # 4. Survival Decay
    [ -f survival.json ] && git-of-theseus-survival-plot survival.json --outfile "../${n}_survival.png"
}

# --- 1. Analyze ROOT ---
echo "Analyzing ROOT with 5400s intervals..."
git-of-theseus-analyze --outdir "$FINAL_OUTPUT_DIR/ROOT_data" --interval 5400 --all-filetypes "."
run_plots "$FINAL_OUTPUT_DIR/ROOT_data" "ROOT"
cd "$PROJECT_ROOT_DIR"

# --- 2. Analyze SUBMODULES ---
git submodule update --init --recursive
git submodule foreach --recursive '
    CLEAN_NAME=$(basename "$displaypath")

    # Calculate timestamps
    FIRST=$(git log --reverse --format=%ct | head -1)
    LAST=$(git log -1 --format=%ct)
    AGE=$((LAST - FIRST))

    # Apply your logic: 1/120 of age, but minimum 5400s
    INT=$((AGE / 120))
    if [ "$INT" -lt 5400 ]; then INT=5400; fi

    echo "Analyzing $CLEAN_NAME | Interval: ${INT}s"

    OUT_DIR="$FINAL_OUTPUT_DIR/${CLEAN_NAME}_data"
    mkdir -p "$OUT_DIR"

    git-of-theseus-analyze --outdir "$OUT_DIR" --interval "$INT" --all-filetypes "."

    # Run Plots
    cd "$OUT_DIR"
    [ -f cohorts.json ] && git-of-theseus-stack-plot cohorts.json --outfile "../${CLEAN_NAME}_growth.png"
    [ -f cohorts.json ] && git-of-theseus-stack-plot cohorts.json --normalize --outfile "../${CLEAN_NAME}_age_mix.png"
    [ -f authors.json ] && git-of-theseus-stack-plot authors.json --outfile "../${CLEAN_NAME}_authors.png"
    [ -f survival.json ] && git-of-theseus-survival-plot survival.json --outfile "../${CLEAN_NAME}_survival.png"
'

echo "Done! Check: $FINAL_OUTPUT_DIR"
