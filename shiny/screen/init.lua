local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")

local setmetatable = setmetatable
local tonumber = tonumber
local client, screen, string, mouse = client, screen, string, mouse

-- display active scren
local screen_mod = { mt = {} }


local infobox = {}
for s = 1, screen.count() do
    infobox[s] = wibox.widget.textbox()
end

function screen_mod.update()
    if screen.count() == 1 then return end
    for s = 1, screen.count() do
        local ltext = ""
    
        for ls = 1, screen.count() do
            if mouse.screen == s and mouse.screen == ls then
                ltext = ltext .. shiny.fg(beautiful.fg_urgent, s) .. " "
            elseif mouse.screen == ls then
                ltext = ltext .. shiny.fg(beautiful.hilight, ls) .. " "
            else
                ltext = ltext .. ls .. " "
            end
        end

        infobox[s]:set_markup(
				shiny.fg(beautiful.hilight, "[ ")
				.. ltext
				.. shiny.fg(beautiful.hilight, "]")
			)
    end
end

if screen.count() > 1 then
    shiny.register(update, 1)
    client.connect_signal("focus", function(c)
        update(c)
    end)
    client.connect_signal("unfocus", function(c)
        update(c)
    end)
end

function screen_mod.mt:__call(lsc)
    return {infobox[lsc]}
end

return setmetatable(screen_mod, screen_mod.mt)
