local awful = require("awful")
local capi = {
    client = client,
}

---@class scratchpad
---@field command string?: Shell command used to spawn a client.
---@field group table?: A common group of scratchpads.
---@field client client?: Current scratchpad client.
---@field screen screen: The screen that the scratchpad displays to.
---@field client_options table: Proporties applied to the client as scratchpad.
---@field scratchpad_options table: Additional features added to the scratchpad.
local scratchpad = {}

---Constructor for the scratchpad class.
---@param args table: Arguments.
---@return table: Scratchpad object.
function scratchpad:new(args)
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
        reapply_options = false,
        only_one        = false,
    }
    local object = {}
    self.__index = self
    setmetatable(object, self)
    object.has_been_run       = false
    object.command            = args.command
    object.group              = args.group
    object.client             = args.client
    object.screen             = args.screen             or awful.screen.focused()
    object.client_options     = args.client_options     or default_client_options
    object.scratchpad_options = args.scratchpad_options or default_scratchpad_options
    capi.client.connect_signal("request::unmanage", function(current_client)
        if self.client == current_client then
            self.client = nil
        end
    end)
    return object
end

---Gets scratchpad options table and defines any property if it wasn't already defined.
---@return table: Options for the scratchpad.
function scratchpad:get_scratchpad_options()
    local options = {}
    options.reapply_options = self.scratchpad_options.reapply_options or false
    options.only_one        = self.scratchpad_options.only_one        or false
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
---@param client_options table?: Table of options to iterate through.
function scratchpad:set_all_boolean_client_options(bool, client_options)
    client_options = client_options or self:get_client_options()
    for option, _ in pairs(client_options) do
        if
            client_options[option]
            and type(client_options[option]) == "boolean"
        then
            self.client[option] = bool
        end
    end
end

---Enable client properties to the scratchpad as per defined in options table.
function scratchpad:enable_client_options()
    if not self.client then return end
    local client_options = self:get_client_options()
    awful.client.property.set(
        self.client,
        "floating_geometry",
        self.client:geometry({
            x      = self.screen.geometry.x + client_options.geometry.x,
            y      = self.screen.geometry.y + client_options.geometry.y,
            width  = client_options.geometry.width,
            height = client_options.geometry.height,
        })
    )
    self:set_all_boolean_client_options(true, client_options)
end

---Disable any client properties applied to the scratchpad as per defined in the client_options table.
function scratchpad:disable_client_options()
    if not self.client then return end
    local client_options = self:get_client_options()
    if self.client.hidden then
        self.client.hidden = false
        self.client:move_to_tag(awful.tag.selected(self.screen))
    end
    self:set_all_boolean_client_options(false, client_options)
end

function scratchpad:turn_off_other_scratchpads()
    for _, scratchpad_object in pairs(self.group) do
        if
            scratchpad_object.client
            and self.client ~= scratchpad_object.client
            and scratchpad_object.client.hidden == false
        then
            scratchpad_object:turn_off()
        end
    end
end

---Applies a client from the request::manage client signal to the scratchpad.
---Used for when there isnt a current client within the scratchpad.
function scratchpad:apply_client_to_scratchpad()
    local application
    application = function(client)
        self.client = client
        self:enable_client_options()
        capi.client.disconnect_signal("request::manage", application)
    end
    capi.client.connect_signal("request::manage", application)
end

---Enable current scratchpad client visibility.
function scratchpad:turn_on()
    if self.scratchpad_options.only_one then
        self:turn_off_other_scratchpads()
    end
    if self.scratchpad_options.reapply_options then
        self:enable_client_options()
    end
    self.client.hidden = false
    self.client:move_to_tag(awful.tag.selected(self.screen))
    capi.client.focus = self.client
    self.client:raise()
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
        else
            self:turn_off()
        end
    else
        self:apply_client_to_scratchpad()
        if self.command then
            awful.spawn(self.command, false)
            if self.scratchpad_options.only_one then
                self:turn_off_other_scratchpads()
            end
        end
    end
end

function scratchpad:set_client_to_scratchpad(client)
    self.client = client
    self:enable_client_options()
    self.client:raise()
end

---Toggle whether or not the focused client is the scratchpad.
---If it is already a scratchpad, disable its scratchpad status. Otherwise set as the scratchpad.
---@param client client: Client to get set to the current scratchpad.
function scratchpad:toggle_scratched_status(client)
    if self.client then
        self:disable_client_options()
        if self.client == client then
            self.client = nil
        else
            self:set_client_to_scratchpad(client)
        end
    else
        self:set_client_to_scratchpad(client)
    end
end

return scratchpad
