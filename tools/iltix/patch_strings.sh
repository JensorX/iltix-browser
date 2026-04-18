#!/usr/bin/env bash
# tools/iltix/patch_strings.sh
#
# Manages Iltix string overrides in Cromite source files.
#
# IMPORTANT: Iltix NEVER modifies upstream strings in place.
# All Iltix strings live in:
#   chrome/browser/ui/android/strings/iltix_android_chrome_strings_grd/
#
# This script handles the special case where we want to override
# a Cromite/Chromium string *value* at build time without editing the upstream file.
# It creates a sidecar .orig backup and patches in our values, then restores from
# backup before upstream merges.
#
# Usage:
#   ./tools/iltix/patch_strings.sh apply      # apply overrides (before build)
#   ./tools/iltix/patch_strings.sh restore    # restore upstream (before merge)
#   ./tools/iltix/patch_strings.sh status     # check current state
#
# CHROMIUM_SRC must be set to the Chromium source root.

set -euo pipefail

CHROMIUM_SRC="${CHROMIUM_SRC:?Set CHROMIUM_SRC to your Chromium source root}"
ACTION="${1:-status}"

# ─── String override definitions ────────────────────────────────────────────
# Format: each entry is "FILE|PATTERN|REPLACEMENT"
# FILE is relative to CHROMIUM_SRC
# PATTERN and REPLACEMENT are passed to sed (basic regex)
#
# Currently we have NO string overrides because our strategy is to keep all
# Iltix strings in separate .grdp files (added via the patch's android_chrome_strings.grd xi:include).
# If a future Iltix release needs to change a Cromite string, add an entry here.
# ────────────────────────────────────────────────────────────────────────────
declare -a OVERRIDES=(
    # Example (currently unused):
    # "chrome/browser/ui/android/strings/android_chrome_strings.grd|Cromite|Iltix Browser"
)

apply_overrides() {
    echo "[iltix/strings] Applying string overrides..."
    for entry in "${OVERRIDES[@]}"; do
        IFS='|' read -r file pattern replacement <<< "$entry"
        target="${CHROMIUM_SRC}/${file}"
        backup="${target}.iltix.orig"
        if [ -f "${backup}" ]; then
            echo "  [SKIP] ${file} — already patched"
            continue
        fi
        cp "${target}" "${backup}"
        sed -i "s|${pattern}|${replacement}|g" "${target}"
        echo "  [OK]   ${file}"
    done
    echo "[iltix/strings] Done."
}

restore_overrides() {
    echo "[iltix/strings] Restoring original strings..."
    for entry in "${OVERRIDES[@]}"; do
        IFS='|' read -r file pattern replacement <<< "$entry"
        target="${CHROMIUM_SRC}/${file}"
        backup="${target}.iltix.orig"
        if [ ! -f "${backup}" ]; then
            echo "  [SKIP] ${file} — no backup found (not patched)"
            continue
        fi
        mv "${backup}" "${target}"
        echo "  [OK]   ${file}"
    done
    echo "[iltix/strings] Done."
}

show_status() {
    echo "[iltix/strings] Current state:"
    for entry in "${OVERRIDES[@]}"; do
        IFS='|' read -r file pattern replacement <<< "$entry"
        target="${CHROMIUM_SRC}/${file}"
        backup="${target}.iltix.orig"
        if [ -f "${backup}" ]; then
            echo "  PATCHED   ${file}"
        else
            echo "  UPSTREAM  ${file}"
        fi
    done
}

case "${ACTION}" in
    apply)   apply_overrides ;;
    restore) restore_overrides ;;
    status)  show_status ;;
    *)
        echo "Usage: $0 {apply|restore|status}"
        exit 1
        ;;
esac
