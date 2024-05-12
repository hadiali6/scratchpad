local awful = require("awful")
local gears = require("gears")
local math, pairs, setmetatable, string, type = math, pairs, setmetatable, string, type
local capi = { client = client }

---@class scratchpad: gears.object
---@field id? string Identifier.
---@field command string|nil Shell command used to spawn a client.
---@field group table|nil A common group of scratchpads.
---@field client client|nil Current scratchpad client.
---@field screen? screen|nil The screen that the scratchpad displays to.
---@field client_options? table Proporties applied to the client as scratchpad.
---@field scratchpad_options? table Additional features added to the scratchpad.
local scratchpad = {}

---Constructor for the scratchpad class.
---@param args? table: Arguments.
---@return scratchpad: Scratchpad object inheriting from gears.object.
function scratchpad:new(args)
    args = args or {}
    local default_client_options = {
        floating     = true,
        ontop        = false,
        above        = false,
        skip_taskbar = false,
        sticky       = false,
        geometry = { width = 1200, height = 900, x = 360, y = 90, },
    }
    local default_scratchpad_options = {
        reapply_options     = false,
        only_one            = false,
        close_on_focus_lost = false,
    }
    local object = setmetatable({}, self)
    self.__index = self
    object.id                 = args.id                 or string.sub(math.random(), 3)
    object.command            = args.command
    object.group              = args.group
    object.client             = args.client
    object.screen             = args.screen             or awful.screen.focused()
    object.client_options     = args.client_options     or default_client_options
    object.scratchpad_options = args.scratchpad_options or default_scratchpad_options
    return gears.object({ class = object })
end

---@param bool boolean: What to set to all client options.
---@param client client: Client to mutate.
---@param table table: Table of options to iterate through.
local set_all_boolean_client_options_to = function(bool, client, table)
    for option, _ in pairs(table) do
        if table[option] and type(table[option]) == "boolean" then
            client[option] = bool
        end
    end
end

---Gets client options table and defines any property if it wasn't already defined.
---@param scratchpad_object scratchpad: Scratchpad Object to get options from.
---@return table: Options for the scratchpad client.
local function get_client_options(scratchpad_object)
    local options = {}
    options.floating     = scratchpad_object.client_options.floating     or false
    options.skip_taskbar = scratchpad_object.client_options.skip_taskbar or false
    options.ontop        = scratchpad_object.client_options.ontop        or false
    options.above        = scratchpad_object.client_options.above        or false
    options.sticky       = scratchpad_object.client_options.sticky       or false
    if scratchpad_object.client_options.geometry then
        options.geometry = {
            width  = scratchpad_object.client_options.geometry.width  or 1200,
            height = scratchpad_object.client_options.geometry.height or 900,
            x      = scratchpad_object.client_options.geometry.x      or 360,
            y      = scratchpad_object.client_options.geometry.y      or 90,
        }
    else
        options.geometry = {
            width  = 1200,
            height = 900,
            x      = 360,
            y      = 90,
        }
    end
    return options
end

---Enable client properties to the scratchpad as per defined in options table.
---@param scratchpad_object scratchpad: Scratchpad Object to mutate.
local function enable_client_properties(scratchpad_object)
    if not scratchpad_object.client then return end
    local client_options = get_client_options(scratchpad_object)
    set_all_boolean_client_options_to(true, scratchpad_object.client, client_options)
    scratchpad_object.client:geometry({
        x      = scratchpad_object.screen.geometry.x + client_options.geometry.x,
        y      = scratchpad_object.screen.geometry.y + client_options.geometry.y,
        width  = client_options.geometry.width,
        height = client_options.geometry.height,
    })
end

---Disable any client properties applied to the scratchpad as per defined in the client_options table.
---@param scratchpad_object scratchpad: Scratchpad Object to mutate.
local function disable_client_properties(scratchpad_object)
    if not scratchpad_object.client then return end
    set_all_boolean_client_options_to(false, scratchpad_object.client, get_client_options(scratchpad_object))
    if scratchpad_object.client.hidden then
        scratchpad_object.client.hidden = false
        scratchpad_object.client:move_to_tag(awful.tag.selected(scratchpad_object.screen))
    end
