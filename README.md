# LibDragonFramework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Lint](https://img.shields.io/github/actions/workflow/status/DragonAddons/LibDragonFramework/lint.yml?label=lint&style=flat-square)](https://github.com/DragonAddons/LibDragonFramework/actions/workflows/lint.yml)

Standalone options UI framework for World of Warcraft addons.

## Overview

LibDragonFramework (LDF) provides a themed options panel system with no Ace3 dependency. It was extracted and enhanced from the Dragon addon family (DragonToast, DragonLoot) into a reusable library.

- **Pixel-perfect rendering** - `GetPhysicalScreenSize`-based snapping for crisp edges at any resolution
- **Centralized theme** - Dark charcoal backgrounds, gold accent, Friz Quadrata typography
- **Full widget protocol** - Two-phase value commits (live change + final commit callbacks)
- **Multi-version** - Retail, Cata Classic, MoP Classic, TBC Anniversary, Classic Era
- **Zero dependencies** - No Ace3, no LibStub; optional LibSharedMedia integration

## Supported Versions

| Version          | Interface          |
| ---------------- | ------------------ |
| Retail           | 110207             |
| Cata Classic     | 120000, 120001     |
| MoP Classic      | 50502, 50503       |
| TBC Anniversary  | 20505              |

## Installation

### Embed as a submodule

```bash
git submodule add https://github.com/DragonAddons/LibDragonFramework Libs/LibDragonFramework
```

Then load it in your `.toc`:

```text
Libs\LibDragonFramework\LibDragonFramework.toc
```

### Manual

Copy the `LibDragonFramework` folder into your addon's `Libs/` directory and reference the TOC as above.

### Access

LDF exports itself as a global. Grab a reference at the top of any file:

```lua
local LDF = LibDragonFramework
```

## Quick Start

```lua
local LDF = LibDragonFramework

-- Create main window
local window = LDF.CreateWindow({
    name = "MyAddonOptions",
    title = "My Addon Options",
    width = 400,
    height = 500,
})

-- Add widgets to window content
local content = window.content

local header = LDF.CreateHeader(content, "General Settings")
header:SetPoint("TOPLEFT", 0, 0)
header:SetPoint("RIGHT")

local toggle = LDF.CreateToggle(content, {
    label = "Enable Feature",
    tooltip = "Toggles the main feature on or off",
    get = function() return MyAddonDB.enabled end,
    set = function(v) MyAddonDB.enabled = v end,
})
toggle:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
toggle:SetPoint("RIGHT")
```

## Architecture

LDF is organized in five layers, loaded in strict order:

```text
1. Core      PixelPerfect, BaseMixin, ObjectPool
2. Theme     Tokens, Typography, Backdrop, Quality, Spacing
3. Engine    Bindings (widget protocol), Validation, Layout
4. Display   Window, ScrollFrame, TabGroup, Section
5. Widgets   Header, Description, Toggle, Slider, Dropdown,
             ColorPicker, TextInput, Button, ItemSlot, ItemList
```

**Core** provides pixel-snapping math, a mixin system for frame composition, and a generic object pool. **Theme** centralizes all visual tokens (colors, fonts, backdrops, quality mappings, spacing constants). **Engine** defines the widget protocol, validates opts tables, and handles layout calculations. **Display** builds the container hierarchy (windows, scroll regions, tabs, collapsible sections). **Widgets** implement the individual controls that consumers interact with.

## Widget Catalog

| Widget | Factory | Type | Description |
| ------ | ------- | ---- | ----------- |
| Header | `LDF.CreateHeader(parent, text)` | Display | Gold section header with separator line |
| Description | `LDF.CreateDescription(parent, text)` | Display | Word-wrapped gray description text |
| Toggle | `LDF.CreateToggle(parent, opts)` | Value | Checkbox with label and tooltip |
| Slider | `LDF.CreateSlider(parent, opts)` | Value | Slider with editbox and min/max labels |
| Dropdown | `LDF.CreateDropdown(parent, opts)` | Value | Scrollable dropdown with LSM preview |
| ColorPicker | `LDF.CreateColorPicker(parent, opts)` | Value | Color swatch (Retail + Classic API) |
| TextInput | `LDF.CreateTextInput(parent, opts)` | Value | Single-line text input field |
| Button | `LDF.CreateButton(parent, opts)` | Action | Styled action button |
| ItemSlot | `LDF.CreateItemSlot(parent, opts)` | Value | Single item slot with icon and quality border |
| ItemList | `LDF.CreateItemList(parent, opts)` | Value | Scrollable grid of item slots |

**Display** widgets render static content. **Value** widgets bind to data via `get`/`set`. **Action** widgets fire a callback on click.

### ItemSlot

```lua
LDF.CreateItemSlot(parent, opts)
```

Single item display slot with icon, quality border coloring, and drag-and-drop support.

- `opts.size` - slot size in pixels (default 36)
- `opts.showTooltip` - show GameTooltip on hover (default true)
- `opts.onAccept` - callback fired when an item is dropped onto the slot, receives `itemID`
- `opts.onRemove` - callback fired when an item is right-click removed, receives `itemID`

Item info is fetched via `GetItemInfo` with automatic retry (up to 3 attempts) when data is not yet cached.

**Methods:**

| Method | Description |
| ------ | ----------- |
| `SetItem(itemID)` | Set the displayed item (nil clears the slot) |
| `GetItem()` | Return the current item ID or nil |
| `ClearItem()` | Remove the item and reset to empty state |
| `SetEnabled(state)` | Enable or disable the slot |

**Interactions:** Left-click accepts a cursor item, right-click removes the current item, hover shows a tooltip.

