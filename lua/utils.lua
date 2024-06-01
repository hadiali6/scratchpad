local pairs = pairs
local require = require
local type = type

local awful = require("awful")

local utils = {}

---Mutates a table with any value it doesnt have from a given source table.
---@param target table
---@param source table
---@return table
utils.combine = function(target, source)
    for k, v in pairs(source) do
        if not target[k] then
            target[k] = v
        end
    end
    return target
end

---@param bool boolean: What to set to all client options.
---@param client client: Client to mutate.
---@param table table: Table of options to iterate through.
utils.set_boolean_client_options = function(bool, client, table)
    for option, _ in pairs(table) do
        if table[option] and type(table[option]) == "boolean" then
            client[option] = bool
        end
    end
end

---@param client client
---@param screen screen
---@param properties table
utils.enable_client_properties = function(client, screen, properties)
    utils.set_boolean_client_options(true, client, properties)
    client:geometry({
        x      = screen.geometry.x + properties.geometry.x,
        y      = screen.geometry.y + properties.geometry.y,
        width  = properties.geometry.width,
        height = properties.geometry.height,
    })
end

---@param client client
---@param screen screen
---@param properties table
utils.disable_client_properties = function(client, screen, properties)
    utils.set_boolean_client_options(false, client, properties)
    if client.hidden then
        client.hidden = false
        client:move_to_tag(screen.selected_tag)
    end
end

---@param client client
---@param screen screen
utils.enable_client = function(client, screen)
    client.hidden = false
    client:move_to_tag(awful.tag.selected(screen))
    client:activate({})
end

---@param client client
utils.disable_client = function(client)
    client.hidden = true
    client:tags({})
end

---@param args table
utils.validate_scratchpad_config = function(args)
    local id_good = false
    local cmd_good = false
    local group_good = false
    local screen_good = false
    local client_options_good = false
    local scratchpad_options_good = false
    for k, v in pairs(args) do
        if k == "id" and type(v) == "string" then
            id_good = true
        end
        if k == "command" and (type(v) == "string" or type(v) == "nil") then
            cmd_good = true
        end
        if k == "group" and (type(v) == "table" or type(v) == "nil") then
            group_good = true
        end
        if k == "screen" and (type(v) == "screen" or type(v) == "nil") then
            screen_good = true
        end
        if k == "client_options" and type(v) == "table" then
            client_options_good = true
        end
        if k == "scratchpad_options" and type(v) == "table" then
            scratchpad_options_good = true
        end
    end
    return id_good
        and cmd_good
        and group_good
        and screen_good
        and client_options_good
        and scratchpad_options_good
end

---@param args table
utils.validate_group_config = function(args)
    local id_good = false
    local scratchpads_good = false
    for k, v in pairs(args) do
        if k == "id" and type(v) == "string" then
            id_good = true
        end
        if k == "scratchpads" and type(v) == "table" then
            scratchpads_good = true
        end
    end
    return id_good and scratchpads_good
end

return utils
