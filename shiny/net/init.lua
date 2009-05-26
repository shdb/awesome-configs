local beautiful = require("beautiful")
local wicked = require("wicked")

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
    open = io.open,
    popen = io.popen,
    close = io.close
}
local string = {
    find = string.find
}
local widget, button, mouse, image = widget, button, mouse, image

local net_if = nil
local essid = nil
local last_update = 0

module("shiny.net")
local icon = widget({ type = "imagebox", align = "right" })
local infobox = widget({type = "textbox", name = "netbox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })

local graph_down = widget({
   type  = 'graph',
   name  = 'netgraph_down',
   align = 'right'
})
local graph_up = widget({
    type  = 'graph',
    name  = 'netgraph_up',
    align = 'right'
})
graph_down.height = 0.85
graph_down.width = 35
graph_down.bg = beautiful.graph_bg
graph_down.border_color = beautiful.bg_normal
graph_down.grow = 'right'

graph_up.height = 0.85
graph_up.width = 35
graph_up.bg = beautiful.graph_bg
graph_up.border_color = beautiful.bg_normal
graph_up.grow = 'right'

graph_down:plot_properties_set('down', {
    fg                = beautiful.fg_normal,
    vertical_gradient = false
})
graph_up:plot_properties_set('up', {
    fg                = beautiful.fg_normal,
    vertical_gradient = false
})

local function fg(color, text)
    if not color then
        color = "#555555"
    end
    return '<span color="' .. color .. '">' .. text .. '</span>'
end

function bold(text)
    return '<b>' .. text .. '</b>'
end

local function file_exists(filename)
    local file = io.open(filename)
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

local function get_up()
    local lfd, wfd, lan, wlan
    lfd = io.open("/sys/class/net/eth0/operstate")
    lan = lfd:read()
    lfd:close()
    if file_exists("/sys/class/net/wlan0/operstate") then
        wfd = io.open("/sys/class/net/wlan0/operstate")
        wlan = wfd:read()
        wfd:close()
    end
    if lan and lan == "up" then
        return "br0"
    elseif wlan and wlan == "up" then
        return "wlan0"
    else
        return nil
    end
end

local function get_essid(iface)
    local f = io.popen("/sbin/iwgetid " .. iface)
    local ret = ""
    for line in f:lines() do
        local _, _, essid = string.find(line, "ESSID:\"(.*)\"")
        if essid then
            ret = ret .. essid
        end
    end
    f:close()
    return ret
end

local function update()
    local nif = get_up()
    if not nif then
        wicked.unregister(graph_down, false)
        wicked.unregister(graph_up, false)
        openbox.text = ""
        icon.image = nil
        net_if = nil
        return ""
    elseif net_if ~= nif then
        wicked.unregister(graph_down, true)
        wicked.unregister(graph_up, true)
        wicked.register(graph_down, wicked.widgets.net,"${" .. nif .. " down_kb}",1,"down")
        wicked.register(graph_up, wicked.widgets.net,"${" .. nif .. " up_kb}",1,"up")
        net_if = nif
        if nif == "wlan0" then
            icon.image = image(beautiful.wireless)
            openbox.text = fg(beautiful.hilight, "[ ")
            essid = get_essid(nif)
            return bold(essid) .. fg(beautiful.hilight, " ] ")
        elseif nif == "br0" then
            icon.image = image(beautiful.network)
            openbox.text = ""
            return ""
        end
    elseif nif == "wlan0" then
        last_update = last_update + 1
        if last_update == 3 then
            last_update = 0
            essid = get_essid(nif)
        end
        return bold(essid) .. fg(beautiful.hilight, " ] ")
    end
end

wicked.register(infobox, update, "$1", 5)

setmetatable(_M, { __call = function () return {openbox, icon, infobox, graph_down, graph_up} end })
