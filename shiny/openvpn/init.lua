local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")

local setmetatable = setmetatable
local tonumber     = tonumber
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
local button, mouse, image = button, mouse, image

local icon = wibox.widget.imagebox()
local infobox = wibox.widget.textbox()
local openbox = wibox.widget.textbox()

openvpn = { mt  = {} }

local function tun_address()
	local f = io.popen("ifconfig | grep -A1 tun")
	local ret = nil
	for line in f:lines() do
		local _, _, tun = string.find(line, "inet (%d+%.%d+%.%d+%.%d+)")
		if tun then
			ret = tun
		end
	end
	f:close()
	return ret
end

local function openvpn_info()
    shiny.remove_notify(popup)
    local text = tun_address()
    if text then
        popup = naughty.notify({
                title = "openvpn",
                text = text,
                timeout = 0,
                hover_timeout = 0.5,
               })
    end
end

local function update()
	local oupdown
    local spacer = " "
	if tun_address() then
		oupdown = "up"
	else
		oupdown = "down"
	end

	openbox:set_markup(shiny.fg(beautiful.hilight, " [ "))
	icon:set_image(beautiful.openvpn)
	infobox:set_markup(oupdown .. shiny.fg(beautiful.hilight, " ]"))
end

infobox:connect_signal("mouse::enter", function() openvpn_info() end)
infobox:connect_signal("mouse::leave", function() shiny.remove_notify(popup) end)
icon:connect_signal("mouse::enter", function() openvpn_info() end)
icon:connect_signal("mouse::leave", function() shiny.remove_notify(popup) end)
openbox:connect_signal("mouse::enter", function() openvpn_info() end)
openbox:connect_signal("mouse::leave", function() shiny.remove_notify(popup) end)

shiny.register(update, 5)

function openvpn.mt:__call()
	return { openbox, icon, infobox }
end

return setmetatable(openvpn, openvpn.mt)
