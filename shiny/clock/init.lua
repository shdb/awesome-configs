local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local shiny = require("shiny")

local setmetatable = setmetatable
local tonumber = tonumber
local widget, os, math, string = widget, os, math, string
module("shiny.clock")

local infobox = widget({ type = "textbox" })

calendar = nil
cal_offset = 0
function remove_notify(notify)
    if notify then
        naughty.destroy(notify)
        notify = nil
        cal_offset = 0
    end
end

function add_calendar(inc_offset)
    local save_offset = cal_offset
    remove_notify(calendar)
    cal_offset = save_offset + inc_offset
    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + cal_offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = awful.util.pread("cal -m " .. datespec)
    if cal_offset == 0 then -- this month, hilight day and month
        cal = string.gsub(cal, "%s" .. tonumber(os.date("%d")) .. "%s", shiny.bold(shiny.fg(beautiful.hilight, "%1")))
        cal = string.gsub(cal, "^(%s*%w+%s+%d+)", shiny.bold(shiny.fg(beautiful.hilight, "%1")))
    end
    calendar = naughty.notify {
        text = string.format('<span font_desc="%s">%s</span>', "monospace", cal),
        timeout = 1,
        hover_timeout = 0.5,
    }
end

local function update()
    infobox.text = shiny.fg(beautiful.hilight, "[ ")
                .. os.date("%d/%m/%Y " .. shiny.bold("%H:%M:%S"))
                .. shiny.fg(beautiful.hilight, " ]")
end

infobox:add_signal("mouse::enter", function() add_calendar(0) end)
infobox:add_signal("mouse::leave", function() remove_notify(calendar) end)

infobox:buttons(awful.util.table.join(
    awful.button({ }, 1, function() add_calendar(-1) end),
    awful.button({ }, 3, function() add_calendar(1)  end)
))
shiny.register(update, 1)

setmetatable(_M, { __call = function () return {infobox, layout = awful.widget.layout.horizontal.rightleft} end })