### ItemList

```lua
LDF.CreateItemList(parent, opts)
```

Scrollable grid of `ItemSlot` widgets managed by an `ObjectPool`. Displays a "+" add-slot when below the maximum item count, and a configurable empty-text placeholder when the list is empty.

- `opts.get` - function returning a table of `{ [itemID] = true }` (required)
- `opts.set` - function receiving the updated items table (required)
- `opts.label` - header label text
- `opts.emptyText` - placeholder text when empty (default "Drop items here")
- `opts.slotSize` - individual slot size in pixels (default 36)
- `opts.slotsPerRow` - grid columns (default 6)
- `opts.maxItems` - maximum number of items (default 30)

**Methods:**

| Method | Description |
| ------ | ----------- |
| `GetValue()` | Return the current items table |
| `SetValue(items)` | Replace the items table and rebuild the grid |
| `Refresh()` | Re-read from `opts.get()` and rebuild |
| `AddItem(itemID)` | Add an item (no-op if duplicate or at max) |
| `RemoveItem(itemID)` | Remove an item by ID |
| `GetItemCount()` | Return the number of items |
| `SetEnabled(state)` | Enable or disable the list and hide the add-slot when disabled |

## Widget Protocol

### Opts Contract

Every value widget accepts an `opts` table:

```lua
{
    label = "My Widget",         -- display label
    tooltip = "Help text",       -- GameTooltip on hover
    get = function() end,        -- value getter
    set = function(value) end,   -- value setter (fired on change)
    order = 1,                   -- layout sort order
    disabled = function() end,   -- dynamic disable check
}
```

### Two-Phase Callbacks

Value widgets support two change callbacks:

- `SetOnValueChanged(fn)` - fires continuously during interaction (drag, typing)
- `SetOnValueCommitted(fn)` - fires once on final confirmation (mouse release, Enter key)

This lets you preview changes live while only persisting the final value.

### Standard Methods

All value widgets implement:

| Method | Description |
| ------ | ----------- |
| `SetValue(value)` | Set the value programmatically |
| `GetValue()` | Return the current value |
| `SetOnValueChanged(fn)` | Register live change callback |
| `SetOnValueCommitted(fn)` | Register final commit callback |
| `SetEnabled(enabled)` | Enable or disable the widget |
| `SetDisabled(state)` | Backward-compat shim - calls `SetEnabled(not state)` (deprecated) |
| `SetLabel(text)` | Update the display label |
| `Refresh()` | Re-read the value from `opts.get()` |
| `UpdatePixels()` | Recalculate pixel-perfect sizing |

> **Note:** All widgets inherit `SetDisabled(state)` from `BaseMixin` as a backward-compatibility shim. New code should use `SetEnabled(enabled)` instead.

## Display Containers

| Container | Factory | Purpose |
| --------- | ------- | ------- |
| Window | `LDF.CreateWindow(opts)` | Top-level draggable panel with title bar and close button |
| ScrollFrame | `LDF.CreateScrollFrame(parent, opts)` | Scrollable content region with mousewheel support |
| TabGroup | `LDF.CreateTabGroup(parent, opts)` | Horizontal tab bar that swaps child panels |
| Section | `LDF.CreateSection(parent, title, opts)` | Collapsible group with header |

Containers can nest freely. A typical layout is Window > TabGroup > ScrollFrame > widgets.

### Window

```lua
LDF.CreateWindow(opts)
-- opts = { name, title, width, height }
```

Returns a top-level draggable panel parented to `UIParent`. The `name` field is required and used as the global frame name for ESC-close registration.

- `window.content` - content area frame below the title bar
- `window:SetTitle(text)` - update the title bar text
- `window:Toggle()` - show or hide the window

Auto-handles close button (Retail `UIPanelCloseButton` with fallback), title bar drag-to-move, and ESC-closable via `UISpecialFrames`.

### Section

```lua
LDF.CreateSection(parent, title, opts)
```

Titled content group with separator line. Content goes inside `section.content` (or `section:GetContent()`).

- `opts.collapsible` (bool) - adds a chevron indicator and clickable header region
- `opts.collapsed` (bool) - initial collapsed state (default false)

**Methods:**

| Method | Description |
| ------ | ----------- |
| `SetTitle(text)` | Update the section header |
| `GetContent()` | Return the content frame |
| `UpdateHeight()` | Recalculate section height from content |

**Additional methods when `opts.collapsible = true`:**

| Method | Description |
| ------ | ----------- |
| `SetCollapsed(collapsed)` | Expand or collapse the section |
| `ToggleCollapsed()` | Toggle between expanded and collapsed |
| `IsCollapsed()` | Return whether the section is collapsed |

**Callback:** `SECTION_TOGGLED` fires via `LDF.FireCallback` when a collapsible section is toggled, receiving the section frame and the collapsed state.

## Theme Customization

LDF exposes the theme system for per-addon color and font overrides:

```lua
LDF.AddColor("myAddonAccent", 0.2, 0.8, 1.0, 1.0)
LDF.SetAccentColor("myAddonAccent")
LDF.AddFontPreset("myTitle", { path = LDF.FONT_PATH, size = 16, flags = "OUTLINE" })
```

Default theme tokens:

| Token | Value |
| ----- | ----- |
| Background | Dark charcoal (`0.1, 0.1, 0.1`) |
| Accent | Gold (`1.0, 0.82, 0.0`) |
| Font | Friz Quadrata TT |
| Quality colors | Standard Blizzard item quality palette |
| Spacing | Compact 4/8/12/16px scale |

## License

MIT - See [LICENSE](LICENSE) file.
