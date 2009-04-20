local naughty = require("naughty")
local awful = require("awful")
local beautiful = require("beautiful")
local wicked = require("wicked")

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
batteryicon = widget({ type = "imagebox", align = "right" })
batterybox = widget({type = "textbox", name = "batterybox", align = "right" })
openboxbat = widget({ type = "textbox", align = "right" })
closeboxbat = widget({ type = "textbox", align = "right" })

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

function remove_notify(notify)
    if notify then
        naughty.destroy(notify)
        notify = nil
    end
end

local function battery_info()
	local function battery_remaining() 
        local f = io.popen("acpi -t") 
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
    remove_notify(batteryboxpopup) 
    local timerem = battery_remaining() 
    if timerem then 
        batteryboxpopup = naughty.notify({ 
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
		openboxbat.text = fg(beautiful.hilight, " [ ")
		closeboxbat.text = fg(beautiful.hilight, " ]")
		if beautiful.battery then
			batteryicon.image = image(beautiful.battery)
		end
		return battery
	else
		openboxbat.text = ""
		closeboxbat.text = ""
		batteryicon.image = nil
		return ""
	end
end

batterybox.mouse_enter = battery_info
batterybox.mouse_leave = function() remove_notify(batteryboxpopup) end
batteryicon.mouse_enter = battery_info
batteryicon.mouse_leave = function() remove_notify(batteryboxpopup) end
closeboxbat.mouse_enter = battery_info
closeboxbat.mouse_leave = function() remove_notify(batteryboxpopup) end
openboxbat.mouse_enter = battery_info
openboxbat.mouse_leave = function() remove_notify(batteryboxpopup) end

wicked.register(batterybox, update, "$1", 5)

setmetatable(_M, { __call = function () return {openboxbat, batteryicon, batterybox, closeboxbat} end })
