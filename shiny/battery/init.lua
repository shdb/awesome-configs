local naughty = require("naughty")
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
local math = {
	floor = math.floor
}
local string = {
	find = string.find
}
local widget, button, mouse, image = widget, button, mouse, image


module("shiny.battery")
local icon = widget({ type = "imagebox", align = "right" })
local infobox = widget({type = "textbox", name = "batterybox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })
local closebox = widget({ type = "textbox", align = "right" })

local function fg(color, text)
	if not color then
		color = "#555555"
	end
    return '<span color="' .. color .. '">' .. text .. '</span>'
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

local function battery_info()
	local function battery_remaining() 
        local f = io.popen("acpi -b") 
        local ret = nil 
        for line in f:lines() do 
            local _, _, rem = string.find(line, "(..:..:..) remaining") 
            if rem then 
                ret = rem 
            end 
        end 
        f:close() 
        return ret 
    end 
    remove_notify(popup) 
    local timerem = battery_remaining() 
    if timerem then 
        popup = naughty.notify({ 
                title = "battery", 
                text = timerem .. " remaining", 
                timeout = 0, 
                hover_timeout = 0.5, 
               }) 
    end
end

local function update()
	local adapter = "BAT0"
	if file_exists("/sys/class/power_supply/"..adapter) then
		spacer = " "
		local fcur = io.open("/sys/class/power_supply/"..adapter.."/energy_now")
		local fcap = io.open("/sys/class/power_supply/"..adapter.."/energy_full")
		local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
		local cur = fcur:read()
		local cap = fcap:read()
		local sta = fsta:read()
		local battery = math.floor(cur * 100 / cap)
		if sta:match("Charging") then
			battery = battery .. "% A/C"
		elseif sta:match("Discharging") then
			if tonumber(battery) <= 3 then
				naughty.notify({
					title      = "Battery Warning",
					text       = "Battery low!"..spacer..battery.."%"..spacer.."left!",
					timeout    = 5,
					position   = "top_right",
					fg         = beautiful.fg_focus,
					bg         = beautiful.bg_focus,
				})
			end
			if tonumber(battery) < 10 then
				battery = fg("#ff0000", battery .. "%")
			elseif tonumber(battery) < 20 then
				battery = fg("#ffff00", battery .. "%")
			else
				battery = battery .. "%"
			end
		else
			battery = "A/C"
		end
		fcur:close()
		fcap:close()
		fsta:close()
		openbox.text = fg(beautiful.hilight, " [ ")
		closebox.text = fg(beautiful.hilight, " ]")
		icon.image = image(beautiful.battery)
		infobox.text = battery
	else
		openbox.text = ""
		closebox.text = ""
		icon.image = nil
		infobox.text = ""
	end
end

infobox.mouse_enter = battery_info
infobox.mouse_leave = function() remove_notify(popup) end
icon.mouse_enter = battery_info
icon.mouse_leave = function() remove_notify(popup) end
closebox.mouse_enter = battery_info
closebox.mouse_leave = function() remove_notify(popup) end
openbox.mouse_enter = battery_info
openbox.mouse_leave = function() remove_notify(popup) end

shiny.register(update, 5)

setmetatable(_M, { __call = function () return {closebox, infobox, icon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
