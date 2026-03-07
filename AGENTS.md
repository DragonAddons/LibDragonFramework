# LibDragonFramework - Agent Guidelines

Shared options UI framework for Dragon addons. No Ace3 dependencies.

## Build / Lint

```bash
C:\\Users\\lasse\\scoop\\apps\\luarocks\\current\\rocks\\bin\\luacheck.bat .
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
3. **Theme/** - Tokens, Typography, Backdrop, Quality, Spacing
4. **Engine/** - Bindings (widget protocol), Validation, Layout
5. **Display/** - Window, ScrollFrame, TabGroup, Section
6. **Widgets/** - Header, Description, Toggle, Slider, Dropdown, ColorPicker, TextInput, Button

### File Organization (24 files, ~3300 lines)

| Layer | File | Lines |
|-------|------|------:|
| Root | Init.lua | ~88 |
| Core | PixelPerfect.lua | ~244 |
| Core | BaseMixin.lua | ~141 |
| Core | ObjectPool.lua | ~86 |
| Theme | Tokens.lua | ~151 |
| Theme | Typography.lua | ~150 |
| Theme | Backdrop.lua | ~145 |
| Theme | Quality.lua | ~127 |
| Theme | Spacing.lua | ~83 |
| Engine | Bindings.lua | ~107 |
| Engine | Validation.lua | ~75 |
| Engine | Layout.lua | ~150 |
| Display | Window.lua | ~149 |
| Display | ScrollFrame.lua | ~143 |
| Display | TabGroup.lua | ~202 |
| Display | Section.lua | ~79 |
| Widgets | Header.lua | ~46 |
| Widgets | Description.lua | ~60 |
| Widgets | Toggle.lua | ~135 |
| Widgets | Slider.lua | ~264 |
| Widgets | Dropdown.lua | ~326 |
| Widgets | ColorPicker.lua | ~249 |
| Widgets | TextInput.lua | ~120 |
| Widgets | Button.lua | ~112 |

### Key Rules
- **One widget per file, max 300 lines**
- **No Ace3** - this is a standalone library
- **Export only via `_G.LibDragonFramework`** - `ns` is private per-addon
- **Namespace internal state under `self._ldf`** to avoid frame field collisions
- **Pixel-snap disabling scoped to LDF regions only** - no global metatable hooks
- **Composition over inheritance** - mixins, not class hierarchies

### Widget Protocol
Every value widget must implement:
- `widget:SetValue(value)` - set programmatically
- `widget:GetValue()` - return current value
- `widget:SetOnValueChanged(fn)` - live callback during interaction
- `widget:SetOnValueCommitted(fn)` - final callback on confirm
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

## Common Pitfalls
- **Don't use `ns.LDF`** from consuming addons - `ns` is private per-TOC. Always use `_G.LibDragonFramework`.
- **Always use `_ldf`** for internal widget state; never add bare properties to frames.
- **ColorPicker opacity inversion** - Blizzard API uses (1-a) for opacity; LDF handles the conversion.
- **Slider `isInternal` flag** - prevents OnValueChanged feedback loops during programmatic SetValue.

## Code Style
- 4-space indent, no tabs
- File headers with 79-char dashes
- `local LIB_NAME, LDF = ...` in Init.lua only; other files use `local LDF = LibDragonFramework`
- Cache WoW API as locals at file top
- PascalCase functions, camelCase locals, UPPER_SNAKE constants
- Plain hyphens only (no em/en dashes)

## Git
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`
- Squash merge only
