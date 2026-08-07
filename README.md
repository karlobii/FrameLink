```markdown
# FrameLink

**FrameLink** is a lightweight, type-safe Luau UI animation and state management framework designed for Roblox. It simplifies window management, handles single-frame visibility constraints, manages audio playback, and automates UI transitions with built-in or custom animations.

Whether you build interfaces using traditional Instance hierarchies or declarative UI frameworks like **Vide**, **Fusion**, or **Roact**, FrameLink integrates seamlessly by allowing optional button binding (`button = nil`) and exposing imperative control methods (`:setOpen()`, `:setClosed()`, `:toggle()`).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Luau Strict](https://img.shields.io/badge/Luau-Strict-blueviolet.svg)](https://luau-lang.org/)

---

## Key Features

- 🎯 **Automatic State Locking:** Ensures only **one** linked UI frame can be open at a time, smoothly transitioning out active frames before opening new ones.
- ⚛️ **Declarative Framework Support:** Pass `nil` as the trigger button to link frames generated dynamically via **Vide**, **Fusion**, or **Roact/React**, controlling them directly through action hooks or signal callbacks.
- ⚡ **Type-Safe Luau:** Built from the ground up using `--!strict` mode for full autocomplete and static analysis support.
- 📂 **Multi-Linking:** Automatically link whole folders of buttons and corresponding frames with a single method call.
- 🎨 **Built-in Presets:** Out-of-the-box support for popular UI animations like `Pop`, `PopSpin`, `SlideBottom`, `SlideLeft`, `SlideRight`, and `Top`.
- 🧩 **Custom Animation Engine:** Register custom tween definitions globally or pass dynamic per-frame transitions.
- 🎧 **Built-in Audio & Overlay Support:** Assign open/close sound effects and modal backdrop buttons directly through property tables.

---

# Install

## Manual

Place `FrameLink` inside your project's client hierarchy (e.g., `ReplicatedStorage` or `StarterPlayerScripts`):

```text
FrameLink (ModuleScript)
└── Animations (ModuleScript)

```

## Wally

```text
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
    CloseButton = shopFrame:FindFirstChild("CloseButton"),
    Background = mainGui:FindFirstChild("ModalOverlay"),
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

When using declarative UI libraries, pass `nil` as the first argument (`button`) in `FrameLink.link()`. This creates a `FrameLinkObj` managed directly through state handlers or click events.

#### Vide Integration Example

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)
local FrameLink = require(ReplicatedStorage.Packages.FrameLink)

local create = Vide.create
local action = Vide.action

local function ShopComponent()
    local shopLink: FrameLink.FrameLinkObj?

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

            -- Capture reference to node upon creation and link without explicit button
            action(function(node: Instance)
                shopLink = FrameLink.link(nil, node :: GuiObject, {
                    Anim = "PopSpin",
                    CloseButton = node:FindFirstChild("CloseButton") :: GuiButton,
                })
            end),

            create "UICorner" { CornerRadius = UDim.new(0.05, 0) },

            create "TextButton" {
                Name = "CloseButton",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromScale(0.1, 0.1),
                Text = "X",
                Font = Enum.Font.FredokaOne,
                BackgroundColor3 = Color3.new(1, 0, 0),
            },
        },

        -- Open Trigger Button
        create "TextButton" {
            Name = "ShopButton",
            Text = "Shop",
            Position = UDim2.fromScale(0.026, 0.574),
            Size = UDim2.fromScale(0.05, 0.05),
            Font = Enum.Font.FredokaOne,

            -- Call the FrameLink instance methods imperatively
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

FrameLink includes standard presets provided via the `Animations` submodule:

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

Register custom preset transitions to make them available across all scripts:

```lua
local FrameLink = require(ReplicatedStorage.FrameLink)

FrameLink.registerAnimation("FadeScale", {
    InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    StartState = function(defaults)
        return {
            Size = UDim2.new(0, 0, 0, 0),
            GroupTransparency = 1,
        }
    end,
    InGoals = function(defaults)
        return {
            Size = defaults.Size,
            GroupTransparency = 0,
        }
    end,
    OutGoals = function(defaults)
        return {
            Size = UDim2.new(0, 0, 0, 0),
            GroupTransparency = 1,
        }
    end,
})

-- Use your custom animation
FrameLink.link(button, frame, { Anim = "FadeScale" })

```

---

## API Reference

### `FrameLink.link(button, frame, props)`

Binds an optional `GuiButton` trigger to a target `GuiObject` frame and returns a `FrameLinkObj` instance.

* **`button`**: `GuiButton?` — Optional trigger button that toggles frame visibility. Pass `nil` for declarative framework UI workflow.
* **`frame`**: `GuiObject` — Target UI element.
* **`props`**: `Props?` — Config object (see [Props Reference](https://www.google.com/search?q=%23props-reference)).

### `FrameLink.multiLink(buttonFolder, frameFolder, multiProps)`

Iterates over a folder of buttons, pairing them with named frames in a frame folder.

### `FrameLink.registerAnimation(name, animDef)`

Adds a named `AnimationDefinition` table to the internal registry.

### Instance Methods (`FrameLinkObj`)

```lua
window:setOpen()   -- Opens the frame and closes any previously opened active frame
window:setClosed() -- Closes the frame
window:toggle()    -- Toggles between open/closed states
window:destroy()   -- Disconnects events and cancels active tweens

```

---

## Props Reference

```lua
type Props = {
    In: (string | AnimationDefinition)?,        -- Animation for opening
    Out: (string | AnimationDefinition)?,       -- Animation for closing
    Anim: (string | AnimationDefinition)?,      -- Unified animation for both In/Out
    CloseButton: GuiButton?,                   -- Button that explicitly closes the frame
    Background: GuiButton?,                    -- Backdrop overlay button (closes frame on click)
    SoundIn: Sound?,                           -- Sound played when opening
    SoundOut: Sound?,                          -- Sound played when closing
    OnOpened: ((FrameLinkObj) -> ())?,         -- Callback executed on open
    OnClosed: ((FrameLinkObj) -> ())?,         -- Callback executed on close
    tweenInfoIn: TweenInfo?,                   -- Override TweenInfo for open transition
    tweenInfoOut: TweenInfo?,                  -- Override TweenInfo for close transition
}

```

---

## License

Copyright (c) 2026 karlobii

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

```

```#   F r a m e L i n k  
 