# LibDragonFramework - Agent Guidelines

Shared options UI framework for Dragon addons. No Ace3 dependencies.

## Build / Lint

```bash
luacheck .
```

- `std = "lua51"`, `max_line_length = 120`, `codes = true`
- No external dependencies beyond WoW API and optional LibSharedMedia

## Testing

No automated test harness - all testing is manual in-game.

1. Load LDF in the target client and create a test window with all widget types
2. Verify pixel-perfect rendering by toggling UI scale (0.64 -> 1.0 -> back)
3. Verify Dropdown singleton: open dropdown A, then open dropdown B - A must close
4. Verify ColorPicker dual-path on both Retail (ColorPickerFrame.GetColorRGB) and Classic (ColorPickerFrame:GetColorRGB)
5. Always run luacheck before committing

## Architecture

### Layers (load order)
1. **Init.lua** - namespace bootstrap, `_G.LibDragonFramework = LDF`
2. **Core/** - PixelPerfect, BaseMixin, ObjectPool
3. **Theme/** - Tokens, Typography, Backdrop, Glow, Quality, Spacing
4. **Engine/** - Bindings (widget protocol), Validation, Layout
5. **Display/** - Window, ScrollFrame, TabGroup, Section
6. **Widgets/** - Header, Description, Toggle, Slider, Dropdown, ColorPicker, TextInput, Button, ItemSlot, ItemList

### File Organization (27 files, ~4200 lines)

| Layer | File | Lines |
|-------|------|------:|
| Root | Init.lua | ~88 |
| Core | PixelPerfect.lua | ~244 |
| Core | BaseMixin.lua | ~141 |
| Core | ObjectPool.lua | ~86 |
| Theme | Tokens.lua | ~151 |
| Theme | Typography.lua | ~150 |
| Theme | Backdrop.lua | ~145 |
| Theme | Glow.lua | ~91 |
| Theme | Quality.lua | ~127 |
| Theme | Spacing.lua | ~83 |
| Engine | Bindings.lua | ~107 |
| Engine | Validation.lua | ~75 |
| Engine | Layout.lua | ~210 |
| Display | Window.lua | ~188 |
| Display | ScrollFrame.lua | ~143 |
| Display | TabGroup.lua | ~202 |
| Display | Section.lua | ~157 |
| Widgets | Header.lua | ~46 |
| Widgets | Description.lua | ~60 |
| Widgets | Toggle.lua | ~135 |
| Widgets | Slider.lua | ~264 |
| Widgets | Dropdown.lua | ~326 |
| Widgets | ColorPicker.lua | ~247 |
| Widgets | TextInput.lua | ~120 |
| Widgets | Button.lua | ~112 |
| Widgets | ItemSlot.lua | ~189 |
| Widgets | ItemList.lua | ~289 |

### Key Rules
- **One widget per file, max 300 lines**
- **No Ace3** - this is a standalone library
- **Export only via `_G.LibDragonFramework`** - `ns` is private per-addon
- **Namespace internal state under `self._ldf`** to avoid frame field collisions
- **Pixel-snap disabling scoped to LDF regions only** - no global metatable hooks
- **Composition over inheritance** - mixins, not class hierarchies
- **Layout philosophy** - stack sections vertically, then use grids inside sections for content

### Widget Protocol
Every value widget must implement:
- `widget:SetValue(...)` - set programmatically; payload may be single-value or multi-value by widget type
- `widget:GetValue()` - return the current value payload; may return one or more values by widget type
- `widget:SetOnValueChanged(fn)` - live callback during interaction; `fn` receives the widget value payload
- `widget:SetOnValueCommitted(fn)` - final callback on confirm; `fn` receives the widget value payload
- `widget:SetEnabled(enabled)` - enable/disable
- `widget:SetLabel(text)` - update label
- `widget:Refresh()` - re-read from opts.get()
- `widget:UpdatePixels()` - pixel-perfect recalculation

### Theme Token Reference
Core color tokens in `Theme/Tokens.lua`:
- **Backgrounds**: `bg0` (darkest), `bg1` (panels), `bg2` (inputs)
- **Borders**: `border` (dark edge), `borderLight` (subtle divider)
- **Text**: `text` (primary), `textMuted` (secondary), `textDim` (disabled)
- **Accent**: `accentGold` (1, 0.82, 0) - Dragon signature color
- **State**: `success` (green), `danger` (red), `highlight` (hover)

### Singleton Dropdown Pattern
Dropdown uses ONE shared list frame at module level, re-parented to the active
dropdown on each open. Buttons inside the list are managed via ObjectPool. This
means only one dropdown can be open at a time by design.

### Opts Contract
Preserved from Dragon addons: `{ label, tooltip, get, set, order, disabled }`

### Layout Guidance
- Keep `LDF.CreateStackLayout(...)` behavior stable for outer stacking
- Prefer `LDF.CreateGridLayout(...)` for content regions and section internals
- `LDF.CreateSection(...)` should expose `section.content` for compatibility, but new child placement should usually go through `section:AddChild(...)`
- Layout-managed widgets should keep ordering and span state under `_ldf`

## Common Pitfalls
- **Don't use `ns.LDF`** from consuming addons - `ns` is private per-TOC. Always use `_G.LibDragonFramework`.
- **Always use `_ldf`** for internal widget state; never add bare properties to frames.
- **ColorPicker opacity inversion** - Blizzard API uses (1-a) for opacity; LDF handles the conversion.
- **Slider `isInternal` flag** - prevents OnValueChanged feedback loops during programmatic SetValue.
- **Missing APIs for a target version** -- check `docs/` for the exact client build
- **Race conditions on `PLAYER_ENTERING_WORLD`** -- use a short `C_Timer.After` delay
- **Timer leaks** -- cancel `C_Timer` handles before reusing
- **`GetItemInfo` or item data can be nil on first call** -- retry with a timer

## Code Style
- 4-space indent, no tabs
- File headers with 79-char dashes
- `local LIB_NAME, LDF = ...` in Init.lua only; other files use `local LDF = LibDragonFramework`
- Cache WoW API as locals at file top
- PascalCase functions, camelCase locals, UPPER_SNAKE constants
- Plain hyphens only (no em/en dashes)

```lua
-------------------------------------------------------------------------------
-- FileName.lua
-- Brief description
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------
```

## Git
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`
- Squash merge only

## CI/CD

### Workflows
| Workflow | Trigger | Action |
|----------|---------|--------|
| `lint.yml` | `pull_request_target` to master | Runs luacheck via `Xerrion/wow-workflows/.github/workflows/lint.yml` |
| `release.yml` | Push to master | release-please PR via `Xerrion/wow-workflows`; dispatches `packager.yml` on release |
| `packager.yml` | `workflow_dispatch` (from release.yml) | BigWigsMods packager via `Xerrion/wow-workflows` reusable workflow |

### Branch Protection
- `master` requires passing luacheck before merge
- PRs created by `GITHUB_TOKEN` (release-please) use `pull_request_target` to trigger lint

## Versioning and File Loading
- Do not gate features with runtime version checks
- Split version-specific code into separate files
- Load with TOC `## Interface` / `## Interface-*` directives or packager comment
  directives (`#@retail@`, `#@non-retail@`)
- Packager directives are comments locally, so later files can override earlier ones

## Error Handling
- Use defensive nil checks for optional APIs (e.g., ColorPickerFrame methods vary by version)
- Use `pcall` for version-specific APIs that may be missing in some clients
- Use `error(msg, 2)` for public library input validation (reports at caller site)
- For version differences, prefer `or` fallbacks over runtime version checks

## GitHub Workflow

### Issues

Create issues using the repo's issue templates (`.github/ISSUE_TEMPLATE/`):
- **Bug reports**: Use `bug-report.yml` template. Title prefix: `[Bug]: `
- **Feature requests**: Use `feature-request.yml` template. Title prefix: `[Feature]: `

Create via CLI:
```bash
gh issue create --repo DragonAddons/LibDragonFramework --label "bug" --title "[Bug]: <title>" --body "<body matching template fields>"
gh issue create --repo DragonAddons/LibDragonFramework --label "enhancement" --title "[Feature]: <title>" --body "<body matching template fields>"
```

### Branches

Use conventional branch prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat/` | New feature | `feat/12-grid-layout` |
| `fix/` | Bug fix | `fix/15-dropdown-zorder` |
| `refactor/` | Code improvement | `refactor/20-pool-cleanup` |

Include the issue number in the branch name when linked to an issue.

### Commits
Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat: <description> (#issue)` - new feature
- `fix: <description> (#issue)` - bug fix
- `refactor: <description> (#issue)` - code restructuring
- `docs: <description>` - documentation only

### Pull Requests
1. Create PRs via CLI using the repo's `.github/PULL_REQUEST_TEMPLATE.md` format
2. Set the PR title explicitly with `--title`. Do not rely on `gh pr create` defaults.
3. PR titles must use Conventional Commit style and should usually match the primary commit intent.
4. If the branch has multiple commits, write the PR title as a clean Conventional Commit summary of the overall change.
5. Set the PR body explicitly with `--body` or `--body-file`. Do not leave it empty.
6. PR bodies should include short `## Summary`, `## Changes`, and `## Testing` sections.
7. Link to the issue with `Closes #N` in the PR body
8. PRs require passing status checks (luacheck, test) before merge
9. Squash merge only: `gh pr merge <number> --squash`
10. Branches are auto-deleted after merge

### Project Boards
When a repo has a GitHub Projects board, update issue status as work progresses:

| Phase | Board Status | Action |
|-------|-------------|--------|
| Triaged/planned | Ready | Issue is understood and ready for work |
| Work starts | In progress | Add comment describing the approach |
| PR created | In review | Add comment with PR link |
| PR merged | Done | Auto-updated by GitHub automation or manual move |

Use `gh project` CLI commands to update board status:
```bash
gh project item-list <PROJECT_NUMBER> --owner DragonAddons --format json
gh project field-list <PROJECT_NUMBER> --owner DragonAddons --format json
gh project item-edit --project-id <ID> --id <ITEM_ID> --field-id <FIELD_ID> --single-select-option-id <OPTION_ID>
```

Add comments on issues at each phase transition to maintain a clear audit trail.

---

## Working Agreement for Agents
- Addon-level AGENTS.md overrides root rules when present
- Do not add new dependencies without discussing trade-offs
- Run luacheck before and after changes
- If only manual tests exist, document what you verified in-game
- Verify changes in the game client when possible
- Keep changes small and focused; prefer composition over inheritance

---

## Communication Style

When responding to or commenting on issues, always write in **first-person singular** ("I")
as the repo owner -- never use "we" or "our team". Speak as if you are the developer personally.

**Writing style:**
- Direct, structured, solution-driven. Get to the point fast. Text is a tool, not decoration.
- Think in systems. Break things into flows, roles, rules, and frameworks.
- Bias toward precision. Concrete output, copy-paste-ready solutions, clear constraints. Low
  tolerance for fluff.
- Tone is calm and rational with small flashes of humor and self-awareness.
- When confident in a topic, become more informal and creative.
- When something matters, become sharp and focused.
