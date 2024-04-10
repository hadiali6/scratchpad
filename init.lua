local awful = require("awful")
local capi = {
    client = client,
    mouse  = mouse,
    screen = screen
}

---@class scratchpad
---@field has_been_run boolean: If the scratchpad has been run in any way.
---@field command string: Shell command used to spawn a client.
---@field options table: Proporties applied to the client as scratchpad.
---@field client client?: Current scratchpad client.
---@field screen screen: The screen that the scratchpad displays to.
local scratchpad = {}

---Constructor for the scratchpad class.
---@return table: Scratchpad object.
function scratchpad:new(args)
    local obj = {}
    self.__index = self
    setmetatable(obj, self)
    obj.has_been_run = false
    obj.command      = args.command or "alacritty"
    obj.options      = args.options
    obj.client       = args.client
    obj.screen       = args.screen or awful.screen.focused()
    return obj
end

---Getter for client options table. Will define any property if it wasn't already defined.
---@return table: Client options.
function scratchpad:get_client_options()
    local options = {}
    options.floating     = self.options.floating     or false
    options.skip_taskbar = self.options.skip_taskbar or false
    options.ontop        = self.options.ontop        or false
    options.above        = self.options.above        or false
    options.sticky       = self.options.sticky       or false
    if self.options.geometry then
        options.geometry = {
            width  = self.options.geometry.width  or 1200,
            height = self.options.geometry.height or 900,
            x      = self.options.geometry.x      or 360,
            y      = self.options.geometry.y      or 90,
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

---Apply client properties to the scratchpad as per defined in options table.
function scratchpad:apply_properties()
    if not self.client then
        return
    end
    local props = self:get_client_options()
    local screen_workarea = self.screen.workarea
    local screen_geometry = self.screen.geometry

    if props.floating then
        self.client:set_floating(true)
    end
    if props.skip_taskbar then
        self.client.skip_taskbar = true
    end
    if props.ontop then
        self.client.ontop = true
    end
    if props.above then
        self.client.above = true
    end
    if props.sticky then
        self.client.sticky = true
    end
    if props.width and props.width <= 1 then
        props.width = screen_workarea.width * props.width
    end
    if props.height and props.height <= 1 then
        props.height = screen_workarea.height * props.height
    end
    awful.client.property.set(self.client, "floating_geometry", self.client:geometry({
        x      = screen_geometry.x + props.geometry.x,
        y      = screen_geometry.y + props.geometry.y,
        width  = props.geometry.width,
        height = props.geometry.height,
    }))
end

---Disable any client properties applied to the scratchpad as per defined in options table.
function scratchpad:unapply_properties()
    if not self.client then
        return
    end
    local props = self:get_client_options()
    if self.client.hidden then
        self.client.hidden = false
        self.client:move_to_tag(awful.tag.selected(self.screen))
    end
    if props.floating then
        self.client:set_floating(false)
    end
    if props.skip_taskbar then
        self.client.skip_taskbar = false
    end
    if props.ontop then
        self.client.ontop = false
    end
    if props.above then
        self.client.above = false
    end
    if props.sticky then
        self.client.sticky = false
    end
end

---Connect unmanage signal if there hasn't been usage of toggle() or set()
function scratchpad:connect_unmanage_signal()
    if self.has_been_run == false then
        self.has_been_run = true
        capi.client.connect_signal("request::unmanage", function (current_client)
            if self.client == current_client then
                self.client = nil
            end
        end)
    end
end

---Enable current scratchpad client visibility.
function scratchpad:turn_on()
    self.client.hidden = false
    self.client:move_to_tag(awful.tag.selected(self.screen))
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
    self:connect_unmanage_signal()
    if not self.client then
        local initial_apply
        initial_apply = function (client)
            self.client = client
            self:apply_properties()
            capi.client.disconnect_signal("request::manage", initial_apply)
        end
        capi.client.connect_signal("request::manage", initial_apply)
        awful.spawn(self.command, false)
    else
        if self.client.hidden then
            self:turn_on()
        else
            self:turn_off()
        end
    end
end

function scratchpad:set_client_to_scratchpad(client)
    self.client = client
    self:apply_properties()
end

---Toggle whether or not the focused client is the scratchpad.
---If it is already a scratchpad, disable its scratchpad status. Otherwise set as the scratchpad.
---@param client client: Client to get set to the current scratchpad.
function scratchpad:toggle_scratched_status(client)
    self:connect_unmanage_signal()
    if not self.client then
        self:set_client_to_scratchpad(client)
    else
        self:unapply_properties()
        if self.client == client then
            self.client = nil
        else
            self:set_client_to_scratchpad(client)
        end
    end
end

return scratchpad
