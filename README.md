# Scratchpad
A Scratchpad module for [AwesomeWM](https://github.com/awesomeWM/awesome).

## What is a Scratchpad?
It's a window in which you can toggle its visibility while keeping it running in the background. It's mainly used in conjunction with a main set of windows, only opening your "scratchpad" for a few seconds. For example, you could use it for a music application or a calculator.

## Showcase
https://github.com/hadiali6/scratchpad/assets/105244642/b95772b2-3d70-44cd-9b44-3408f5d66829

## Installation
1. Make sure you are on the latest git version of [AwesomeWM](https://github.com/awesomeWM/awesome). 
2. Clone the repository inside your awesome config directory.
```
git clone https://github.com/hadiali6/scratchpad.git ~/.config/awesome/scratchpad
```
## Usage
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
    group   = pads,
    client_options = {            -- All options are optional.
        floating     = true,
        ontop        = false,
        above        = false,
        skip_taskbar = false, -- These are the defaults if you don't specify client_options.
        sticky       = false,
        geometry = {
            width  = 1200,
            height = 900,
            x      = 360,
            y      = 90,
        },
    },
    scratchpad_options = { -- These are the defaults if you don't specify scratchpad_options.
        reapply_options = false,
        only_one        = false,
    },
})
pads.second_pad = scratchpad:new({
    command = "qalculate-qt",
    group   = pads,
    client_options = {
        floating     = true,
        ontop        = false,
        above        = false,
        skip_taskbar = false,
        sticky       = false,
        geometry = {
            width  = 1200,
            height = 900,
            x      = 360,
            y      = 90,
        },
    },
    scratchpad_options = {
        reapply_options = false,
        only_one        = false,
    },
})
```
3. Add the following binds to your global keybinds: (The keybind is just an example, set it to whatever you want)
```lua
awful.key({ modkey, }, "F1", function()
    pads.first_pad:toggle_visibility()
end),
awful.key({ modkey, }, "F2", function()
    pads.second_pad:toggle_visibility()
end),
```
4. Add the following binds to your client keybinds: (The keybind is just an example, set it to whatever you want)
```lua
awful.key({ modkey, "Alt" }, "F1", function(c)
    pads.first_pad:toggle_scratched_status(c)
end),
awful.key({ modkey, "Alt" }, "F2", function(c)
    pads.second_pad:toggle_scratched_status(c)
end),
```
## Details
| Object Fields        | Type          | Description                                     |
| :------------------- | :--------:    | :---------------------------------------------- |
| `id`                 | `string`      | Identifier. Defaults to random numbers.         |
| `command`            | `string\|nil` | Shell command used to spawn a client.           |
| `group`              | `table\|nil`  | A common group of scratchpads.                  |
| `client`             | `client\|nil` | Current scratchpad client.                      |
| `screen`             | `screen`      | The screen that the scratchpad displays to.     |
| `client_options`     | `table`       | Proporties applied to the client as scratchpad. |
| `scratchpad_options` | `table`       | Additional features added to the scratchpad.    |

| Public Functions      | Description                                                                                                                                                                                            |
| :-------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:new(args) -> table` | Constructor for the scratchpad class.                                                                                                                                                                  |
| `:turn_on()`          | Enable current scratchpad client visibility.                                                                                                                                                           |
| `:turn_off()`         | Disable current scratchpad client visibility.                                                                                                                                                          |
| `:toggle()`           | Toggle current scratchpad client visibility. If there isnt one, spawn a new one.                                                                                                                       |
| `:set(client)`        | Set a new clinet into the scratchpad at runtime. If it's already within the scratchpad, eject the client into the current tag. Otherwise set the passed in client to the client within the scratchpad. |

## Configuration
### Client Options
See the [offical documentaion for the client module](https://awesomewm.org/apidoc/core_components/client.html) within AwesomeWM.
##### Defaults
These are the default client options if you don't define them within your configuration:
```lua
floating = true,
ontop = false,
above = false,
skip_taskbar = false,
sticky = false,
geometry = { width = 1200, height = 900, x = 360, y = 90, }
```

### Scratchpad Options
##### Reapply Options
If true, the client options will be reapplied every time you turn it on. For example when you move or resize the client, it will go back to its original state when you turn it back on.
##### Only One
If true, there will only be one scratchpad allowed on the screen at a time. You must define a group as it iterates through the group to hide the other scratchpads. If a scratchpad in another group is on, then it won't be hidden.
<!-- ##### Clone Focus On Lost -->
<!-- If true, the scratchpad will hide itself when it loses focus. <b>NOTE:</b> This currently has issues when the previous focused window is a big gui application like firefox, gimp, and libreoffice.  -->

##### Defaults
These are the default scratchpad options if you don't define them within your configuration:
```lua
scratchpad_options = {
    reapply_options = false,
    only_one = false,
}
```
