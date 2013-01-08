-- apps like mplayer should always be ontop
-- mplayer looses the ontop flag when changing from fullscreen to windowed mode.

local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")

local pairs, screen, mouse, client
    = pairs, screen, mouse, client

-- keeps apps on top
topapps = {}


topapps = {
        ["Gkrellm"]  = true,
        ["MPlayer"]  = true,
        ["mplayer2"] = true,
    }

local function update(c)
    local lscreen = c and c.screen or mouse.screen
    for _, ttag in pairs(awful.tag.selectedlist(lscreen)) do
        for _, tclient in pairs(ttag:clients()) do
            if topapps[tclient.class] and not tclient.fullscreen then
                tclient.ontop = true
                tclient:raise()
            end
        end
    end
end

client.connect_signal("focus", function(c) update(c) end)
client.connect_signal("unfocus", function(c) update(c) end)
client.connect_signal("unmanage", function(c) update(c) end)

return topapps
