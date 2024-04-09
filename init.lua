local awful = require("awful")
local capi = {
    client = client,
    mouse  = mouse,
    screen = screen
}

local scratchpad = {}
local has_been_run = false

function scratchpad:new(args)
    local obj = {}

    self.__index = self
    setmetatable(obj, self)

    obj.command = args.command
    obj.rule    = args.rule
    obj.options = args.options
    obj.client  = args.client
    obj.screen  = args.screen or awful.screen.focused()

    return obj
end

function scratchpad:get_client_options()
    local tbl = {}
    tbl.ontop    = self.options.ontop    or false
    tbl.above    = self.options.above    or false
    tbl.hidden   = self.options.hidden   or false
    tbl.sticky   = self.options.sticky   or false
    tbl.floating = self.options.floating or false
    if self.options.geometry then
        tbl.geometry = {
            width  = self.options.geometry.width  or 1200,
            height = self.options.geometry.height or 900,
            x      = self.options.geometry.x      or 360,
            y      = self.options.geometry.y      or 90,
        }
    else
        tbl.geometry = {
            width  = 1200,
            height = 900,
            x      = 360,
            y      = 90,
        }
    end
    return tbl
end

function scratchpad:apply_props()
    local props = self:get_client_options()
    if self.client then
        local screen_workarea = self.screen.workarea
        local screen_geometry = self.screen.geometry

        if props.floating then
            self.client:set_floating(true)
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

        self.client.skip_taskbar = true
    end
end

function scratchpad:unapply_props()
    local props = self:get_client_options()
    if self.client then
        if self.client.hidden then
            self.client.hidden = false
            self.client:move_to_tag(awful.tag.selected(self.screen))
        end
        if props.floating then
            self.client:set_floating(false)
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
        self.client.skip_taskbar = false
    end
end

function scratchpad:startup()
    if has_been_run == false then
        has_been_run = true
        capi.client.connect_signal("request::unmanage", function (current_client)
            if self.client == current_client then
                self.client = nil
            end
        end)
    end
end

function scratchpad:toggle()
    self:startup()
    if not self.client then
        local initial_apply; initial_apply = function (c)
            self.client = c
            self:apply_props()
            capi.client.disconnect_signal("request::manage", initial_apply)
        end

        capi.client.connect_signal("request::manage", initial_apply)
        awful.spawn(self.command, false)
    else
        if self.client:isvisible() == false then
            self.client.hidden = true
            self.client:move_to_tag(awful.tag.selected(self.screen))
        end

        if self.client.hidden then
            self.client.hidden = false
            self.client:raise()
            capi.client.focus = self.client
        else
            self.client.hidden = true
            local ctags = self.client:tags()
            for i, _ in pairs(ctags) do
                ctags[i] = nil
            end
            self.client:tags(ctags)
        end
    end
end

function scratchpad:set(client)
    local function setscratch(c)
        self.client = c
        self:apply_props()
    end
    self:startup()
    if not self.client then
        self.client = client
        setscratch(self.client)
    else
        self:unapply_props()
        if self.client == client then
            self.client = nil
        else
            self.client = client
            setscratch(client)
        end
    end
end

return scratchpad
