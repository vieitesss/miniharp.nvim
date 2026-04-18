# Miniharp Plan

## Goal

Keep `miniharp.nvim` tiny and fast for a 2-3 file loop, while improving clarity, reducing interruption, and making releases predictable for users.

## Product Principles

1. Optimize for fast `next()` / `prev()` use, not large lists.
2. Reduce cognitive load: fewer notifications, clearer state.
3. Keep UI lightweight and optional.
4. Preserve minimal surface area unless a feature clearly improves the core loop.

## Implementation Order

### Phase 1: Minimal UX fixes

These are the highest-value changes and should land first.

1. Respect `show_on_autoload` consistently.
   - Do not show the popup on restore or `DirChanged` unless explicitly requested.
   - Keep restore quiet by default.

2. Reduce noisy notifications.
   - Remove or reduce routine `vim.notify` calls for add/update/remove actions.
   - Keep warnings for real problems only: invalid mark, failed persistence, missing file, decode/write errors.

3. Improve popup orientation.
   - Highlight the current file.
   - Show clearer row state for a small loop, for example current mark and next target.
   - Keep the popup optimized for 2-3 items, not long lists.

4. Improve popup readability.
   - Show filename first and parent path second when possible.
   - Disambiguate similar paths without making rows noisy.
   - Keep visual structure compact and easy to scan.

### Phase 2: Loop-focused feedback improvements

These improve navigation feel without expanding the feature set.

1. Add compact navigation feedback.
   - On `next()` / `prev()`, show lightweight orientation like `2/3` instead of verbose path-based messages.
   - Prefer minimal, short-lived feedback over full notifications.

2. Improve popup behavior by context.
   - Manual popup: user-controlled close (`q`, `<Esc>`, or explicit action).
   - Automatic popup: short timeout or no popup at all unless configured.

3. Handle dead marks gracefully.
   - If a marked file no longer exists, skip it during `next()` / `prev()`.
   - Warn once if needed, but do not break the movement loop.

### Phase 3: Nice-to-have refinements

Only implement these if they still fit the minimal philosophy after Phases 1 and 2.

1. Add line/column or short code snippet in popup rows.
   - Useful only if it stays visually quiet.

2. Add an optional tiny status indicator.
   - Example: current loop position like `2/3` in statusline or winbar helper.
   - Must remain optional and low-maintenance.

3. Add lightweight Ex commands for discoverability.
   - Example: `:MiniharpNext`, `:MiniharpPrev`, `:MiniharpList`, `:MiniharpToggle`.
   - This is lower priority than core loop improvements.

## Out of Scope

These do not fit the current product direction and should not be prioritized.

1. Fixed numbered slots.
   - Plugin is intentionally built for cycling through a very small set of files.

2. Large-list management features.
   - Reordering, bulk actions, sorting, or heavy interactive list management are not aligned with the current goal.

3. Harpoon-style expansion into a richer workspace manager.
   - If that becomes the goal later, it should be a deliberate product shift.

## Release Communication Plan

Users should be warned when UX behavior changes, especially around popup behavior, notifications, and restore/autoload flow.

### What to communicate in release notes

1. Popup behavior changes.
2. Notification behavior changes.
3. Any new defaults or changed semantics for `show_on_autoload`.
4. Any compatibility notes for existing keymaps or workflows.

### Suggested release note format

1. Summary of user-visible UX changes.
2. Any default behavior changes.
3. Migration notes, if any.
4. Short before/after examples when behavior changes materially.

## Release Automation Plan

### Stable releases

Goal: create a GitHub release automatically whenever a version tag is pushed.

Recommended flow:

1. Merge finished work into `main`.
2. Create and push a version tag from `main`, for example `v0.2.0`.
3. GitHub Actions detects the pushed tag.
4. GitHub Actions creates a GitHub Release automatically.
5. Release notes are generated from the tag and recent changes, with room for a manually curated summary if desired.

Recommended trigger:

1. Workflow trigger: `push.tags: ["v*"]`

Recommended safeguards:

1. Only create releases for semantic version tags.
2. Treat tagged releases as stable and user-facing.
3. Require that tags are created from `main` only.

Recommended workflow file:

1. `.github/workflows/release.yml`

Recommended behavior:

1. Checkout repository.
2. Validate tag format.
3. Generate release notes automatically.
4. Publish GitHub Release for the pushed tag.

## Nightly Automation Plan

Goal: maintain a moving nightly release that always reflects the latest commit on `main`.

Recommended flow:

1. Any new commit pushed to `main` triggers a nightly workflow.
2. Workflow updates a rolling `nightly` tag to point at the latest `main` commit.
3. Workflow recreates or updates a GitHub Release named `nightly`.
4. Release notes clearly state that this build is unstable and auto-updated.

Recommended trigger:

1. Workflow trigger: `push.branches: ["main"]`

Recommended workflow file:

1. `.github/workflows/nightly.yml`

Recommended behavior:

1. Checkout repository with full history.
2. Move `nightly` tag to current `main` commit.
3. Force-push the `nightly` tag.
4. Delete and recreate the `nightly` GitHub Release, or update it in place.
5. Generate notes that include commit SHA and date.

Recommended nightly release content:

1. Title: `nightly`
2. Clear warning that it tracks latest `main` automatically.
3. Short changelog since previous nightly or since last stable release.

## Automation Order

After the UX work starts, implement automation in this order:

1. Add stable release workflow triggered by version tags.
2. Add nightly workflow triggered by pushes to `main`.
3. Test both workflows on a temporary branch or test repository.
4. Document release process in `README.md` or `CONTRIBUTING.md`.

## Recommended Delivery Sequence

1. Phase 1 UX fixes.
2. Phase 2 loop-focused behavior improvements.
3. Stable release automation.
4. Nightly automation.
5. Optional Phase 3 refinements.
6. Documentation refresh after behavior stabilizes.

## First Concrete Milestone

Ship one small release containing:

1. `show_on_autoload` behavior cleanup.
2. Notification noise reduction.
3. Popup current-file highlighting.
4. Updated release notes explaining the new quieter UX.
