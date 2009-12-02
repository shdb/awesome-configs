local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")

local setmetatable = setmetatable
local tonumber = tonumber
local widget, pairs, screen, mouse, client
    = widget, pairs, screen, mouse, client
module("shiny.borders")

local function update(c)
    local lscreen = c and c.screen or mouse.screen
    local tiledclients = awful.client.tiled(lscreen)
    if (#tiledclients == 0) then return end
    for _, current in pairs(tiledclients) do
        if awful.client.floating.get(current) or layout == "floating" then
            current.border_width = beautiful.border_width
        elseif (#tiledclients == 1) or layout == "max" then
            current.border_width = 0
        else
            current.border_width = beautiful.border_width
        end
    end
end

client.add_signal("focus", function(c)
        update(c)
        c.border_color = beautiful.border_focus
    end)
client.add_signal("unfocus", function(c)
        update(c)
        c.border_color = beautiful.border_normal
    end)
client.add_signal("unmanage", function(c) update(c) end)