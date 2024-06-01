---@meta
---@module "group"

--[[
Scratchpad Group module for AwesomeWM.
]]--

local math = math
local pairs = pairs
local rawset = rawset
local require = require
local setmetatable = setmetatable
local string = string
local table = table
local tostring = tostring

local gears = require("gears")
local utils = require(tostring(...):match(".*scratchpad.lua") .. ".utils")

---@class group: gears.object
---@field id string: Identifier.
---@field scratchpads table<string|number, scratchpad>: Table of scratchpads.
local group = {}

---Constructor of the Scratchpad Group object.
---@param args table: Arguments.
---@return group: Scratchpad group object.
function group:new(args)
    local object = setmetatable({}, self)
    self.__index = self
    args.validate = args.validate or true
    object.id          = args.id          or string.sub(math.random(), 3)
    object.scratchpads = args.scratchpads or {}
    if args.validate then
        if not utils.validate_group_config(object) then
            error("Invalid scratchpad group config")
        end
    end
    return gears.object({ class = object })
end

---@param new_scratchpad scratchpad
function group:add_scratchpad(new_scratchpad)
    for key, scratchpad in pairs(self.scratchpads) do
        if scratchpad.id == new_scratchpad.id then
            rawset(self.scratchpads, key, new_scratchpad)
            return
        end
    end
    table.insert(self.scratchpads, new_scratchpad)
end

---@param scratchpad_id string
---@return scratchpad
function group:remove_scratchpad(scratchpad_id)
    local ret
    for key, scratchpad in pairs(self.scratchpads) do
        if scratchpad_id == scratchpad.id then
            rawset(self.scratchpads, key, nil)
        end
    end
    return ret
end

---@param scratchpad_id string: Identifier string of scratchpad object we are looking for.
---@param key string|number: Key corresponding to the location of the scratchpad in the table of scratchpads.
---@return scratchpad: Scratchpad object.
function group:get_scratchpad(scratchpad_id, key)
    if key then return self.scratchpads[key] end
    local ret
    for _, scratchpad in pairs(self.scratchpads) do
        if scratchpad_id == scratchpad.id then
            ret = scratchpad
            break
        end
    end
    return ret
end

---@param callback fun(scratchpad: scratchpad): nil
function group:do_for_each_scratchpad(callback)
    for _, scratchpad in pairs(self.scratchpads) do
        callback(scratchpad)
    end
end

---@param scratchpad_id string
---@param callback fun(scratchpad: scratchpad): nil
function group:do_for_scratchpad(scratchpad_id, callback)
    for _, scratchpad in pairs(self.scratchpads) do
        if scratchpad_id == scratchpad.id then
            callback(scratchpad)
            break
        end
    end
end

return group
