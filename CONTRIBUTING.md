# Contributing

Thanks for helping improve `miniharp.nvim`. This project is intentionally small: keep changes focused, dependency-free, and easy to reason about.

## Project Shape

`miniharp.nvim` is a Lua-only Neovim plugin with no runtime dependencies.

- `lua/miniharp/init.lua` exposes the public API and setup/autocmd behavior.
- `lua/miniharp/core.lua` contains mark navigation and mutation logic.
- `lua/miniharp/ui.lua` contains the floating marks list UI.
- `lua/miniharp/storage.lua` handles per-cwd session persistence.
- `lua/miniharp/marks.lua`, `state.lua`, `utils.lua`, and `notify.lua` hold small supporting modules.
- `nvim_test.lua` is the local development init file for manual testing.
- `README.md` is the user-facing API and behavior reference.

## Development Setup

Use a recent Neovim version and open the plugin with the local test init:

```sh
nvim -u nvim_test.lua
```

This prepends the current checkout to `runtimepath`, configures `miniharp`, and installs development keymaps for marking, jumping, listing, saving, restoring, and clearing marks.

## Making Changes

- Prefer the smallest correct change.
- Keep the plugin dependency-free unless there is a strong reason to change that.
- Preserve the public API exposed from `require('miniharp')` unless the change is intentionally breaking.
- Keep persistence per-cwd and avoid writing project-local state files.
- Update `README.md` when changing user-visible behavior, options, keymaps, or public API.
- Update Lua annotations (`---@class`, `---@field`, `---@param`, `---@return`) when option or data shapes change.
- Keep notifications and status messages short and prefixed with `miniharp:` where appropriate.
- Avoid broad refactors in feature or bug-fix changes.

## Lua Style

Format Lua with StyLua. The repository config is in `.stylua.toml`:

- 4 spaces.
- 80-column width.
- Unix line endings.
- Prefer single quotes where StyLua can choose.
- Always use call parentheses.

Run formatting before submitting:

```sh
stylua lua nvim_test.lua
```

Match the existing module style: small local helpers, clear early returns, and explicit Neovim API calls.

## Manual Testing

There is no full automated test suite in the current repository. Smoke test changes manually with:

```sh
nvim -u nvim_test.lua
```

For behavior changes, test the relevant flow end to end:

- Toggle marks with the development keymaps.
- Jump with next, previous, and direct-position navigation.
- Open, enter, close, and edit the floating list.
- Save and restore marks across Neovim restarts.
- Change cwd when touching persistence behavior.
- Check missing-file handling when touching navigation or storage.
- Test with `notifications = false` when touching messages or notification plumbing.

If you add an automated test harness later, document the command here and keep `nvim_test.lua` useful for quick local checks.

## Conventional Commits

Use Conventional Commits for commit messages:

```text
<type>[optional scope]: <short summary>
```

Use lowercase types. Keep the summary imperative, concise, and focused on user-visible intent when possible.

Common types for this repo:

- `feat`: new user-facing behavior or API.
- `fix`: bug fixes.
- `docs`: documentation-only changes.
- `style`: formatting-only changes with no behavior change.
- `refactor`: code restructuring with no behavior change.
- `test`: test or development test-init changes.
- `ci`: GitHub Actions or automation changes.
- `chore`: maintenance that does not fit the above.

Scopes are optional but useful for focused areas:

- `feat(ui): add interactive mark editing`
- `fix(core): retry direct navigation after missing file removal`
- `docs: document floating list options`
- `style: formatting`
- `ci: generate release notes from tag commits`

Avoid vague commits such as `debug` or `update`. Split unrelated work into separate commits.

Release notes are generated from commit subjects, so make each subject readable on its own. For breaking changes, use `!` in the header or a `BREAKING CHANGE:` footer and describe the migration path.

## Pull Requests

Before opening a PR:

- Format Lua with StyLua.
- Smoke test with `nvim -u nvim_test.lua`.
- Update `README.md` for public behavior changes.
- Mention manual test coverage in the PR description.
- Keep PRs focused on one bug fix, feature, refactor, or docs update.

For UI changes, include a screenshot or short recording when it helps reviewers see the behavior.
