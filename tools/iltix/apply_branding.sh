#!/usr/bin/env bash
set -euo pipefail

# apply_branding.sh
# Fallback: apply Iltix branding by editing files directly when git am/git apply fail.

# Determine chromium src dir. Prefer first argument, then CHROMIUM_SRC, then WORKSPACE/chromium/src.
CHROMIUM_SRC_DIR="${1:-${CHROMIUM_SRC:-$WORKSPACE/chromium/src}}"

if [ -z "${CHROMIUM_SRC_DIR:-}" ]; then
  echo "[iltix-fallback] CHROMIUM_SRC_DIR not set; cannot apply branding"
  exit 0
fi

echo "[iltix-fallback] Using chromium src: $CHROMIUM_SRC_DIR"

changed=0

# 1) AndroidManifest.xml: replace android:label in <application ...>
MANIFEST="$CHROMIUM_SRC_DIR/chrome/android/java/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  echo "[iltix-fallback] Patching AndroidManifest: $MANIFEST"
  # Try a robust perl in-place substitution: replace label attribute in the application tag
  if perl -0777 -pe 's/(<application[^>]*?)android:label="[^"]*"/$1android:label="Iltix Browser"/s' -i "$MANIFEST"; then
    changed=1
  fi
else
  echo "[iltix-fallback] AndroidManifest not found: $MANIFEST"
fi

# 2) BRANDING file: update PRODUCT_* entries
BRANDING="$CHROMIUM_SRC_DIR/chrome/app/theme/chromium/BRANDING"
if [ -f "$BRANDING" ]; then
  echo "[iltix-fallback] Updating BRANDING: $BRANDING"
  sed -i 's/^PRODUCT_FULLNAME=.*/PRODUCT_FULLNAME=Iltix Browser/' "$BRANDING" || true
  sed -i 's/^PRODUCT_SHORTNAME=.*/PRODUCT_SHORTNAME=Iltix/' "$BRANDING" || true
  sed -i 's/^PRODUCT_INSTALLER_FULLNAME=.*/PRODUCT_INSTALLER_FULLNAME=Iltix Browser Installer/' "$BRANDING" || true
  sed -i 's/^PRODUCT_INSTALLER_SHORTNAME=.*/PRODUCT_INSTALLER_SHORTNAME=Iltix Installer/' "$BRANDING" || true
  changed=1
else
  echo "[iltix-fallback] BRANDING file not found: $BRANDING"
fi

# Commit changes if any
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ "$changed" -eq 1 ] && [ -n "$(git status --porcelain)" ]; then
    git add -A || true
    git commit -m "Iltix Branding (applied via fallback script)" || true
    echo "[iltix-fallback] Committed branding changes"
  else
    echo "[iltix-fallback] No changes to commit"
  fi
else
  echo "[iltix-fallback] Not inside a git repo; skipping commit"
fi

exit 0
