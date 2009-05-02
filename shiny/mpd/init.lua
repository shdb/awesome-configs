local awful = require("awful")
local beautiful = require("beautiful")
local wicked = require("wicked")
local naughty = require("naughty")
local mpd = require("mpd")

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
	open = io.open,
	popen = io.popen,
	close = io.close
}
local string = {
	find = string.find
}
local os = {
	date = os.date
}
local table = {
	insert = table.insert,
	sort = table.sort
}
local widget, button, mouse, image = widget, button, mouse, image

module("shiny.mpd")
local icon = widget({ type = "imagebox", align = "right" })
local infobox = widget({type = "textbox", name = "batterybox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })

local function fg(color, text)
    return '<span color="' .. color .. '">' .. text .. '</span>'
end

local function bold(text)
    return '<b>' .. text .. '</b>'
end

local function remove_notify(notify)
    if notify then
        naughty.destroy(notify)
        notify = nil
    end
end

local function onoff(value)
    if value then
        return "on"
    else
        return "off"
    end
end

local function update()
    local function timeformat(t)
        if tonumber(t) >= 60 * 60 then -- more than one hour !
            return os.date("%X", t)
        else
            return os.date("%M:%S", t)
        end
    end
    mpd.currentsong()
    mpd.status()

    if not mpd.is_connected() then
		openbox.text = ""
		icon.image = nil
        return ""
    end

    if mpd.is_stop() then
		icon.image = image(beautiful.mpd_stop)
        openbox.text =  fg(beautiful.hilight, "[ ") .. bold("MPD")
		return ""
    end

	if mpd.is_playing() then
		icon.image = image(beautiful.mpd_play)
	elseif mpd.is_pause() then
		icon.image = image(beautiful.mpd_pause)
	end
	openbox.text =  fg(beautiful.hilight, "[ ")
		.. awful.util.escape(mpd.artist())
		.. " - "
		.. awful.util.escape(mpd.title())
	return fg(beautiful.hilight, " | ")
		.. timeformat(mpd.elapsed_time())
		.. fg(beautiful.hilight, " / ")
		.. timeformat(mpd.time())
		.. fg(beautiful.hilight, " ]")
end

local function info()
	remove_notify(popup)
    local stat = mpd.send("status")
    local string = ""
    if not mpd.is_stop() then
        string = string .. bold("Artist:\t") .. awful.util.escape(mpd.artist()) .. "\n"
        string = string .. bold("Title:\t\t") .. awful.util.escape(mpd.title()) .. "\n"
        string = string .. bold("Album:\t") .. awful.util.escape(mpd.album()) .. "\n"
        string = string .. bold("Year:\t") .. mpd.year() .. "\t"
            .. bold("Genre: ") .. awful.util.escape(mpd.genre()) .. "\n"
    end
    string = string .. bold("random: ") .. onoff(mpd.is_random())
    string = string .. bold("\tcrossfade: ") .. onoff(mpd.is_xfade())
    popup = naughty.notify({
            title = "mpd",
            text = string,
            timeout = 0,
            hover_timeout = 0.5,
           })
end

local function build_mpd_menu()
    local menu_items = {}
    local menu_genres = mpd.list("genre")
    table.sort(menu_genres, function (a,b)
            return (a < b)
        end)
    for i = 1,#menu_genres do
        table.insert(menu_items, { awful.util.escape(menu_genres[i]),
            function() mpd.play_by_genre(menu_genres[i]) end})
    end

    menu_playlists = mpd.playlists()
    table.sort(menu_playlists, function (a,b)
            return (a < b)
        end)
    for i = 1,#menu_playlists do
        table.insert(menu_items, { awful.util.escape(menu_playlists[i]),
            function() mpd.play_playlist(menu_playlists[i]) end})
    end
    return menu_items
end

function hook()
	infobox.text = update()
end

function info_rand()
    local stat = mpd.toggle_random()
    naughty.notify {
        title = "mpd",
        text  = "random " .. onoff(stat),
        timeout = 2
    }
end

function info_crossfade()
    local stat = mpd.toggle_crossfade()
    naughty.notify {
        title = "mpd",
        text  = "crossfade " .. onoff(stat),
        timeout = 2
    }
end

local button_table = {
    button({ }, 1,
        function()
            mpd.pause()
            hook()
        end),
    button({ }, 3,
        function ()
            if not mpd.menu or #mpd.menu.items == 0 then
                mpd.menu = awful.menu.new({
                    id    = "mpd",
                    items = build_mpd_menu()
                })
            end
            mpd.menu:toggle()
        end)
}

openbox:buttons(button_table)
icon:buttons(button_table)
infobox:buttons(button_table)

openbox.mouse_enter = info
openbox.mouse_leave = function() remove_notify(popup) end
icon.mouse_enter = info
icon.mouse_leave = function() remove_notify(popup) end
infobox.mouse_enter = info
infobox.mouse_leave = function() remove_notify(popup) end


wicked.register(infobox, update, "$1", 1)

setmetatable(_M, { __call = function () return {openbox, icon, infobox} end })
