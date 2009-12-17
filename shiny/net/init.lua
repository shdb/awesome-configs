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
    if bytes == nil or tonumber(bytes) == nil then
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

            args['{'..name..' rx}'] = bytes_to_string(line[1])
            args['{'..name..' tx}'] = bytes_to_string(line[9])

            args['{'..name..' rx_b}'] = math.floor(line[1]*10)/10
            args['{'..name..' tx_b}'] = math.floor(line[9]*10)/10

            args['{'..name..' rx_kb}'] = math.floor(line[1]/1024*10)/10
            args['{'..name..' tx_kb}'] = math.floor(line[9]/1024*10)/10

            args['{'..name..' rx_mb}'] = math.floor(line[1]/1024/1024*10)/10
            args['{'..name..' tx_mb}'] = math.floor(line[9]/1024/1024*10)/10

            args['{'..name..' rx_gb}'] = math.floor(line[1]/1024/1024/1024*10)/10
            args['{'..name..' tx_gb}'] = math.floor(line[9]/1024/1024/1024*10)/10

            if nets[name] == nil then
                nets[name] = {}
                args['{'..name..' down}'] = 'n/a'
                args['{'..name..' up}'] = 'n/a'

                args['{'..name..' down_b}'] = 0
                args['{'..name..' up_b}'] = 0

                args['{'..name..' down_kb}'] = 0
                args['{'..name..' up_kb}'] = 0

                args['{'..name..' down_mb}'] = 0
                args['{'..name..' up_mb}'] = 0

                args['{'..name..' down_gb}'] = 0
                args['{'..name..' up_gb}'] = 0

                nets[name].time = os.time()
            else
                interval = os.time()-nets[name].time
                nets[name].time = os.time()

                down = (line[1]-nets[name][1])/interval
                up = (line[9]-nets[name][2])/interval

                args['{'..name..' down}'] = bytes_to_string(down, true)
                args['{'..name..' up}'] = bytes_to_string(up, true)

                args['{'..name..' down_b}'] = math.floor(down*10)/10
                args['{'..name..' up_b}'] = math.floor(up*10)/10

                args['{'..name..' down_kb}'] = math.floor(down/1024*10)/10
                args['{'..name..' up_kb}'] = math.floor(up/1024*10)/10

                args['{'..name..' down_mb}'] = math.floor(down/1024/1024*10)/10
                args['{'..name..' up_mb}'] = math.floor(up/1024/1024*10)/10

                args['{'..name..' down_gb}'] = math.floor(down/1024/1024/1024*10)/10
                args['{'..name..' up_gb}'] = math.floor(up/1024/1024/1024*10)/10
            end

            nets[name][1] = line[1]
            nets[name][2] = line[9]
        end
    end

    f:close()
    return args

end

local function update()
    local data = get_net_data()
    local nif = get_up()
    if not nif then
        openbox.text = ""
        icon.image = nil
        net_if = nil
        infobox.text = ""
    elseif net_if ~= nif then
        net_if = nif
        if nif == "wlan0" then
            icon.image = image(beautiful.wireless)
            openbox.text = shiny.fg(beautiful.hilight, "[ ")
            essid = get_essid(nif)
            infobox.text = shiny.bold(essid) .. shiny.fg(beautiful.hilight, " ] ")
        elseif nif == "eth0" then
            icon.image = image(beautiful.network)
            openbox.text = ""
            infobox.text = ""
        end
    elseif nif == "wlan0" then
        last_update = last_update + 1
        if last_update == 3 then
            last_update = 0
            essid = get_essid(nif)
        end
        infobox.text = shiny.bold(essid) .. shiny.fg(beautiful.hilight, " ] ")
    end
    if nif then
        graph_down:add_value(data["{" .. nif .. " down_kb}"])
        graph_up:add_value(data["{" .. nif .. " up_kb}"])
    end
end

shiny.register(update, 1)

setmetatable(_M, { __call = function () return {graph_up.widget, graph_down.widget, infobox, icon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
