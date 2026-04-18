#!/usr/bin/env bash
# tools/iltix/apply_icons.sh
# Copies Iltix Messenger placeholder icons into the Chromium source tree.
# Must be run after `git am` has applied all patches, from within the
# chromium/src directory. The ILTIX_BROWSER_REPO env var must point to
# the root of the iltix-browser repo.
#
# Usage:
#   CHROMIUM_SRC=/path/to/chromium/src \
#   ILTIX_BROWSER_REPO=/path/to/iltix-browser \
#   bash tools/iltix/apply_icons.sh

set -euo pipefail

CHROMIUM_SRC="${CHROMIUM_SRC:?Please set CHROMIUM_SRC}"
ILTIX_REPO="${ILTIX_BROWSER_REPO:?Please set ILTIX_BROWSER_REPO}"
ICON_SRC="${ILTIX_REPO}/tools/iltix/icons"

# Mapping: source density dir -> target Chromium res dir
declare -A DENSITIES=(
  ["mipmap-hdpi"]="mipmap-hdpi"
  ["mipmap-mdpi"]="mipmap-mdpi"
  ["mipmap-xhdpi"]="mipmap-xhdpi"
  ["mipmap-xxhdpi"]="mipmap-xxhdpi"
  ["mipmap-xxxhdpi"]="mipmap-xxxhdpi"
)

CHROMIUM_ICON_BASE="${CHROMIUM_SRC}/chrome/android/java/res_chromium_base"

echo "[iltix] Applying Iltix Browser icons to Chromium source..."

for density in "${!DENSITIES[@]}"; do
  src_dir="${ICON_SRC}/${density}"
  target_dir="${CHROMIUM_ICON_BASE}/${DENSITIES[$density]}"

  if [ ! -d "${src_dir}" ]; then
    echo "  [WARN] Icon source directory not found: ${src_dir} (skipping)"
    continue
  fi

  mkdir -p "${target_dir}"

  # app_icon.png -> the main launcher icon
  if [ -f "${src_dir}/ic_launcher.png" ]; then
    cp "${src_dir}/ic_launcher.png" "${target_dir}/app_icon.png"
    echo "  [OK] ${density}/app_icon.png"
  fi

  # layered_app_icon.png -> foreground of adaptive icon
  if [ -f "${src_dir}/ic_launcher_foreground.png" ]; then
    cp "${src_dir}/ic_launcher_foreground.png" "${target_dir}/layered_app_icon.png"
    echo "  [OK] ${density}/layered_app_icon.png"
  fi

  # layered_app_icon_background.png -> background of adaptive icon
  if [ -f "${src_dir}/ic_launcher_background.png" ]; then
    cp "${src_dir}/ic_launcher_background.png" "${target_dir}/layered_app_icon_background.png"
    echo "  [OK] ${density}/layered_app_icon_background.png"
  fi
done

echo "[iltix] Icon apply complete."
