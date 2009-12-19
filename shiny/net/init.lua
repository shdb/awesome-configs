local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
    open = io.open,
    popen = io.popen,
    close = io.close
}
local string = {
    find = string.find,
    sub  = string.sub
}
local math = { floor = math.floor }
local os = { time = os.time }
local widget, button, mouse, image, table, tostring
    = widget, button, mouse, image, table, tostring

local net_if = nil
local essid = nil
local last_update = 0

module("shiny.net")
local icon = widget({ type = "imagebox", align = "right" })
local infobox = widget({type = "textbox", name = "netbox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })

local graph_down = awful.widget.graph()
awful.widget.layout.margins[graph_down.widget] = { top = 1, bottom = 1 }
graph_down:set_height(13)
graph_down:set_width(35)
graph_down:set_color(beautiful.fg_normal)
graph_down:set_background_color(beautiful.graph_bg)
graph_down:set_border_color(beautiful.bg_normal)
graph_down:set_scale("true")

local graph_up = awful.widget.graph()
awful.widget.layout.margins[graph_up.widget] = { top = 1, bottom = 1 }
graph_up:set_height(13)
graph_up:set_width(35)
graph_up:set_color(beautiful.fg_normal)
graph_up:set_background_color(beautiful.graph_bg)
graph_up:set_border_color(beautiful.bg_normal)
graph_up:set_scale("true")

local function bytes_to_string(bytes, sec)
    if not bytes or not tonumber(bytes) then
        return ''
    end

    bytes = tonumber(bytes)

    signs = {}
    signs[1] = '  b'
    signs[2] = 'KiB'
    signs[3] = 'MiB'
    signs[4] = 'GiB'
    signs[5] = 'TiB'

    sign = 1

    while bytes/1024 > 1 and signs[sign+1] ~= nil do
        bytes = bytes/1024
        sign = sign+1
    end

    bytes = bytes*10
    bytes = math.floor(bytes)/10

    if sec then
        return tostring(bytes)..signs[sign]..'ps'
    else
        return tostring(bytes)..signs[sign]
    end
end

local function get_up()
    local lfd, wfd, lan, wlan
    lfd = io.open("/sys/class/net/eth0/operstate")
    lan = lfd:read()
    lfd:close()
    if shiny.file_exists("/sys/class/net/wlan0/operstate") then
        wfd = io.open("/sys/class/net/wlan0/operstate")
        wlan = wfd:read()
        wfd:close()
    end
    if lan and lan == "up" then
        return "eth0"
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

local nets = {}
local function get_net_data()
    local f = io.open('/proc/net/dev')
    args = {}

    for line in f:lines() do
        line = shiny.splitbywhitespace(line)

        local p = line[1]:find(':')
        if p ~= nil then
            name = line[1]:sub(0,p-1)
            line[1] = line[1]:sub(p+1)

            if tonumber(line[1]) == nil then
                line[1] = line[2]
                line[9] = line[10]
            end

            args[name..'_rx'] = bytes_to_string(line[1])
            args[name..'_tx'] = bytes_to_string(line[9])

            args[name..'_rx_b'] = shiny.round_num(line[1], 1, 1)
            args[name..'_tx_b'] = shiny.round_num(line[9], 1, 1)

            args[name..'_rx_kb'] = shiny.round_num(line[1]/1024, 1, 1)
            args[name..'_tx_kb'] = shiny.round_num(line[9]/1024, 1, 1)

            args[name..'_rx_mb'] = shiny.round_num(line[1]/1024^2, 1, 1)
            args[name..'_tx_mb'] = shiny.round_num(line[9]/1024^2, 1, 1)

            args[name..'_rx_gb'] = shiny.round_num(line[1]/1024^3, 1, 1)
            args[name..'_tx_gb'] = shiny.round_num(line[9]/1024^3, 1, 1)

            if nets[name] == nil then
                nets[name] = {}
                args[name..'_down'] = 'n/a'
                args[name..'_up'] = 'n/a'

                args[name..'_down_b'] = 0
                args[name..'_up_b'] = 0

                args[name..'_down_kb'] = 0
                args[name..'_up_kb'] = 0

                args[name..'_down_mb'] = 0
                args[name..'_up_mb'] = 0

                args[name..'_down_gb'] = 0
                args[name..'_up_gb'] = 0

                nets[name].time = os.time()
            else
                interval = os.time()-nets[name].time
                nets[name].time = os.time()

                down = (line[1]-nets[name][1])/interval
                up = (line[9]-nets[name][2])/interval

                args[name..'_down'] = bytes_to_string(down, true)
                args[name..'_up'] = bytes_to_string(up, true)

                args[name..'_down_b'] = shiny.round_num(down, 1, 1)
                args[name..'_up_b'] = shiny.round_num(up, 1, 1)

                args[name..'_down_kb'] = shiny.round_num(down/1024, 1, 1)
                args[name..'_up_kb'] = shiny.round_num(up/1024, 1, 1)

                args[name..'_down_mb'] = shiny.round_num(down/1024^2, 1, 1)
                args[name..'_up_mb'] = shiny.round_num(up/1024^2, 1, 1)

                args[name..'_down_gb'] = shiny.round_num(down/1024^3, 1, 1)
                args[name..'_up_gb'] = shiny.round_num(up/1024^3, 1, 1)
            end

            nets[name][1] = line[1]
            nets[name][2] = line[9]
        end
    end

    f:close()
    return args
end

local padding = 0
local paddu = 0
function padd(text)
    local text = tostring(text)
    if text:len() >= padding then
        padding = text:len()
        paddu = 0
    else
        paddu = paddu + 1
        if paddu == 30 then
            paddu = 0
            padding = padding - 1
        end
    end
    while text:len() < padding do
        text = " " .. text
    end
    return text
end

local function update()
    local data = get_net_data()
    local nif = get_up()
    local text = ""
    if not nif then
        openbox.text = ""
        icon.image = nil
        net_if = nil
    elseif net_if ~= nif then
        net_if = nif
        if nif == "wlan0" then
            icon.image = image(beautiful.wireless)
            essid = get_essid(nif)
            text = shiny.bold(essid)
        elseif nif == "eth0" then
            icon.image = image(beautiful.network)
        end
    elseif nif == "wlan0" then
        last_update = last_update + 1
        if last_update == 3 then
            last_update = 0
            essid = get_essid(nif)
        end
        text = shiny.bold(essid)
    end
    if nif then
        openbox.text = shiny.fg(beautiful.hilight, "[ ")
        graph_down:add_value(data[nif .. "_down_kb"])
        graph_up:add_value(data[nif .. "_up_kb"])
        text = text .. " "
            .. padd(data[nif .. "_down_kb"])
            .. shiny.fg(beautiful.hilight, " / ")
            .. padd(data[nif .. "_up_kb"])
            .. shiny.fg(beautiful.hilight, " ] ")
        infobox.text = text
    end
end

shiny.register(update, 1)

setmetatable(_M, { __call = function () return {graph_up.widget, graph_down.widget, infobox, icon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