end

---Applies signals for when the client is created, killed or set at runtime.
---Applies signals for any field in scratchpad_options set to true.
---Used for when there isnt a current client within the scratchpad.
---@param scratchpad_object scratchpad: Scratchpad Object to connect/disconnect signals to.
local function apply_signals(scratchpad_object)
    ---Callback function for the scratchpad::only_one signal.
    ---@param current_scratchpad scratchpad
    local only_one = function(current_scratchpad)
        if not current_scratchpad.group then return end
        for _, object in pairs(current_scratchpad.group) do
            if
                object.client
                and object.client ~= current_scratchpad.client
                and object.client.hidden == false
            then
                object:turn_off()
            end
        end
    end
    do
        local connect_scratchpad_option_signals = function()
            if scratchpad_object.scratchpad_options.reapply_options then
                scratchpad_object:connect_signal("scratchpad::reapply_options", enable_client_properties)
            end
            if scratchpad_object.scratchpad_options.only_one then
                scratchpad_object:connect_signal("scratchpad::only_one", only_one)
            end
        end
        local apply_client
        apply_client = function(client)
            scratchpad_object.client = client
            connect_scratchpad_option_signals()
            enable_client_properties(scratchpad_object)
            capi.client.disconnect_signal("request::manage", apply_client)
        end
        capi.client.connect_signal("request::manage", apply_client)
    end
    do
        local disconnect_scratchpad_option_signals = function()
            if scratchpad_object.scratchpad_options.reapply_options then
                scratchpad_object:disconnect_signal("scratchpad::reapply_options", enable_client_properties)
            end
            if scratchpad_object.scratchpad_options.only_one then
                scratchpad_object:disconnect_signal("scratchpad::only_one", only_one)
            end
        end
        local remove_client
        remove_client = function(client)
            if scratchpad_object.client == client then
                disconnect_scratchpad_option_signals()
                scratchpad_object.client = nil
                capi.client.disconnect_signal("request::unmanage", remove_client)
            end
        end
        capi.client.connect_signal("request::unmanage", remove_client)
    end
end

---Enable current scratchpad client visibility.
function scratchpad:turn_on()
    self:emit_signal("scratchpad::reapply_options")
    self:emit_signal("scratchpad::only_one")
    self.client.hidden = false
    self.client:move_to_tag(awful.tag.selected(self.screen))
    capi.client.focus = self.client
    self.client:raise()
    self:emit_signal("scratchpad::on")
end

---Disable current scratchpad client visibility.
function scratchpad:turn_off()
    self.client.hidden = true
    local client_tags = self.client:tags()
    for i, _ in pairs(client_tags) do
        client_tags[i] = nil
    end
    self.client:tags(client_tags)
    self:emit_signal("scratchpad::off")
end

---Toggle current scratchpad client visibility. If there isnt one, spawn a new one.
function scratchpad:toggle()
    if not self.client then
        apply_signals(self)
        if self.command then
            awful.spawn(self.command, false)
            self:emit_signal("scratchpad::on")
            self:emit_signal("scratchpad::only_one")
        end
        return
    end
    if self.client.hidden then
        self:turn_on()
    else
        self:turn_off()
    end
end

---Set a new clinet into the scratchpad at runtime.
---If it's already within the scratchpad, eject the client into the current tag.
---Otherwise set the passed in client to the client within the scratchpad.
---@param new_client client: Client to get set to the current scratchpad.
function scratchpad:set(new_client)
    ---@param client client
    local set_client_to_scratchpad = function(client)
        self.client = client
        apply_signals(self)
        capi.client.emit_signal("request::manage", self.client)
        self.client:raise()
    end
    if self.client then
        disable_client_properties(self)
        capi.client.emit_signal("request::unmanage", self.client)
        if self.client ~= new_client then
            set_client_to_scratchpad(new_client)
        end
    else
        set_client_to_scratchpad(new_client)
    end
end

return scratchpad
