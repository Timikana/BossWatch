#!/usr/bin/env bash
# Tag and push a BETA release from the beta branch.
#
# Usage:  scripts/release_beta.sh
#
# Reads the current TOC version, finds the next available -beta.N number,
# extracts the [Unreleased] section from CHANGELOG.md as the tag annotation,
# tags + pushes + posts to Discord. Does NOT merge to main — beta tags live
# parallel to stable tags.
#
# Output: e.g. tag v0.7.6-beta.1 pushed and announced on Discord as a beta.
# The BigWigsMods/packager auto-detects the -beta.N suffix and publishes
# to the beta channel on CurseForge / Wago.

set -euo pipefail
cd "$(dirname "$0")/.."

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "beta" ]; then
    echo "error: must run from the 'beta' branch (currently on '$branch')" >&2
    exit 2
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "error: working tree dirty — commit or stash first" >&2
    exit 2
fi

# Read the next version target from the TOC (e.g. 0.7.6)
toc_ver=$(grep -m1 '^## Version:' BossWatch.toc | sed 's/## Version: //; s/[[:space:]]*$//')
if [ -z "$toc_ver" ]; then
    echo "error: couldn't read ## Version from BossWatch.toc" >&2
    exit 2
fi

# Find next available -beta.N number
n=1
while git rev-parse -q --verify "v${toc_ver}-beta.${n}" >/dev/null 2>&1; do
    n=$((n+1))
done
tag="v${toc_ver}-beta.${n}"

# Extract [Unreleased] block for the tag annotation. If empty, abort
# (beta releases should ship some pending change).
tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT
bash scripts/extract_changelog.sh Unreleased > "$tmpfile"
if [ ! -s "$tmpfile" ]; then
    echo "error: [Unreleased] section of CHANGELOG.md is empty — nothing to release" >&2
    exit 2
fi

echo "About to create tag: $tag"
echo "--- annotation body ---"
cat "$tmpfile"
echo "--- end ---"
echo "Press Enter to continue, Ctrl+C to abort"
read -r

git tag -a "$tag" -F "$tmpfile"
git push origin "$tag"

echo "$tag pushed."
echo "GitHub Actions will package and publish to CurseForge/Wago beta channel."

# Discord — beta uses a different embed color to distinguish from stable
if [ -f scripts/_post_discord.py ]; then
    # Reuse the same script with the beta tag (it doesn't care about suffix)
    python scripts/_post_discord.py "${toc_ver}-beta.${n}" || \
        echo "warning: Discord post failed (continuing)"
fi
