local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")
local string = {
    len = string.len,
    sub = string.sub
}
local math = {
    floor = math.floor,
    mod   = math.mod
}
local os = { date = os.date }
local setmetatable = setmetatable
local widget, image
    = widget, image

local height, width, show_sec = 12, 28, false

module("shiny.binclock")

local cwidget = widget({type = "imagebox"})
--dont forget that awesome resizes our image with clocks to fit wibox's height
local color_active = beautiful.hilight --active dot color
local color_bg = beautiful.bg_normal --background color
local color_inactive = beautiful.fg_normal --inactive dot color
local dotsize = math.floor(height / 6) --dot size
local step = math.floor(dotsize / 2) --whitespace between dots
cwidget.image = image.argb32(width, height, nil) --create image
if (show_sec) then timeout = 1 else timeout = 20 end --we don't need to update often

local DEC_BIN = function(IN) --thanx to Lostgallifreyan (http://lua-users.org/lists/lua-l/2004-09/msg00054.html)
     local B,K,OUT,I,D = 2, "01", "", 0
     while IN > 0 do
         I = I + 1
         IN, D = math.floor(IN / B), math.mod(IN, B) + 1
         OUT = string.sub(K,D,D) .. OUT
     end
     return OUT
end

local paintdot = function(val,shift,limit) --paint number as dots with shift from left side
    local binval = DEC_BIN(val)
    local len = string.len(binval)
    local heightadj = 0 --height adjustment, if you need to lift dots up
    if (len < limit) then
        for i = 1, limit - len do binval = "0" .. binval end
    end
    for i = 0, limit - 1 do
        if (string.sub(binval, limit - i, limit - i) == "1") then
            cwidget.image:draw_rectangle(shift,  height - dotsize - heightadj, dotsize, dotsize, true, color_active)
        else
            cwidget.image:draw_rectangle(shift,  height - dotsize - heightadj, dotsize, dotsize, true, color_inactive)
        end
        heightadj = heightadj + dotsize + step
    end
end

local drawclock = function () --get time and send digits to paintdot()
     cwidget.image:draw_rectangle(0, 0, width, height, true, color_bg) --fill background

     local time = os.date("*t")
     local hour = time.hour
     if (string.len(hour) == 1) then
         hour = "0" .. time.hour
     end
     
     local min = time.min
     if (string.len(min) == 1) then
         min = "0" .. time.min
     end

     local sec = time.sec
     if (string.len(sec) == 1) then
         sec = "0" .. time.sec
     end

     local col_count = 6
     if (not show_sec) then col_count = 4 end
     local step = math.floor((width - col_count * dotsize) / 8) --calc horizontal whitespace between cols
     paintdot(0 + string.sub(hour, 1, 1), step, 2)
     paintdot(0 + string.sub(hour, 2, 2), dotsize + 2 * step, 4)
     paintdot(0 + string.sub(min, 1, 1),dotsize * 2 + 4 * step, 3)
     paintdot(0 + string.sub(min, 2, 2),dotsize * 3 + 5 * step, 4)
     if (show_sec) then
         paintdot(0 + string.sub(sec, 1, 1), dotsize * 4 + 7 * step, 3)
         paintdot(0 + string.sub(sec, 2, 2), dotsize * 5 + 8 * step, 4)
     end
     cwidget.image = cwidget.image
end

shiny.register(drawclock, 1)

setmetatable(_M, { __call = function (_, lheight, lwidth, lshow_sec)
        height = lheight or 12
        width = lwidth or 28
        show_sec = lshow_sec or false
        return {cwidget, layout = awful.widget.layout.horizontal.rightleft}
    end }
)
