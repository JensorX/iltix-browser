#!/usr/bin/env bash
# tools/iltix/pre_merge.sh
#
# Run this BEFORE pulling/merging upstream Cromite changes.
# It reverses all Iltix patches so the working tree is clean for merging.
#
# CHROMIUM_SRC must point to the Chromium source root (with all patches applied).
#
# Usage:
#   CHROMIUM_SRC=/path/to/chromium/src bash tools/iltix/pre_merge.sh

set -euo pipefail

CHROMIUM_SRC="${CHROMIUM_SRC:?Set CHROMIUM_SRC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="${SCRIPT_DIR}/../../build/patches"

ILTIX_PATCHES=(
    "Iltix-Module-AutoHideNavigation.patch"
    "Iltix-Module-Navigation.patch"
    "Iltix-Module-Theme.patch"
    "Iltix-Module-Settings-Infrastructure.patch"
    "Iltix-Branding.patch"
)

echo "========================================================"
echo " Iltix pre-merge: reversing Iltix patches"
echo " Chromium source: ${CHROMIUM_SRC}"
echo "========================================================"

cd "${CHROMIUM_SRC}"

# Restore any string overrides first
CHROMIUM_SRC="${CHROMIUM_SRC}" bash "${SCRIPT_DIR}/patch_strings.sh" restore

# Reverse patches in reverse order (last applied first)
for patch in "${ILTIX_PATCHES[@]}"; do
    patch_file="${PATCH_DIR}/${patch}"
    if [ ! -f "${patch_file}" ]; then
        echo "[WARN] Patch not found, skipping: ${patch}"
        continue
    fi
    echo "[iltix] Reversing: ${patch}"
    git apply --reverse "${patch_file}" || {
        echo "[WARN] Could not reverse ${patch} cleanly — may not have been applied."
    }
done

echo ""
echo "========================================================"
echo " Done. You can now merge/rebase upstream Cromite."
echo " Run tools/iltix/post_merge.sh after the merge."
echo "========================================================"
