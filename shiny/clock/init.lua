local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local shiny = require("shiny")
local wibox      = require("wibox")

local setmetatable = setmetatable
local tonumber = tonumber
local os, math, string = os, math, string
local capi = { mouse = mouse }

-- display the current time and date
clock = { mt = {} }

local infobox = wibox.widget.textbox()

calendar = nil
cal_offset = 0

function clock.add_calendar(inc_offset)
    shiny.remove_notify(calendar)
    cal_offset = cal_offset + inc_offset
    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + cal_offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = awful.util.pread("cal -mw " .. datespec)
    if cal_offset == 0 then -- this month, hilight day and month
        cal = string.gsub(cal, "%s" .. tonumber(os.date("%d")) .. "%s", shiny.bold(shiny.fg(beautiful.hilight, "%1")))
        cal = string.gsub(cal, "^(%s*%w+%s+%d+)", shiny.bold(shiny.fg(beautiful.hilight, "%1")))
    end
    calendar = naughty.notify {
        text = string.format('<span font_desc="%s">%s</span>', "monospace", cal),
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen,
    }
end

local function update()
    infobox:set_markup(
		shiny.fg(beautiful.hilight, "[ ")
		.. os.date("%d/%m/%Y " .. shiny.bold("%H:%M:%S"))
		.. shiny.fg(beautiful.hilight, " ]")
	)
end

infobox:connect_signal("mouse::enter", function() clock.add_calendar(0) end)
infobox:connect_signal("mouse::leave", function() shiny.remove_notify(calendar); cal_offset = 0 end)

infobox:buttons(awful.util.table.join(
    awful.button({ }, 1, function() clock.add_calendar(-1) end),
    awful.button({ }, 3, function() clock.add_calendar(1)  end)
))
shiny.register(update, 1)

function clock.mt:__call()
	return { infobox }
end

return setmetatable(clock, clock.mt)
