local lfs       = require("lfs")
local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")

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
local widget, button, mouse, table, tostring, pairs
    = widget, button, mouse, table, tostring, pairs

local net_if = nil
local essid = nil
local last_update = 0
local iflist = {}

-- display network statistics
local net = { mt = {} }


local icon    = wibox.widget.imagebox()
local infobox = wibox.widget.textbox()
local openbox = wibox.widget.textbox()

local function create_graph()
    local graph = awful.widget.graph()
    --awful.widget.layout.margins[graph.widget] = { top = 1, bottom = 1 }
    graph:set_height(13)
    graph:set_width(35)
    graph:set_color(beautiful.fg_normal)
    graph:set_background_color(beautiful.graph_bg)
    graph:set_border_color(beautiful.bg_normal)
    graph:set_scale("true")
    return graph
end

local graph_down = create_graph()
local graph_up = create_graph()

local function bytes_to_string(bytes, sec)
    if not bytes or not tonumber(bytes) then
        return ''
    end

    bytes = tonumber(bytes)

    local signs = {}
    signs[1] = '  b'
    signs[2] = 'KiB'
    signs[3] = 'MiB'
    signs[4] = 'GiB'
    signs[5] = 'TiB'

    local sign = 1

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
    -- returns the first device found to be up.
    -- lan is preferred over wlan
    for iface in lfs.dir("/sys/class/net") do
        if iface ~= "lo" and iface ~= "." and iface ~= ".." then
            local fd = io.open("/sys/class/net/" .. iface .. "/operstate")
            if fd then
                local stat = fd:read()
                if stat ~= "down" and stat ~= "unknown" then
                   fd:close()
                   return iface
                end
            fd:close()
            end
        end
    end
    return nil
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
    local args = {}

    for line in f:lines() do
        line = shiny.splitbywhitespace(line)

        local p = line[1]:find(':')
        if p ~= nil then
            local name = line[1]:sub(0,p-1)
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
                local interval = os.time()-nets[name].time
                interval = interval > 0 and interval or 1
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
local function padd(text)
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

local function update_icon(nif)
    if not iflist[nif] then return false end
    if iflist[nif] == "wlan" then
        icon:set_image(beautiful.wireless)
        essid = get_essid(nif)
        text = shiny.bold(essid)
    elseif iflist[nif] == "lan" then
        icon:set_image(beautiful.network)
    end
end

local function update()
    local nif = get_up()
    local text = ""
    if not nif then
        openbox:set_text("")
        icon:set_image(nil)
        net_if = nil
    elseif net_if ~= nif then
        if update_icon(nif) then
            net_if = nif
        end
    end
    if nif then 
        if iflist[nif] == "wlan" then
            last_update = last_update + 1
            if last_update >= 9 then
                last_update = 0
                essid = get_essid(nif)
            end
            text = shiny.bold(essid)
        end
        local data = get_net_data()
        openbox:set_markup(shiny.fg(beautiful.hilight, "[ "))
        graph_down:add_value(data[nif .. "_down_kb"])
        graph_up:add_value(data[nif .. "_up_kb"])
        text = text .. " "
            .. padd(data[nif .. "_down_kb"])
            .. shiny.fg(beautiful.hilight, " / ")
            .. padd(data[nif .. "_up_kb"])
            .. shiny.fg(beautiful.hilight, " ] ")
    else
        graph_down:add_value(0)
        graph_up:add_value(0)
    end
    infobox:set_markup(text)
end

shiny.register(update, 1)

function net.mt:__call(ifl)
    iflist = ifl
	return { openbox, icon, infobox, graph_down, graph_up }

end

return setmetatable(net, net.mt)
