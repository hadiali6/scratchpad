local awful = require("awful")
local gears = require("gears")
local capi = { client = client }

---Scratchpad Module for AwesomeWM.
---@class scratchpad: gears.object
---@field id? string Identifier. Defaults to a string of random numbers.
---@field command string|nil Shell command used to spawn a client.
---@field group table|nil A common group of scratchpads.
---@field client client|nil Current scratchpad client.
---@field screen? screen|nil The screen that the scratchpad displays to. Defaults to awful.screen.focused().
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
        geometry = {
            width  = 1200,
            height = 900,
            x      = 360,
            y      = 90,
        },
    }
    local default_scratchpad_options = {
        reapply_options     = false,
        only_one            = false,
        close_on_focus_lost = false,
    }
    local object = {}
    self.__index = self
    setmetatable(object, self)
    object.id                 = args.id                 or string.sub(math.random(), 3)
    object.command            = args.command
    object.group              = args.group
    object.client             = args.client
    object.screen             = args.screen             or awful.screen.focused()
    object.client_options     = args.client_options     or default_client_options
    object.scratchpad_options = args.scratchpad_options or default_scratchpad_options
    return gears.object({ class = object })
end

---Gets scratchpad options table and defines any property if it wasn't already defined.
---@return table: Options for the scratchpad.
function scratchpad:get_scratchpad_options()
    local options = {}
    options.reapply_options     = self.scratchpad_options.reapply_options     or false
    options.only_one            = self.scratchpad_options.only_one            or false
    options.close_on_focus_lost = self.scratchpad_options.close_on_focus_lost or false
    return options
end

