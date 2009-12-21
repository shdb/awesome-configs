local naughty = require("naughty")
local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")

local setmetatable = setmetatable
local io = {
    open = io.open,
    popen = io.popen,
    close = io.close
}
local string = {
    find   = string.find,
    gmatch = string.gmatch
}
local math = {
    floor = math.floor
}
local widget, button, mouse, image, ipairs, table
    = widget, button, mouse, image, ipairs, table


module("shiny.cpu")
local cpuicon = widget({ type = "imagebox", align = "right" })
cpuicon.image = image(beautiful.cpu)
--local tempicon = widget({ type = "imagebox", align = "right" })
--tempicon.image = image(beautiful.temp)
local infobox_cpu = widget({type = "textbox", name = "batterybox", align = "right" })
local infobox_temp = widget({type = "textbox", name = "batterybox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })
local graph = awful.widget.graph()

awful.widget.layout.margins[graph.widget] = { top = 1, bottom = 1 }
graph:set_height(13)
graph:set_width(35)
graph:set_color(beautiful.fg_normal)
graph:set_background_color(beautiful.graph_bg)
graph:set_border_color(beautiful.bg_normal)
graph:set_max_value(100)

local function get_cpu_freq()
    local fhz = io.open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
    local hz = fhz:read();
    fhz:close()
    return shiny.round_num(hz/10^6, 1) .. " GHz" .. shiny.fg(beautiful.hilight, " | ")
end

local function get_temp()
    local f = io.popen("acpi -t")
    local ret = ""
    for line in f:lines() do
        local _, _, temp = string.find(line, "(..)\.. degrees")
        if temp then
            ret = ret .. temp .. "C, "
        end
    end
    f:close()
    ret = ret:sub(0, ret:len() - 2)
    return ret .. shiny.fg(beautiful.hilight, " ] ")
end

-- Initialise function tables
local cpu_usage  = {}
local cpu_total  = {}
local cpu_active = {}

local function get_cpu_usage()
    -- Get /proc/stat
    local f = io.open("/proc/stat")
    local cpu_lines = {}

    for line in f:lines() do
        if string.find(line, "^cpu") then
            cpu_lines[#cpu_lines+1] = {}

            for i in string.gmatch(line, "[%s]+([%d]+)") do
                  table.insert(cpu_lines[#cpu_lines], i)
            end
        end
    end
    f:close()

    -- Ensure tables are initialized correctly
    while #cpu_total < #cpu_lines do
        table.insert(cpu_total, 0)
    end
    while #cpu_active < #cpu_lines do
        table.insert(cpu_active, 0)
    end
    while #cpu_usage < #cpu_lines do
        table.insert(cpu_usage, 0)
    end

    local total_new   = {}
    local active_new  = {}
    local diff_total  = {}
    local diff_active = {}

    for i, v in ipairs(cpu_lines) do
        -- Calculate totals
        total_new[i]  = 0
        for j = 1, #v do
            total_new[i] = total_new[i] + v[j]
        end
        active_new[i] = v[1] + v[2] + v[3]

        -- Calculate percentage
        diff_total[i]  = total_new[i]  - cpu_total[i]
        diff_active[i] = active_new[i] - cpu_active[i]
        cpu_usage[i]   = math.floor(diff_active[i] / diff_total[i] * 100)

        -- Store totals
        cpu_total[i]   = total_new[i]
        cpu_active[i]  = active_new[i]
    end

    return cpu_usage
end

local function update()
	--infobox_temp.text = get_temp()
    infobox_cpu.text = get_cpu_freq()
    graph:add_value(get_cpu_usage()[1])
end

openbox.text = shiny.fg(beautiful.hilight, " [ ")
shiny.register(update, 1)

setmetatable(_M, { __call = function () return {graph.widget, infobox_temp, infobox_cpu, cpuicon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
