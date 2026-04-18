#!/usr/bin/env bash
# tools/iltix/post_merge.sh
#
# Run this AFTER a successful upstream Cromite merge.
# Re-applies all Iltix patches in the correct order.
#
# CHROMIUM_SRC must point to the Chromium source root.
#
# Usage:
#   CHROMIUM_SRC=/path/to/chromium/src bash tools/iltix/post_merge.sh

set -euo pipefail

CHROMIUM_SRC="${CHROMIUM_SRC:?Set CHROMIUM_SRC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="${SCRIPT_DIR}/../../build/patches"

ILTIX_PATCHES=(
    "Iltix-Branding.patch"
    "Iltix-Module-Settings-Infrastructure.patch"
    "Iltix-Module-Theme.patch"
    "Iltix-Module-Navigation.patch"
    "Iltix-Module-AutoHideNavigation.patch"
)

echo "========================================================"
echo " Iltix post-merge: re-applying Iltix patches"
echo " Chromium source: ${CHROMIUM_SRC}"
echo "========================================================"

cd "${CHROMIUM_SRC}"

FAILED=()

for patch in "${ILTIX_PATCHES[@]}"; do
    patch_file="${PATCH_DIR}/${patch}"
    if [ ! -f "${patch_file}" ]; then
        echo "[ERROR] Patch not found: ${patch}"
        FAILED+=("${patch}")
        continue
    fi
    echo "[iltix] Applying: ${patch}"
    if ! git am "${patch_file}"; then
        echo "[ERROR] Failed to apply: ${patch}"
        git am --abort 2>/dev/null || true
        FAILED+=("${patch}")
    fi
done

# Re-apply string overrides
CHROMIUM_SRC="${CHROMIUM_SRC}" bash "${SCRIPT_DIR}/patch_strings.sh" apply

# Apply icons
CHROMIUM_SRC="${CHROMIUM_SRC}" ILTIX_BROWSER_REPO="${SCRIPT_DIR}/../.." \
    bash "${SCRIPT_DIR}/apply_icons.sh"

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "========================================================"
    echo " All Iltix patches applied successfully!"
    echo " Check the patch conflicts above for any warnings."
    echo "========================================================"
else
    echo "========================================================"
    echo " WARNING: The following patches need manual attention:"
    for p in "${FAILED[@]}"; do echo "   - ${p}"; done
    echo "========================================================"
    exit 1
fi