---Gets client options table and defines any property if it wasn't already defined.
---@return table: Options for the scratchpad client.
function scratchpad:get_client_options()
    local options = {}
    options.floating     = self.client_options.floating     or false
    options.skip_taskbar = self.client_options.skip_taskbar or false
    options.ontop        = self.client_options.ontop        or false
    options.above        = self.client_options.above        or false
    options.sticky       = self.client_options.sticky       or false
    if self.client_options.geometry then
        options.geometry = {
            width  = self.client_options.geometry.width  or 1200,
            height = self.client_options.geometry.height or 900,
            x      = self.client_options.geometry.x      or 360,
            y      = self.client_options.geometry.y      or 90,
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


---@param bool boolean: What to set to all client options.
---@param client client: Client to mutate.
---@param table table: Table of options to iterate through.
local function set_all_boolean_client_options_to(bool, client, table)
    for option, _ in pairs(table) do
        if table[option] and type(table[option]) == "boolean" then
            client[option] = bool
        end
    end
end

---Enable client properties to the scratchpad as per defined in options table.
function scratchpad:enable_client_options()
    if not self.client then return end
    local client_options = self:get_client_options()
    set_all_boolean_client_options_to(true, self.client, client_options)
    self.client:geometry({
        x      = self.screen.geometry.x + client_options.geometry.x,
        y      = self.screen.geometry.y + client_options.geometry.y,
        width  = client_options.geometry.width,
        height = client_options.geometry.height,
    })
end

---Disable any client properties applied to the scratchpad as per defined in the client_options table.
function scratchpad:disable_client_options()
    if not self.client then return end
    local client_options = self:get_client_options()
    set_all_boolean_client_options_to(false, self.client, client_options)
    if self.client.hidden then
        self.client.hidden = false
        self.client:move_to_tag(awful.tag.selected(self.screen))
    end
end

function scratchpad:turn_off_other_scratchpads()
    if not self.group then return end
    for _, scratchpad_object in pairs(self.group) do
        if
            scratchpad_object.client
            and scratchpad_object.client ~= self.client
            and scratchpad_object.client.hidden == false
        then
            scratchpad_object:turn_off()
        end
    end
end

---Applies signals for when the client is created or killed.
---Applies signals for any field in scratchpad_options set to true.
---Used for when there isnt a current client within the scratchpad.
function scratchpad:apply_client_signals_to_scratchpad()
    ---Callback function for scratchpad::reapply_options signal.
    ---@param object scratchpad
    local reapply_options = function(object)
        if object == self then object:enable_client_options() end
    end

    ---Callback function for scratchpad::only_one signal.
    ---@param object scratchpad
    local only_one = function(object)
        if object == self then object:turn_off_other_scratchpads() end
    end

    ---Callback function for unfocus signal.
    ---@param focused_client client
    local unfocus_client = function(focused_client)
        if
            self.client
            and self.client == focused_client
            and self.client ~= awful.client.focus.history.get()
        then
            self:turn_off()
        end
    end

    do
        local disconnect_scratchpad_option_signals = function()
            if self.scratchpad_options.reapply_options then
                self:disconnect_signal("scratchpad::reapply_options", reapply_options)
            end
            if self.scratchpad_options.only_one then
                self:disconnect_signal("scratchpad::only_one", only_one)
            end
            if self.scratchpad_options.close_on_focus_lost then
                capi.client.disconnect_signal("unfocus", unfocus_client)
            end
        end

        local remove_client
        ---@param client client
        remove_client = function(client)
            if self.client == client then
                self.client = nil
                capi.client.disconnect_signal("request::unmanage", remove_client)
            end
            disconnect_scratchpad_option_signals()
        end
        capi.client.connect_signal("request::unmanage", remove_client)
    end

    do
        local connect_scratchpad_option_signals = function()
            if self.scratchpad_options.reapply_options then
                self:connect_signal("scratchpad::reapply_options", reapply_options)
            end
            if self.scratchpad_options.only_one then
                self:connect_signal("scratchpad::only_one", only_one)
            end
            if self.scratchpad_options.close_on_focus_lost then
                capi.client.connect_signal("unfocus", unfocus_client)
            end
        end

        local add_client
        ---@param client client
        add_client = function(client)
            self.client = client
            self:enable_client_options()
            connect_scratchpad_option_signals()
            capi.client.disconnect_signal("request::manage", add_client)
        end
        capi.client.connect_signal("request::manage", add_client)
    end
end

---Enable current scratchpad client visibility.
function scratchpad:turn_on()
    self:emit_signal("scratchpad::only_one")
    self:emit_signal("scratchpad::reapply_options")
    self.client.hidden = false
    self.client:move_to_tag(awful.tag.selected(self.screen))
    self.client:raise()
    capi.client.focus = self.client
end

---Disable current scratchpad client visibility.
function scratchpad:turn_off()
    self.client.hidden = true
    local client_tags = self.client:tags()
    for i, _ in pairs(client_tags) do
        client_tags[i] = nil
    end
    self.client:tags(client_tags)
end

---Toggle current scratchpad client visibility. If there isnt one, spawn a new one.
function scratchpad:toggle_visibility()
    if self.client then
        if self.client.hidden then
            self:turn_on()
            self:emit_signal("scratchpad::visibility_on")
        else
            self:turn_off()
            self:emit_signal("scratchpad::visibility_off")
        end
    else
        self:apply_client_signals_to_scratchpad()
        if self.command then
            awful.spawn(self.command, false)
            self:emit_signal("scratchpad::visibility_on")
            self:emit_signal("scratchpad::only_one")
            self:emit_signal("scratchpad::reapply_options")
        end
    end
end

---Set a new clinet into the scratchpad at runtime.
---If it's already within the scratchpad, eject the client into the current tag.
---Otherwise set the passed in client to the client within the scratchpad.
---@param new_client client: Client to get set to the current scratchpad.
function scratchpad:set_new_client(new_client)
    ---@param client client
    local set_client_to_scratchpad = function(client)
        self.client = client
        self:apply_client_signals_to_scratchpad()
        self:enable_client_options()
        self.client:raise()
    end

    if self.client then
        self:disable_client_options()
        capi.client.emit_signal("request::unmanage", self.client)
        if self.client == new_client then
            self.client = nil
        else
            set_client_to_scratchpad(new_client)
        end
    else
        set_client_to_scratchpad(new_client)
    end
end

return scratchpad
