# FrameLink

**FrameLink** is a lightweight, type-safe Luau UI animation and state management framework designed for Roblox. It simplifies window management, handles single-frame visibility constraints, manages audio playback, and automates UI transitions with built-in or custom animations.

Whether you build interfaces using traditional Instance hierarchies or declarative UI frameworks like **Vide**, **Fusion**, or **Roact**, FrameLink integrates seamlessly by allowing optional button binding (`button = nil`) and exposing imperative control methods (`:setOpen()`, `:setClosed()`, `:toggle()`).

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Luau Strict](https://img.shields.io/badge/Luau-Strict-blueviolet.svg)](https://luau-lang.org/)

---

## Key Features

- 🎯 **Automatic State Locking:** Ensures only **one** linked UI frame can be open at a time, smoothly transitioning out active frames before opening new ones.
- ⚛️ **Declarative Framework Support:** Pass `nil` as the trigger button to link frames generated dynamically via **Vide**, **Fusion**, or **Roact/React**, controlling them directly through action hooks or signal callbacks.
- ⚡ **Type-Safe Luau:** Built from the ground up using `--!strict` mode for full autocomplete and static analysis support.
- 📂 **Multi-Linking:** Automatically link whole folders of buttons and corresponding frames with a single method call.
- 🎨 **Built-in Presets:** Out-of-the-box support for popular UI animations like `Pop`, `PopSpin`, `SlideBottom`, `SlideLeft`, `SlideRight`, and `Top`.
- 🧩 **Custom Animation Engine:** Register custom tween definitions globally or pass dynamic per-frame transition tables directly into props.
- 🎧 **Built-in Audio & Overlay Support:** Assign open/close sound effects and modal backdrop buttons directly through property tables.
- 🧹 **Clean Memory Management:** Includes explicit `:destroy()` methods to disconnect connections and cancel active tweens upon unmounting.

---

## Installation

### Manual

Place `FrameLink` inside your project's client hierarchy (e.g., `ReplicatedStorage` or `StarterPlayerScripts`):

```text
FrameLink (ModuleScript)
└── Animations (ModuleScript)

```

### Wally

```toml
[dependencies]
FrameLink = "karlobii/framelink@^1.0.0"

```

---

## Usage Examples

### 1. Traditional Instance Workflow

Link a single trigger button directly to a UI frame:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FrameLink = require(ReplicatedStorage.FrameLink)

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local openButton = mainGui.ShopButton
local shopFrame = mainGui.ShopFrame

-- Link button to frame with a built-in animation preset
local shopWindow = FrameLink.link(openButton, shopFrame, {
    Anim = "Pop",
    CloseButton = shopFrame:FindFirstChild("CloseButton") :: GuiButton,
    Background = mainGui:FindFirstChild("ModalOverlay") :: GuiButton,
    SoundIn = ReplicatedStorage.Sounds.Open,
    SoundOut = ReplicatedStorage.Sounds.Close,
    OnOpened = function(obj)
        print("Shop opened!")
    end,
    OnClosed = function(obj)
        print("Shop closed!")
    end,
})

```

---

### 2. Declarative UI Workflow (Vide, Fusion, etc.)

When using declarative UI libraries, pass `nil` as the first argument (`button`) in `FrameLink.link()`. Control the object imperatively using click events or Vide signals, and return `:destroy()` in Vide's action cleanup callback.

#### Vide Integration Example

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)
local FrameLink = require(ReplicatedStorage.Packages.FrameLink)

local create = Vide.create
local action = Vide.action

local function ShopComponent()
    local shopLink: FrameLink.frameLink?

    return create "Frame" {
        Name = "BigFramey",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        -- Shop Window
        create "Frame" {
            Name = "Shop",
            Size = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),

            -- Link node upon mount
            [action] = function(node: Instance)
                shopLink = FrameLink.link(nil, node :: GuiObject, {
                    Anim = "PopSpin",
                })

                -- Cleanup when Vide unmounts this component
                return function()
                    if shopLink then
                        shopLink:destroy()
                    end
                end
            end,

            create "UICorner" { CornerRadius = UDim.new(0.05, 0) },

            -- Close Button with native Vide handler
            create "TextButton" {
                Name = "CloseButton",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromScale(0.1, 0.1),
                Text = "X",
                Font = Enum.Font.FredokaOne,
                BackgroundColor3 = Color3.new(1, 0, 0),

                Activated = function()
                    if shopLink then
                        shopLink:setClosed()
                    end
                end,
            },
        },

        -- Open Trigger Button
        create "TextButton" {
            Name = "ShopButton",
            Text = "Shop",
            Position = UDim2.fromScale(0.026, 0.574),
            Size = UDim2.fromScale(0.05, 0.05),
            Font = Enum.Font.FredokaOne,

            Activated = function()
                if shopLink then
                    shopLink:toggle()
                end
            end,
        },
    }
end

return ShopComponent

```

---

### 3. Folder-based Linking (`FrameLink.multiLink`)

For traditional static UI structures organized inside folders:

```text
StarterGui
└── MainGui
    ├── Buttons/
    │   ├── Shop
    │   ├── Inventory
    │   └── Settings
    └── Frames/
        ├── Shop (contains CloseButton)
        ├── Inventory (contains CloseButton)
        └── Settings (contains CloseButton)

```

Initialize every interface with a single call:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FrameLink = require(ReplicatedStorage.FrameLink)

local gui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("MainGui")

FrameLink.multiLink(gui.Buttons, gui.Frames, {
    Anim = "PopSpin",
    CloseButtonName = "CloseButton",
    BackgroundName = "ModalOverlay",
    SoundIn = ReplicatedStorage.Sounds.OpenSound,
    SoundOut = ReplicatedStorage.Sounds.CloseSound,
})

```

---

## Built-in Animations

FrameLink includes standard presets provided via the internal `Animations` module:

| Animation Name | Description |
| --- | --- |
| `Pop` | Scales frame up from `0` to its original size using `Back` easing. |
| `PopSpin` | Scales up while un-spinning from `-60°`. |
| `SlideBottom` | Slides in from below the screen (`Y Scale = 1.5`). |
| `Top` | Drops in from above the screen (`Y Scale = -0.5`) with bounce easing. |
| `SlideRight` | Slides in from the right screen boundary (`X Scale = 1.5`). |
| `SlideLeft` | Slides in from the left screen boundary (`X Scale = -0.5`). |
| `SlideLeftSpin` | Slides in from the left screen boundary while rotating 180 degrees. |
| `SlideRightSpin` | Slides in from the right screen boundary while rotating -180 degrees. |

---

## Custom Animations

### Registering Globally

Register custom preset transitions to make them available project-wide:

```lua
local FrameLink = require(ReplicatedStorage.FrameLink)

FrameLink.registerAnimation("FadeScale", {
    InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    StartState = function(defaults)
        return {
            Size = UDim2.new(0, 0, 0, 0),
        }
    end,
    InGoals = function(defaults)
        return {
            Size = defaults.Size,
        }
    end,
    OutGoals = function(defaults)
        return {
            Size = UDim2.new(0, 0, 0, 0),
        }
    end,
})

-- Use your custom registered animation
FrameLink.link(button, frame, { Anim = "FadeScale" })

```

---

## API Reference

### `FrameLink.link(button, frame, props)`

Binds an optional `GuiButton` trigger to a target `GuiObject` frame and returns a `frameLink` instance.

* **`button`**: `GuiButton?` — Optional trigger button. Pass `nil` for declarative framework UI workflows.
* **`frame`**: `GuiObject` — Target UI element.
* **`props`**: `props?` — Configuration parameters (see [Props Reference](https://www.google.com/search?q=%23props-reference)).

### `FrameLink.multiLink(buttonFolder, frameFolder, multiProps)`

Iterates over a folder of buttons, pairing them with matching named frames in a target folder.

### `FrameLink.registerAnimation(name, animDef)`

Adds a custom animation definition table to the global registry.

### Instance Methods (`frameLink`)

```lua
window:setOpen()       -- Opens the frame and automatically closes any previously open active frame
window:setClosed()     -- Closes the frame
window:toggle()        -- Toggles between open/closed states
window:destroy()       -- Cleans up event connections and cancels/destroys active tweens

```

---

## Props Reference

```lua
type props = {
    In: (string | AnimationDefinition)?,       -- Animation name or table for opening
    Out: (string | AnimationDefinition)?,      -- Animation name or table for closing
    Anim: (string | AnimationDefinition)?,     -- Unified animation name or table for both In/Out
    CloseButton: GuiButton?,                   -- Button that explicitly closes the frame
    Background: GuiButton?,                    -- Backdrop overlay button (closes frame on click)
    SoundIn: Sound?,                           -- Sound played when opening
    SoundOut: Sound?,                          -- Sound played when closing
    OnOpened: ((frameLink) -> ())?,            -- Callback executed on open
    OnClosed: ((frameLink) -> ())?,            -- Callback executed on close
    tweenInfoIn: TweenInfo?,                   -- Override TweenInfo for open transition
    tweenInfoOut: TweenInfo?,                  -- Override TweenInfo for close transition
}

```

---

## License

This project is licensed under the **GNU General Public License v3.0** - see the LICENSE file for details.

Copyright (c) 2026 karlobii

```
