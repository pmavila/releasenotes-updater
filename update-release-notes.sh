#!/usr/bin/env bash
# =============================================================================
# Release Notes Updater
# =============================================================================
# Author:   Paulo Miguel Avila
# Website:  https://pmawebtech.ph
# Version:  1.0.0
# GitHub:   https://github.com/pmavila
# Hire me:  https://www.linkedin.com/in/paulo-miguel-avila/
# License:  GNU General Public License v3.0 (GPLv3)
#           https://www.gnu.org/licenses/gpl-3.0.html
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# =============================================================================

# Usage:
#   ./scripts/update-release-notes.sh                              # full release notes, untagged labelled "Latest"
#   ./scripts/update-release-notes.sh -untagged v1.2.6            # label untagged section as "v1.2.6"
#   ./scripts/update-release-notes.sh -limit 10                   # only include the last 10 tags
#   ./scripts/update-release-notes.sh -untagged v1.2.6 -limit 10  # combined

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
version_name="Latest"
tag_limit=0   # 0 = no limit (full history)

while [[ $# -gt 0 ]]; do
    case "$1" in
        -untagged)
            shift
            if [[ $# -gt 0 ]]; then
                version_name="$1"
                shift
            else
                echo "Error: -untagged requires a version label (e.g. -untagged v1.2.6)" >&2
                exit 1
            fi
            ;;
        -limit)
            shift
            if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
                tag_limit="$1"
                shift
            else
                echo "Error: -limit requires a positive integer (e.g. -limit 10)" >&2
                exit 1
            fi
            ;;
        *)
            # Legacy positional argument support
            version_name="$1"
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Categorise a single commit line into one of the known buckets.
# Prints the bucket name: Features | Bug Fixes | Improvements | Enhancements |
#                         Optimisations | Adjustments | Others
categorise_commit() {
    local msg="$1"
    # Strip optional JIRA key prefix (e.g. "KWOS-123 fix: ..." -> "fix: ...")
    local body
    body=$(echo "$msg" | sed 's/^[A-Z][A-Z0-9]*-[0-9]\+[[:space:]]*//')

    local lbody
    lbody=$(echo "$body" | tr '[:upper:]' '[:lower:]')

    if [[ "$lbody" =~ ^feat[[:space:]]*: ]]; then
        echo "Features"
    elif [[ "$lbody" =~ ^fix[[:space:]]*: ]]; then
        echo "Bug Fixes"
    elif [[ "$lbody" =~ ^(improv|improvement|improvements)[[:space:]]*: ]]; then
        echo "Improvements"
    elif [[ "$lbody" =~ ^enhance[[:space:]]*: ]]; then
        echo "Enhancements"
    elif [[ "$lbody" =~ ^opt[[:space:]]*: ]]; then
        echo "Optimisations"
    elif [[ "$lbody" =~ ^adj[[:space:]]*: ]]; then
        echo "Adjustments"
    else
        echo "Others"
    fi
}

# Given a newline-separated list of raw commit lines, print a categorised
# markdown block.  Skips empty input.
print_categorised() {
    local raw_commits="$1"

    [[ -z "$raw_commits" ]] && return

    # Category order
    local -a order=("Features" "Bug Fixes" "Improvements" "Enhancements" "Optimisations" "Adjustments" "Others")

    declare -A buckets
    for cat in "${order[@]}"; do
        buckets["$cat"]=""
    done

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        # Extract the human-readable subject (everything after "*  ")
        local subject="${line#\*  }"
        local cat
        cat=$(categorise_commit "$subject")
        if [[ -n "${buckets[$cat]}" ]]; then
            buckets["$cat"]+=$'\n'"$line"
        else
            buckets["$cat"]="$line"
        fi
    done <<< "$raw_commits"

    local printed_any=0
    for cat in "${order[@]}"; do
        if [[ -n "${buckets[$cat]}" ]]; then
            printf "### %s\n\n" "$cat"
            printf "%s\n\n" "${buckets[$cat]}"
            printed_any=1
        fi
    done

    [[ $printed_any -eq 0 ]] && printf "No new changes since last release.\n\n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

current_date=$(date +"%Y-%m-%d")

# Build ordered list of tags (newest first). Apply limit when set:
# we need limit+1 tags so each tag has a "previous" boundary tag for git log.
if [[ $tag_limit -gt 0 ]]; then
    mapfile -t all_tags < <(git tag --sort=-creatordate | head -n $(( tag_limit + 1 )))
else
    mapfile -t all_tags < <(git tag --sort=-creatordate)
fi

latest_tag="${all_tags[0]}"

# Untagged / unreleased commits (always shown)
untagged_commits=$(git log "${latest_tag}..HEAD" --pretty=format:'*  %s [View](https://bitbucket.org/unlimitedtecau/kayta-web/commits/%H)' --reverse | grep -v Merge)

printf "## %s (%s)\n\n" "$version_name" "$current_date"

if [[ -n "$untagged_commits" ]]; then
    print_categorised "$untagged_commits"
else
    printf "No new changes since last release.\n\n"
fi

# Tagged releases
num_tags=${#all_tags[@]}
for (( i=0; i<num_tags-1; i++ )); do
    this_tag="${all_tags[$i]}"
    prev_tag="${all_tags[$i+1]}"

    tag_date=$(git log -1 --pretty=format:'%ad' --date=short "${this_tag}")
    printf "## %s (%s)\n\n" "$this_tag" "$tag_date"

    raw=$(git log "${prev_tag}...${this_tag}" --pretty=format:'*  %s [View](https://bitbucket.org/unlimitedtecau/kayta-web/commits/%H)' --reverse | grep -v Merge)

    if [[ -n "$raw" ]]; then
        print_categorised "$raw"
    else
        printf "No changes.\n\n"
    fi
done
