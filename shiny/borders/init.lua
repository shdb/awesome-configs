local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")

local setmetatable = setmetatable
local tonumber = tonumber
local pairs, screen, mouse, client
    = pairs, screen, mouse, client

-- manages border colors
borders = {}

function borders.update(c)
    local lscreen = c and c.screen or mouse.screen
    local visibleclients = awful.client.visible(lscreen)
    local tiledclients = awful.client.tiled(lscreen)
    local layout = awful.layout.getname(awful.layout.get(lscreen))

    if (#visibleclients == 0) then return end

    for _, current in pairs(visibleclients) do
        if (awful.client.floating.get(current)
            and not current.maximized_horizontal
            and not current.fullscreen)
            or layout == "floating" then

            current.border_width = beautiful.border_width

        elseif #visibleclients == 1
            or layout == "max"
            or current.maximized_horizontal
            or current.fullscreen
            or #tiledclients == 1 then

            current.border_width = 0

        else
            current.border_width = beautiful.border_width
        end
    end
end

client.connect_signal("focus", function(c)
        borders.update(c)
        c.border_color = beautiful.border_focus
    end)
client.connect_signal("unfocus", function(c)
        borders.update(c)
        c.border_color = beautiful.border_normal
    end)
client.connect_signal("unmanage", function(c) borders.update(c) end)

client.connect_signal("manage", function(c, startup)
    c:connect_signal("property::geometry", function(c)
        borders.update(c)
    end)
    borders.update(c)
end)

return borders
