local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")

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
local button, mouse, image, table
    = button, mouse, image, table

-- display memory usage
memory = { mt = {} }


local icon = wibox.widget.imagebox()
icon:set_image(beautiful.mem)

local bar = awful.widget.progressbar()
bar:set_vertical("true")
bar:set_height(13)
bar:set_width(5)
local gradient = "linear:0,0:20,20:0," .. beautiful.graph_end .. ":0.5," 
.. beautiful.graph_center .. ":1," .. beautiful.fg_normal
bar:set_color(gradient)
bar:set_color(beautiful.fg_normal)
bar:set_background_color(beautiful.graph_bg)
bar:set_border_color(beautiful.bg_normal)
bar:set_ticks("true")
bar:set_ticks_gap(1)
bar:set_ticks_size(2)
bar:set_max_value(100)

local function get_mem()
    -- Return MEM usage values
    local f = io.open('/proc/meminfo')

    ---- Get data
    for line in f:lines() do
        line = shiny.splitbywhitespace(line)

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
    bar:set_value(get_mem()[1])
end

shiny.register(update, 2)

function memory.mt:__call()
	local layout = wibox.layout.fixed.horizontal()
	layout:add(bar)
	layout:add(icon)
    return layout
end

return setmetatable(memory, memory.mt)
