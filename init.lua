local awful = require("awful")
local capi = {
    client = client,
}

---@class scratchpad
---@field has_been_run boolean: If the scratchpad has been run in any way.
---@field command string?: Shell command used to spawn a client.
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
    }
    local object = {}
    self.__index = self
    setmetatable(object, self)
    object.has_been_run       = false
    object.command            = args.command
    object.client             = args.client
    object.screen             = args.screen             or awful.screen.focused()
    object.client_options     = args.client_options     or default_client_options
    object.scratchpad_options = args.scratchpad_options or default_scratchpad_options
    return object
end

---Gets scratchpad options table and defines any property if it wasn't already defined.
---@return table: Options for the scratchpad.
function scratchpad:get_scratchpad_options()
    local options = {}
    options.reapply_options = self.scratchpad_options.reapply_options or false
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

---Enable client properties to the scratchpad as per defined in options table.
function scratchpad:enable_properties()
    if not self.client then
        return
    end
    local client_options = self:get_client_options()
    local screen_geometry = self.screen.geometry
    if client_options.floating then
        self.client:set_floating(true)
    end
    if client_options.skip_taskbar then
        self.client.skip_taskbar = true
    end
    if client_options.ontop then
        self.client.ontop = true
    end
    if client_options.above then
        self.client.above = true
    end
    if client_options.sticky then
        self.client.sticky = true
    end
    awful.client.property.set(
        self.client,
        "floating_geometry",
        self.client:geometry({
            x      = screen_geometry.x + client_options.geometry.x,
            y      = screen_geometry.y + client_options.geometry.y,
            width  = client_options.geometry.width,
            height = client_options.geometry.height,
        })
    )
end

---Disable any client properties applied to the scratchpad as per defined in the client_options table.
function scratchpad:disable_properties()
    if not self.client then
        return
    end
    local client_options = self:get_client_options()
    if self.client.hidden then
        self.client.hidden = false
        self.client:move_to_tag(awful.tag.selected(self.screen))
    end
    if client_options.floating then
        self.client:set_floating(false)
    end
    if client_options.skip_taskbar then
        self.client.skip_taskbar = false
    end
    if client_options.ontop then
        self.client.ontop = false
    end
    if client_options.above then
        self.client.above = false
    end
    if client_options.sticky then
        self.client.sticky = false
    end
end

---Connect unmanage signal if there hasn't been usage of toggle_visibility() or toggle_scratched_status()
function scratchpad:connect_unmanage_signal()
    if self.has_been_run == false then
        self.has_been_run = true
        capi.client.connect_signal("request::unmanage", function(current_client)
            if self.client == current_client then
                self.client = nil
            end
        end)
    end
end

---Enable current scratchpad client visibility.
function scratchpad:turn_on()
    if self.scratchpad_options.reapply_options then
        self:enable_properties()
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
    self:connect_unmanage_signal()
    if self.client then
        if self.client.hidden then
            self:turn_on()
        else
            self:turn_off()
        end
    else
        local initial_apply
        initial_apply = function(client)
            self.client = client
            self:enable_properties()
            capi.client.disconnect_signal("request::manage", initial_apply)
        end
        capi.client.connect_signal("request::manage", initial_apply)
        if self.command then
            awful.spawn(self.command, false)
        end
    end
end

function scratchpad:set_client_to_scratchpad(client)
    self.client = client
    self:enable_properties()
    self.client:raise()
end

---Toggle whether or not the focused client is the scratchpad.
---If it is already a scratchpad, disable its scratchpad status. Otherwise set as the scratchpad.
---@param client client: Client to get set to the current scratchpad.
function scratchpad:toggle_scratched_status(client)
    self:connect_unmanage_signal()
    if self.client then
        self:disable_properties()
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
