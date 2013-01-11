local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")
local string = {
    len    = string.len,
    sub    = string.sub,
	format = string.format
}
local math = {
    floor = math.floor,
    mod   = math.mod,
	min   = math.min,
	fmod  = math.fmod,
	pi    = math.pi
}
local os = { date = os.date }
local setmetatable = setmetatable

local binclock = { mt = {} }
local height, width = 12, 28

local bcwidget = wibox.widget.base.make_widget()
bcwidget.width = 2
bcwidget.shift = 1
bcwidget.farShift = 2
bcwidget.border = 1
bcwidget.lineWidth = 1
bcwidget.colorActive = beautiful.bg_focus 

local function hex2rgba(color, alpha)
	local color = color or "#111111"
	local alpha = alpha or 1
	if string.len(color) == 7 then
		color = string.sub(color,2,7)
	elseif string.len(color) ~= 6 then
		return -1, -1, -1
	end

	red = string.sub(color,1,2)
	green = string.sub(color,3,4)
	blue = string.sub(color,5,6)
	red = tonumber(red, 16)/255;
	green = tonumber(green, 16)/255;
	blue = tonumber(blue, 16)/255;
	return red, green, blue, alpha
end

bcwidget.fit = function(bcwidget, width, height)
	local size = math.min(width, height)
	return 6 * bcwidget.width + 5 * bcwidget.shift + 2 * bcwidget.farShift + 2 * bcwidget.border + 2 * bcwidget.border, size
end

bcwidget.draw = function(bcwidget, wibox, cr, width, height)
	local curTime = os.date("*t")

	local column = {}
	table.insert(column, string.format("%04d", bcwidget:dec_bin(string.sub(string.format("%02d", curTime.hour), 1, 1))))
	table.insert(column, string.format("%04d", bcwidget:dec_bin(string.sub(string.format("%02d", curTime.hour), 2, 2))))
	table.insert(column, string.format("%04d", bcwidget:dec_bin(string.sub(string.format("%02d", curTime.min), 1, 1))))
	table.insert(column, string.format("%04d", bcwidget:dec_bin(string.sub(string.format("%02d", curTime.min), 2, 2))))
	table.insert(column, string.format("%04d", bcwidget:dec_bin(string.sub(string.format("%02d", curTime.sec), 1, 1))))
	table.insert(column, string.format("%04d", bcwidget:dec_bin(string.sub(string.format("%02d", curTime.sec), 2, 2))))

	local bigColumn = 0
	for i = 0, 5 do
		if math.floor(i / 2) > bigColumn then
			bigColumn = bigColumn + 1
		end
		for j = 0, 3 do
			if ((i == 0 and (j == 0 or j == 1)) or ((i == 2 or i == 4) and (j == 0))) then
				active = "bg"
			elseif string.sub(column[i + 1], j + 1, j + 1) == "0" then
				active = true 
			else
				active = false
			end 
			bcwidget:draw_point(cr, bigColumn, i, j, active)
		end
	end
end

bcwidget.dec_bin = function(bcwidget, inNum)
	inNum = tonumber(inNum)
	local base, enum, outNum, rem = 2, "01", "", 0
	while inNum > (base - 1) do
		inNum, rem = math.floor(inNum / base), math.fmod(inNum, base)
		outNum = string.sub(enum, rem + 1, rem + 1) .. outNum
	end
	outNum = inNum .. outNum
	return outNum
end

bcwidget.draw_point = function(bcwidget, cr, bigColumn, column, row, active)
	cr:rectangle(bcwidget.border + column * (bcwidget.width + bcwidget.shift) + bigColumn * bcwidget.farShift + bcwidget.width,
		 bcwidget.border + row * (bcwidget.width + bcwidget.shift) + bcwidget.width, bcwidget.width, bcwidget.width)
	if active == "bg" then
		cr:set_source_rgba(hex2rgba(beautiful.bg_normal))
	elseif active then
		cr:set_source_rgba(hex2rgba(beautiful.hilight))
	else
		cr:set_source_rgba(hex2rgba(beautiful.fg_normal))
	end
	cr:fill()
end

bcwidgettimer = timer { timeout = 1 }
bcwidgettimer:connect_signal("timeout", function() bcwidget:emit_signal("widget::updated") end)
bcwidgettimer:start()

function binclock.mt:__call(lheight, lwidth, lshow_sec)
    height = lheight or 14
    width = lwidth or 28
    show_sec = lshow_sec or false

	return { bcwidget }
end

return setmetatable(bcwidget, binclock.mt)
