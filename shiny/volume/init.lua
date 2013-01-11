local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
    open = io.open,
    popen = io.popen,
    close = io.close
}
local string = {
    find   = string.find,
    format = string.format,
    match  = string.match
}
local button, mouse
    = button, mouse

-- set and display volume
volume = { mt = {} }


local icon = wibox.widget.imagebox()
icon:set_image(beautiful.volume)

local bar
--local bar =  widget({ type = "progressbar" })
--bar.width = 4
--bar.height = 1.0
--bar.border_padding = 0
--bar.border_width = 0
--bar.ticks_count = 5
--bar.vertical = true
--
--bar:bar_properties_set("vol",
--{
--    bg           = beautiful.bg_normal,
--    fg           = beautiful.fg_normal,
--    fg_off       = beautiful.graph_bg,
--    border_color = beautiful.bg_normal,
--    reverse      = false
--})

local bar = awful.widget.progressbar()
bar:set_vertical("true")
bar:set_height(13)
bar:set_width(5)
bar:set_color(beautiful.fg_normal)
bar:set_background_color(beautiful.graph_bg)
bar:set_border_color(beautiful.bg_normal)
bar:set_ticks("true")
bar:set_ticks_gap(1)
bar:set_ticks_size(2)
bar:set_max_value(100)

cardid  = 0
lastvol = 0
muted = false

local function get_vol(chan)
    if not chan then chan = "Master" end
    local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. chan)
    local status = fd:read("*all")
    fd:close()

    local volume = string.match(status, "(%d?%d?%d)%%")
    if not volume then return 0 end
    return string.format("% 3d", volume)
end

local function init()
    if tonumber(get_vol("PCM")) ~= 100 then
        muted = true
        icon:set_image(beautiful.muted)
        awful.util.spawn("amixer -q -c " .. cardid .. " sset Master 0%")
    end
    volume.update()
end

function volume.update()
    bar:set_value(get_vol())
    --bar:bar_data_add("vol", get_vol())
end

function volume.up()
    if muted then
        muted = not muted
        icon:set_image(beautiful.volume)
        awful.util.spawn("amixer -q -c " .. cardid .. " sset PCM 100%")
    end
    awful.util.spawn("amixer -q -c " .. cardid .. " sset Master 2%+")
    volume.update()
end

function volume.down()
    awful.util.spawn("amixer -q -c " .. cardid .. " sset Master 2%-")
    volume.update()
end

function volume.mute()
    local vol_chan = get_vol()
    local vol_pcm
    if muted then
        vol_pcm = 100
        icon:set_image(beautiful.volume)
    else
        vol_pcm = 0
        lastvol = 0
        icon:set_image(beautiful.muted)
    end
    muted = not muted
    awful.util.spawn("amixer -q -c " .. cardid .. " sset Master " .. lastvol .. "%")
    awful.util.spawn("amixer -q -c " .. cardid .. " sset PCM " .. vol_pcm .. "%")
    volume.update()
    lastvol = vol_chan
end


local button_table = awful.util.table.join(
        awful.button({ }, 1, function() volume.mute() end)
    )

icon:buttons(button_table)
--bar:buttons(button_table)

init()
shiny.register(volume.update, 5)

function volume.mt:__call()
	return { bar, icon }
end

return setmetatable(volume, volume.mt)
