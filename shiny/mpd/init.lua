local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local naughty   = require("naughty")
local mpd       = require("mpd")
local wibox     = require("wibox")

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
local capi = { mouse = mouse }
local widget, button, mouse, image = widget, button, mouse, image

-- display mpd info
mpd_mod = { mt = {} }


local icon    = wibox.widget.imagebox()
local infobox = wibox.widget.textbox()
local openbox = wibox.widget.textbox()

local function onoff(value)
    if value then
        return "on"
    else
        return "off"
    end
end

function mpd_mod.update()
    local function timeformat(t)
        if tonumber(t) >= 60 * 60 then -- more than one hour !
            return os.date("%X", t)
        else
            return os.date("%M:%S", t)
        end
    end

    mpd.status()

    if not mpd.is_connected() then
        openbox:set_text("")
        icon:set_image(nil)
        infobox:set_text("")
        return
    elseif mpd.is_stop() then
        icon:set_image(beautiful.mpd_stop)
        openbox:set_markup(shiny.fg(beautiful.hilight, "[ ") .. shiny.bold("MPD"))
        infobox:set_markup(shiny.fg(beautiful.hilight, " ]"))
        return
    end

    mpd.currentsong()

    if mpd.is_playing() then
        icon:set_image(beautiful.mpd_play)
    elseif mpd.is_pause() then
        icon:set_image(beautiful.mpd_pause)
    end

    local ot = shiny.fg(beautiful.hilight, "[ ")
    if mpd.artist() ~= "" then
        ot = ot
            .. awful.util.escape(mpd.artist())
            .. " - "
    end
    if mpd.title() ~= "" then
        ot = ot
            .. awful.util.escape(mpd.title())
    end
    openbox:set_markup(shiny.trim(ot, 92))

    local it = ""
    if mpd.time() ~= 0 then
        it = shiny.fg(beautiful.hilight, " | ")
            .. timeformat(mpd.elapsed_time())
            .. shiny.fg(beautiful.hilight, " / ")
            .. timeformat(mpd.time())
    end
    it = it .. shiny.fg(beautiful.hilight, " ]")
    infobox:set_markup(it)
end

function mpd_mod.info(tout)
    shiny.remove_notify(popup)
    if not tout then tout = 0 end
    local string = ""
    if not mpd.is_stop() then
        string = string
            .. shiny.bold("Artist:\t") .. awful.util.escape(mpd.artist()) .. "\n"
            .. shiny.bold("Title:\t\t") .. awful.util.escape(mpd.title()) .. "\n"
            .. shiny.bold("Album:\t") .. awful.util.escape(mpd.album()) .. "\n"
            .. shiny.bold("Year:\t") .. mpd.year() .. "\t"
            .. shiny.bold("Genre: ") .. awful.util.escape(mpd.genre()) .. "\n"
    end
    string = string .. shiny.bold("random: ") .. onoff(mpd.is_random())
                    .. shiny.bold("\tcrossfade: ") .. onoff(mpd.is_xfade())
    popup = naughty.notify({
            title = "mpd",
            text = string,
            timeout = tout,
            hover_timeout = 0.5,
            screen = capi.mouse.screen,
           })
end

local function build_mpd_menu()
    local menu_items = {}
    local menu_genres = mpd.list("genre")
    table.sort(menu_genres, function(a,b)
            return (a < b)
        end)
    for i = 1,#menu_genres do
        table.insert(menu_items, { awful.util.escape(menu_genres[i]),
            function() mpd.play_by_genre(menu_genres[i]) end})
    end

    menu_playlists = mpd.playlists()
    table.sort(menu_playlists, function(a,b)
            return (a < b)
        end)
    for i = 1,#menu_playlists do
        table.insert(menu_items, { awful.util.escape(menu_playlists[i]),
            function() mpd.play_playlist(menu_playlists[i]) end})
    end
    return menu_items
end

function mpd.info_rand()
    local stat = mpd.toggle_random()
    naughty.notify {
        title = "mpd",
        text  = "random: " .. onoff(stat),
        timeout = 2
    }
end

function mpd_mod.info_crossfade()
    local stat = mpd.toggle_crossfade()
    naughty.notify {
        title = "mpd",
        text  = "crossfade: " .. onoff(stat),
        timeout = 2
    }
end

local button_table = awful.util.table.join(
    awful.button({ }, 1,
        function()
            mpd.pause()
            mpd_mod.update()
        end),
    awful.button({ }, 3,
        function()
            if not mpd.menu or #mpd.menu.items == 0 then
                mpd.menu = awful.menu.new({
                    id    = "mpd",
                    items = build_mpd_menu()
                })
            end
            mpd.menu:toggle()
        end)
)

openbox:buttons(button_table)
icon:buttons(button_table)
infobox:buttons(button_table)

openbox:connect_signal("mouse::enter", function() mpd_mod.info() end)
openbox:connect_signal("mouse::leave", function() shiny.remove_notify(popup) end)
icon:connect_signal("mouse::enter", function() mpd_mod.info() end)
icon:connect_signal("mouse::leave", function() shiny.remove_notify(popup) end)
infobox:connect_signal("mouse::enter", function() mpd_mod.info() end)
infobox:connect_signal("mouse::leave", function() shiny.remove_notify(popup) end)


shiny.register(mpd_mod.update, 1)

function mpd_mod.mt:__call()
	local layout = wibox.layout.fixed.horizontal()
	layout:add(openbox)
	layout:add(icon)
	layout:add(infobox)
    return layout
end

return setmetatable(mpd_mod, mpd_mod.mt)
