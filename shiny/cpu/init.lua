local naughty = require("naughty")
local awful = require("awful")
local beautiful = require("beautiful")
local wicked = require("wicked")
local shiny = require("shiny")

local setmetatable = setmetatable
local io = {
	open = io.open,
	popen = io.popen,
	close = io.close
}
local string = {
	find = string.find
}
local math = {
	floor = math.floor
}
local widget, button, mouse, image = widget, button, mouse, image


module("shiny.cpu")
local cpuicon = widget({ type = "imagebox", align = "right" })
cpuicon.image = image(beautiful.cpu)
--local tempicon = widget({ type = "imagebox", align = "right" })
--tempicon.image = image(beautiful.temp)
local infobox_cpu = widget({type = "textbox", name = "batterybox", align = "right" })
local infobox_temp = widget({type = "textbox", name = "batterybox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })

local graph = widget({
    type  = 'graph',
    name  = 'cpugraph',
    align = 'right'
})

graph.height = 0.85
graph.width = 35
graph.bg = beautiful.graph_bg
graph.border_color = beautiful.bg_normal
graph.grow = 'right'

graph:plot_properties_set('cpu', {
    fg = beautiful.fg_normal,
    vertical_gradient = false
})

local function round_num(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
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

local function remove_notify(notify)
    if notify then
        naughty.destroy(notify)
        notify = nil
    end
end

local function get_cpu()
	local fhz = io.open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
	local hz = fhz:read();
	fhz:close()
	return round_num(hz/10^6, 1) .. " GHz" .. shiny.fg(beautiful.hilight, " | ")
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

local function update()
	--infobox_temp.text = get_temp()
    infobox_cpu.text = get_cpu()
end

openbox.text = shiny.fg(beautiful.hilight, " [ ")
shiny.register(update, 5)
wicked.register(graph, wicked.widgets.cpu, '$1', 1, 'cpu')

setmetatable(_M, { __call = function () return {graph, infobox_temp, tempicon, infobox_cpu, cpuicon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
