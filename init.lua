local require = require
local scratchpad = {}
scratchpad.object = require(... .. ".lua.object")
scratchpad.group  = require(... .. ".lua.group")
scratchpad.utils  = require(... .. ".lua.utils")
return scratchpad
