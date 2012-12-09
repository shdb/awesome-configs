local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")

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
local widget, button, mouse, image = widget, button, mouse, image

local icon = widget({ type = "imagebox" })
local infobox = widget({ type = "textbox", name = "batterybox" })
local openbox = widget({ type = "textbox" })

battery = { mt  = {} }

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
        local bstat = math.floor(cur * 100 / cap)
        if sta:match("Charging") then
            bstat = bstat .. "% A/C"
        elseif sta:match("Discharging") then
            if tonumber(bstat) <= 3 then
                naughty.notify({
                    title      = "Battery Warning",
                    text       = "Battery low!"..spacer..bstat.."%"..spacer.."left!",
                    timeout    = 5,
                    position   = "top_right",
                    fg         = beautiful.fg_focus,
                    bg         = beautiful.bg_focus,
                })
            end
            if tonumber(bstat) < 10 then
                bstat = shiny.fg("#ff0000", bstat .. "%")
            elseif tonumber(bstat) < 20 then
                bstat = shiny.fg("#ffff00", bstat .. "%")
            else
                bstat = bstat .. "%"
            end
        else
            bstat = "A/C"
        end
        openbox.text = shiny.fg(beautiful.hilight, " [ ")
        icon.image = image(beautiful.battery)
        infobox.text = bstat .. shiny.fg(beautiful.hilight, " ]")
    else
        openbox.text = ""
        icon.image = nil
        infobox.text = ""
    end
end

infobox:add_signal("mouse::enter", function() battery_info() end)
infobox:add_signal("mouse::leave", function() shiny.remove_notify(popup) end)
icon:add_signal("mouse::enter", function() battery_info() end)
icon:add_signal("mouse::leave", function() shiny.remove_notify(popup) end)
openbox:add_signal("mouse::enter", function() battery_info() end)
openbox:add_signal("mouse::leave", function() shiny.remove_notify(popup) end)

shiny.register(update, 5)

function battery.mt:__call()
    return {infobox, icon, openbox, layout = awful.widget.layout.horizontal.rightleft}
end

return setmetatable(battery, battery.mt)
