# FrameLink

**FrameLink** is a lightweight, scalable UI management module for Roblox. It seamlessly links `GuiButtons` to `Frames`, handling opening and closing animations, sound effects, state management (ensuring only one frame is open at a time), and background dimming.

With its newly data-driven animation system, you can easily plug in your own custom tweens without touching the core logic.

---

## Features

* **Modular Animation System:** Animations are stored in a separate child module. Add new tweens instantly just by passing a dictionary!
* **Zero-Delay Defaults:** If no animation is provided, frames open and close instantly with zero latency.
* **Smart State Management:** Automatically closes the currently open frame before opening a new one. Prevents awkward overlaps and double-clicking bugs.
* **Multi-Link Support:** Link entire folders of buttons to folders of frames in a single line of code.
* **Rich Callbacks & Accessories:** Built-in support for background dimming buttons, close (X) buttons, open/close sound effects, and `OnOpened`/`OnClosed` event hooks.

---

## Installation

### Rbxm
1. Download the newest release file with the `.rbxm` file extension.
2. Import it into Studio using `File -> Import Roblox Model -> Select FrameLink.rbxm`.
3. Drag the model into `ReplicatedStorage`.

---

### Wally
```text
FrameLink = "karlobii/framelink@^1.0.0"
```

---

### Manual
1. Create a `ModuleScript` inside `ReplicatedStorage` (or your preferred UI directory) and name it `FrameLink`. Paste the code from `src/FrameLink.luau` into it.
2. Create a second `ModuleScript` **inside** `FrameLink`, name it `Animations`, and paste the code from `src/Animations.luau` into it.

Your explorer should look like this:

```text
ReplicatedStorage
 └── FrameLink (ModuleScript)
      └── Animations (ModuleScript)

```

---

## Usage

### Basic Single Link

To link a single button to a frame, require the module and use `FrameLink.link()`.

```lua
local FrameLink = require(game.ReplicatedStorage.FrameLink)

local myButton = script.Parent.OpenMenuButton
local myFrame = script.Parent.MenuFrame
local closeButton = myFrame.CloseButton

FrameLink.link(myButton, myFrame, {
    Anim = "Pop",             -- Uses the "Pop" animation from the Animations module
    XButton = closeButton,    -- Automatically closes the frame when clicked
    SoundIn = someSoundPath,  -- Plays when opening
    OnOpened = function()
        print("Menu opened!")
    end
})

```

### Multi-Linking

If you have a sidebar with multiple buttons (e.g., Shop, Inventory, Settings) that correspond to frames with the exact same names, you can link them all at once.

```lua
local buttonsFolder = script.Parent.SidebarButtons
local framesFolder = script.Parent.MenuFrames

FrameLink.multiLink(buttonsFolder, framesFolder, {
    Anim = "SlideRight",
    XButtonName = "CloseBtn",      -- Looks for a button named "CloseBtn" inside each frame
    BackgroundName = "DimmerBg"    -- Looks for a background button to close the frame when clicking away
})

```

---

## Creating Custom Animations

The biggest feature of FrameLink is the **Animations module**. You no longer need to write massive `if/elseif` blocks to add new UI behaviors.

To add a new animation, simply open the `Animations` module and add a new dictionary. The module passes a `defaults` table (containing the frame's original Size, Position, and Rotation) so your animations always know how to reset correctly.

### Example: Adding a "FadeOut" Animation

Add this to your `Animations` ModuleScript:

```lua
Animations.DropAndFade = {
    -- 1. Define TweenInfos
    InfoIn = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    
    -- 2. Define where the frame should start BEFORE the 'In' tween plays
    StartState = function(defaults) 
        return { 
            Position = UDim2.new(defaults.Position.X.Scale, defaults.Position.X.Offset, -1, 0)
        } 
    end,
    
    -- 3. Define the goal for the 'In' tween (usually back to defaults)
    InGoals = function(defaults) 
        return { Position = defaults.Position } 
    end,
    
    -- 4. Define the goal for the 'Out' tween
    OutGoals = function(defaults) 
        return { Position = UDim2.new(defaults.Position.X.Scale, defaults.Position.X.Offset, 1.5, 0) } 
    end,
}

```

Now, you can immediately use `Anim = "DropAndFade"` in your props!

---

## API Reference (Props)

When calling `.link()` or `.multiLink()`, you can pass a `props` dictionary to customize the behavior.

| Property | Type | Description |
| --- | --- | --- |
| `Anim` | `string` | The name of the animation to use for both In and Out (e.g., "Pop", "SlideRight"). |
| `In` | `string` | Specify a unique animation ONLY for opening. (Overwritten by Anim) |
| `Out` | `string` | Specify a unique animation ONLY for closing. (Overwritten by Anim) |
| `XButton` | `GuiButton` | A button that, when clicked, will close the frame. |
| `Background` | `GuiButton` | A background (like a dark transparent overlay) that becomes visible when the frame opens, and closes the frame when clicked. |
| `SoundIn` | `Sound` | A sound object to play when the frame opens. |
| `SoundOut` | `Sound` | A sound object to play when the frame closes. |
| `OnOpened` | `function` | A callback function fired the moment the In-animation completes (or instantly if no animation). |
| `OnClosed` | `function` | A callback function fired the moment the Out-animation completes. |
| `tweenInfoIn` | `TweenInfo` | Overrides the default `TweenInfo` for the In-animation. |
| `tweenInfoOut` | `TweenInfo` | Overrides the default `TweenInfo` for the Out-animation. |
