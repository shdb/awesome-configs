local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
    open = io.open,
    close = io.close
}
local string = {
	find = string.find,
	sub  = string.sub
}
local math = { floor = math.floor }
local widget, button, mouse, image, table
    = widget, button, mouse, image, table

module("shiny.memory")
local icon = widget({ type = "imagebox", align = "right" })
icon.image = image(beautiful.mem)

local bar =  widget({ type = "progressbar" })
bar.width = 4
bar.height = 1.0
bar.border_padding = 0
bar.border_width = 0
bar.ticks_count = 5
bar.vertical = true

bar:bar_properties_set("mem",
{
    bg           = beautiful.bg_normal,
    fg           = beautiful.fg_normal,
    fg_center    = beautiful.graph_center,
    fg_end       = beautiful.graph_end,
    fg_off       = beautiful.graph_bg,
    border_color = beautiful.bg_normal,
    reverse      = false
})

function splitbywhitespace(str)
    values = {}
    start = 1
    splitstart, splitend = string.find(str, ' ', start)

    while splitstart do
        m = string.sub(str, start, splitstart-1)
        if m:gsub(' ','') ~= '' then
            table.insert(values, m)
        end

        start = splitend+1
        splitstart, splitend = string.find(str, ' ', start)
    end

    m = string.sub(str, start)
    if m:gsub(' ','') ~= '' then
        table.insert(values, m)
    end

    return values
end

local function get_mem()
    -- Return MEM usage values
    local f = io.open('/proc/meminfo')

    ---- Get data
    for line in f:lines() do
        line = splitbywhitespace(line)

        if line[1] == 'MemTotal:' then
            mem_total = math.floor(line[2]/1024)
        elseif line[1] == 'MemFree:' then
            free = math.floor(line[2]/1024)
        elseif line[1] == 'Buffers:' then
            buffers = math.floor(line[2]/1024)
        elseif line[1] == 'Cached:' then
            cached = math.floor(line[2]/1024)
        end
    end
    f:close()

    ---- Calculate percentage
    mem_free=free+buffers+cached
    mem_inuse=mem_total-mem_free
    mem_usepercent = math.floor(mem_inuse/mem_total*100)

    return {mem_usepercent, mem_inuse, mem_total, mem_free}
end

local function update()
	bar:bar_data_add("mem", get_mem()[1])
end

shiny.register(update, 2)

setmetatable(_M, { __call = function () return {bar, icon, layout = awful.widget.layout.horizontal.rightleft} end })
