# Iltix Browser — Conventions & Developer Guide

**Last Updated:** April 2026  
**Status:** ✅ Active

---

## Overview

Iltix Browser is a modular fork of Cromite (which is itself a Chromium fork).

The **primary goal** is minimal upstream merge conflicts. Everything Iltix adds
must be designed to survive an upstream Cromite update with zero or minimal
manual conflict resolution.

---

## Core Rule: Minimum Upstream Footprint

> **We leave the smallest possible footprint on Cromite/Chromium sources.**

This means:

1. **All new code** lives in `org.chromium.chrome.browser.iltix.*` — upstream never touches this namespace.
2. **Never modify upstream strings**. All Iltix UI strings go in  
   `chrome/browser/ui/android/strings/iltix_android_chrome_strings_grd/`.
3. **Hooks into upstream code are kept to ≤2 lines per file** — a single guarded call like:  
   ```java
   if (IltixModuleManager.isFooEnabled()) IltixFooModule.apply(view);
   ```
4. **All features are runtime-toggled via `IltixModuleManager`**. The original Cromite behaviour is always preserved when a module is disabled.
5. **Patch-based**: Every Iltix change is a `.patch` file in `build/patches/`, appended at the end of `build/cromite_patches_list.txt`.

---

## File Locations

| What | Where |
|------|-------|
| Java/Kotlin module code | `chrome/android/java/src/org/chromium/chrome/browser/iltix/` |
| Iltix strings | `chrome/browser/ui/android/strings/iltix_android_chrome_strings_grd/*.grdp` |
| Iltix layouts | `chrome/android/java/res/layout/iltix_*.xml` |
| Iltix drawables | `chrome/android/java/res/drawable/iltix_*.xml` |
| Iltix preference XML | `chrome/android/java/res/xml/iltix_*.xml` |
| Iltix patch files | `build/patches/Iltix-*.patch` |
| Build scripts | `tools/iltix/` |
| App icons (placeholder) | `tools/iltix/icons/` |

---

## Patch Format

Every patch follows the Cromite patch format:

```
From: Iltix <dev@iltix.de>
Date: ...
Subject: Iltix Module: <name>

<description of what the patch does>

Requires: <other-patch.patch>   ← if applicable

Original License: GPL-2.0-or-later
License: GPL-2.0-or-later
---
<git diff header>
```

---

## Modules

All features are implemented as **Iltix Modules** — independently toggleable units
managed by `IltixModuleManager`. All modules are **enabled by default**.

| Module Key | Class | Default |
|-----------|-------|---------|
| `iltix_module_theme` | `IltixThemeModule` | ✅ enabled |
| `iltix_module_navigation` | `IltixNavBarCoordinator` | ✅ enabled |
| `iltix_module_autohide` | `IltixAutoHideController` | ✅ enabled |

### Adding a New Module

1. Create your module code under `org.chromium.chrome.browser.iltix.<module>/`
2. Add a `MODULE_FOO = "iltix_module_foo"` constant to `IltixModuleManager`
3. Add a convenience static `isFooEnabled()` helper to `IltixModuleManager`
4. Add a `SwitchPreference` entry in `iltix_module_preferences.xml`
5. Add the string resources in a new `.grdp` file under  
   `chrome/browser/ui/android/strings/iltix_android_chrome_strings_grd/`
6. Include the `.grdp` in `android_chrome_strings.grd` via `<xi:include>`
7. Write a patch: `build/patches/Iltix-Module-<Name>.patch`
8. Add the patch to `build/cromite_patches_list.txt` at the end of the Iltix section

---

## Strings Policy

> **NEVER touch upstream strings files directly.**

- Cromite/Chromium strings live in `chrome/browser/ui/android/strings/android_chrome_strings.grd`  
  and the `cromite_android_chrome_strings_grd/` subdirectory.
- Iltix strings live **exclusively** in `iltix_android_chrome_strings_grd/`.
- If a future feature requires overriding a Cromite string value (not recommended),  
  use `tools/iltix/patch_strings.sh` to track the change and auto-restore before upstream merges.

---

## Upstream Merge Workflow

### Before merging Cromite upstream:
```bash
CHROMIUM_SRC=/path/to/chromium/src bash tools/iltix/pre_merge.sh
```
This reverses all Iltix patches, leaving a clean tree for merging.

### Perform the upstream merge/rebase normally.

### After the merge:
```bash
CHROMIUM_SRC=/path/to/chromium/src bash tools/iltix/post_merge.sh
```
This re-applies all Iltix patches and icons.

If a patch fails, fix the conflict, update the patch file with  
`tools/export-single-patch.sh`, and run `post_merge.sh` again.

---

## Build GN Args

Iltix-specific GN args (package name, etc.) are set in `build/cromite.gn_args`  
directly, since that file is already Iltix-specific (not upstream Cromite).

```
chrome_public_manifest_package = "de.iltix.browser"
system_webview_package_name = "de.iltix.webview"
system_webview_shell_package_name = "de.iltix.webview_shell"
```

---

## Icons

Placeholder icons from Iltix Messenger are stored at `tools/iltix/icons/`.  
They are copied into the Chromium source by `tools/iltix/apply_icons.sh`  
(called automatically by `post_merge.sh`).

Final production icons should replace the files in `tools/iltix/icons/` at the
appropriate densities (`mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`,  
`mipmap-xxhdpi`, `mipmap-xxxhdpi`).

---

## Merge Conflict Risk Assessment

| Component | Risk | Rationale |
|-----------|------|-----------|
| `Iltix-Branding.patch` | 🟡 Low-medium | Touches AndroidManifest (common upstream change) |
| `Iltix-Module-Settings-Infrastructure.patch` | 🟡 Low | `main_preferences.xml` is touched by many Cromite patches |
| `Iltix-Module-Theme.patch` | 🟢 Very low | All new files, 0 upstream modifications |
| `Iltix-Module-Navigation.patch` | 🟢 Very low | All new files, 0 upstream modifications |
| `Iltix-Module-AutoHideNavigation.patch` | 🟢 Very low | All new files, 0 upstream modifications |
| `build/cromite.gn_args` (package name) | 🟡 Low | Checked in directly; re-apply if rebased |
