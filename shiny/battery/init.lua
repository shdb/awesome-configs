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
local icon = widget({ type = "imagebox" })
local infobox = widget({ type = "textbox", name = "batterybox" })
local openbox = widget({ type = "textbox" })

local function battery_info()
    local function battery_remaining()
        local f = io.popen("acpi -b")
        local ret = nil
        for line in f:lines() do
            local _, _, rem = string.find(line, "(..:..:.. .*)")
            if rem then
                ret = rem
            end
        end
        f:close()
        return ret
    end
    shiny.remove_notify(popup)
    local text = battery_remaining()
    if text then
        popup = naughty.notify({
                title = "battery",
                text = text,
                timeout = 0,
                hover_timeout = 0.5,
               })
    end
end

local function update()
    local adapter = "BAT0"
    local fcur, fcap, fsta
    local spacer = " "
    if shiny.file_exists("/sys/class/power_supply/"..adapter.."/energy_now") then
        fcur = io.open("/sys/class/power_supply/"..adapter.."/energy_now")
        fcap = io.open("/sys/class/power_supply/"..adapter.."/energy_full")
        fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
    elseif shiny.file_exists("/sys/class/power_supply/"..adapter.."/charge_now") then
        fcur = io.open("/sys/class/power_supply/"..adapter.."/charge_now")
        fcap = io.open("/sys/class/power_supply/"..adapter.."/charge_full")
        fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
    end
    if fcur then
        local cur = fcur:read()
        local cap = fcap:read()
        local sta = fsta:read()
        fcur:close()
        fcap:close()
        fsta:close()
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
                battery = shiny.fg("#ff0000", battery .. "%")
            elseif tonumber(battery) < 20 then
                battery = shiny.fg("#ffff00", battery .. "%")
            else
                battery = battery .. "%"
            end
        else
            battery = "A/C"
        end
        openbox.text = shiny.fg(beautiful.hilight, " [ ")
        icon.image = image(beautiful.battery)
        infobox.text = battery .. shiny.fg(beautiful.hilight, " ]")
    else
        openbox.text = ""
        icon.image = nil
        infobox.text = ""
    end
end

infobox:add_signal("mouse::enter", function () battery_info() end)
infobox:add_signal("mouse::leave", function() shiny.remove_notify(popup) end)
icon:add_signal("mouse::enter", function () battery_info() end)
icon:add_signal("mouse::leave", function() shiny.remove_notify(popup) end)
openbox:add_signal("mouse::enter", function () battery_info() end)
openbox:add_signal("mouse::leave", function() shiny.remove_notify(popup) end)

shiny.register(update, 5)

setmetatable(_M, { __call = function () return {infobox, icon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
