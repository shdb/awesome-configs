local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")

local setmetatable = setmetatable
local widget, os = widget, os
module("shiny.clock")

local infobox = widget({ type = "textbox" })

local function update()
    infobox.text = shiny.fg(beautiful.hilight, "[ ")
                .. os.date("%d/%m/%Y " .. shiny.bold("%H:%M:%S"))
                .. shiny.fg(beautiful.hilight, " ]")
end

shiny.register(update, 1)

setmetatable(_M, { __call = function () return {infobox, layout = awful.widget.layout.horizontal.rightleft} end })
