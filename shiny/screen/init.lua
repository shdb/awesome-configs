local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")

local setmetatable = setmetatable
local tonumber = tonumber
local widget, client, screen, string = widget, client, screen, string
local capi = { mouse = mouse, screen = screen }

module("shiny.screen")

local infobox = {}
for s = 1, screen.count() do
    infobox[s] = widget({ type = "textbox" })
end

function update()
    if screen.count() == 1 then return end
    for s = 1, screen.count() do
        local ltext = ""
    
    for ls = 1, screen.count() do
            if capi.mouse.screen == s and capi.mouse.screen == ls then
                ltext = ltext .. shiny.fg(beautiful.fg_urgent, s) .. " "
            elseif capi.mouse.screen == ls then
                ltext = ltext .. shiny.fg(beautiful.hilight, ls) .. " "
        else
                ltext = ltext .. ls .. " "
            end
    end
        infobox[s].text = shiny.fg(beautiful.hilight, "[ ")
        .. ltext
                .. shiny.fg(beautiful.hilight, "]")
    end
end

if screen.count() > 1 then
    shiny.register(update, 1)
    client.add_signal("focus", function(c)
        update(c)
    end)
    client.add_signal("unfocus", function(c)
        update(c)
    end)
end

setmetatable(_M, { __call = function (_, lsc)
    return {infobox[lsc]} end })
