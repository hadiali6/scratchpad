# Scratchpad
Scratchpad module for [AwesomeWM](https://github.com/awesomeWM/awesome).

### Showcase
https://github.com/hadiali2006/scratchpad/assets/105244642/b95772b2-3d70-44cd-9b44-3408f5d66829

### Installation
1. Make sure you are on the latest git version of [AwesomeWM](https://github.com/awesomeWM/awesome). 
2. Clone the repository inside your awesome config directory.
```
git clone https://github.com/hadiali2006/scratchpad.git ~/.config/awesome/scratchpad
```
### Usage
<b>Note:</b> This assumes you use the default rc.lua, which can be found on your filesystem in `/etc/xdg/awesome/rc.lua`.  If you use a modular configuration, you can still follow the steps with a few minor differences.
1. At the top of your config where all of the awesome libraries are being initialized:
```lua
-- Initialize scratchpad module.
local scratchpad = require("scratchpad")
```
2. Initialize all instances of the scratchpads you want to use:
```lua
-- Initialize a table which will contain all of your scratchpad objects. 
local pads = {}  
pads.first_pad = scratchpad:new({ -- Initialize scratchpad object.
    command = "alacritty",        -- Command run if there isnt already a client set.
    options = {                   -- All options are optional.
        floating     = true,
        ontop        = true,
        above        = true,
        skip_taskbar = true,
        sticky       = true,
        geometry = {
            width  = 1000,
            height = 1000,
            x      = 360,
            y      = 90,
        },
    }
})
pads.second_pad = scratchpad:new({
    command = "qalculate-qt", 
    options = {
        floating     = true,
        ontop        = true,
        above        = true,
        skip_taskbar = true,
        sticky       = true,
        geometry = {
            width  = 1000,
            height = 1000,
            x      = 360,
            y      = 90,
        },
    }
})
```
3. Add the following binds to your global keybinds: (The keybind is just an example, set it to whatever you want)
```lua
awful.key({ modkey, }, "F1", function ()
    pads.first_pad:toggle_visibility()
end),
awful.key({ modkey, }, "F2", function ()
    pads.second_pad:toggle_visibility()
end),
```
4. Add the following binds to your client keybinds: (The keybind is just an example, set it to whatever you want)
```lua
awful.key({ modkey, "Alt" }, "F1", function (c)
    pads.first_pad:toggle_scratched_status(c)
end),
awful.key({ modkey, "Alt" }, "F2", function (c)
    pads.second_pad:toggle_scratched_status(c)
end),

```
### Details

> ```lua
> scratchpad:new(args)
> ```
> * Constructor for the scratchpad. You can pass in arguments to configure the scratchpad instance.
> * Returns a scratchpad object.

> ```lua
> scratchpad:toggle_visibility()
> ```
> * Toggle current scratchpad client visibility. If there isnt one, spawn a new one.

> ```lua
> scratchpad:toggle_scratched_status(client)
> ```
> * Toggle whether or not the focused client is the scratchpad.
> * If it is already a scratchpad, disable its scratchpad status. Otherwise set passed in client as the scratchpad.

> ```lua
> scratchpad:get_client_options()
> ```
> * Getter for client options table. Will define any property if it wasn't already defined.
> * Returns client options.

> ```lua
> scratchpad:apply_properties()
> ```
> * Apply client properties to the scratchpad as per defined in options table.
> * Not intended for external use.

> ```lua
> scratchpad:unapply_properties()
> ```
> * Disable any client properties applied to the scratchpad as per defined in options table.
> * Not intended for external use.

> ```lua
> scratchpad:turn_on()
> ```
> * Enable current scratchpad client visibility.
> * Not intended for external use.

> ```lua
> scratchpad:turn_off()
> ```
> * Disable current scratchpad client visibility.
> * Not intended for external use.
