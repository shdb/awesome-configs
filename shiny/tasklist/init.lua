local awful = require("awful")
local shiny = require("shiny")

local setmetatable, tonumber, pairs
    = setmetatable, tonumber, pairs
local widget, os, math, string, screen, mouse, client
    = widget, os, math, string, screen, mouse, client
module("shiny.tasklist")

local mytasklist = {}
for s = 1, screen.count() do
    mytasklist[s] = widget({ type = "textbox" })
end

function update(c)
    local ccount, selc, mcount = 0, 0, 0
    local lscreen = c and c.screen or mouse.screen
    for _, ttag in pairs(awful.tag.selectedlist(lscreen)) do
        for _, tclient in pairs(ttag:clients()) do
            ccount = ccount + 1
            if tclient == client.focus then
                selc = ccount
            end
            if tclient.minimized then
                mcount = mcount + 1
                ccount = ccount - 1
            end
        end
    end
    if mcount > 0 then
        mytasklist[lscreen].text = shiny.widget_base(
            shiny.widget_section("", shiny.widget_value(selc, ccount),
            shiny.widget_section("", mcount)))
    else
        mytasklist[lscreen].text = shiny.widget_base(shiny.widget_section("", shiny.widget_value(selc, ccount)))
    end
end

client.add_signal("focus", function(c) update(c) end)
client.add_signal("unfocus", function(c) update(c) end)
client.add_signal("unmanage", function(c) update(c) end)
for s = 1, screen.count() do
    awful.tag.attached_add_signal(s, "property::selected", function() update() end)
end

setmetatable(_M, { __call = function(_, scr) return {mytasklist[scr]} end })
