local gears      = require("gears")
local awful      = require("awful")
require("awful.autofocus")
require("awful.rules")

local beautiful  = require("beautiful")
local theme_path = awful.util.getdir("config") .. "/themes/shdb/theme.lua"
beautiful.init(theme_path)

local naughty    = require("naughty")
local wibox      = require("wibox")
local menubar    = require("menubar")
local revelation = require("revelation")
local mpd        = require("mpd")
local teardrop   = require("teardrop")
local shifty     = require("shifty")
local shiny      = require("shiny")
shiny.appstack   = require("shiny.appstack")
shiny.battery    = require("shiny.battery")
shiny.binclock   = require("shiny.binclock")
shiny.borders    = require("shiny.borders")
shiny.clock      = require("shiny.clock")
shiny.cpu        = require("shiny.cpu")
shiny.keyboard   = require("shiny.keyboard")
shiny.lock       = require("shiny.lock")
shiny.luaprompt  = require("shiny.luaprompt")
shiny.memory     = require("shiny.memory")
shiny.mpd        = require("shiny.mpd")
shiny.net        = require("shiny.net")
shiny.screen     = require("shiny.screen")
shiny.tasklist   = require("shiny.tasklist")
shiny.topapps    = require("shiny.topapps")
shiny.volume     = require("shiny.volume")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions

terminal = "urxvt"
browser = "firefox"
mail = "sylpheed"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey  = "Mod4"
alt     = "Mod1"
ctrl    = "Control"
shift   = "Shift"
volup   = "XF86AudioRaiseVolume"
voldn   = "XF86AudioLowerVolume"
slock   = "XF86ScreenSaver"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,            -- 1
--    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,     -- 2
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,            -- 3
    awful.layout.suit.fair.horizontal, -- 4
--    awful.layout.suit.magnifier,
    awful.layout.suit.max,             -- 5
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.floating
}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

use_titlebar = false

-- Shifty configured tags.
gold_number = 0.618
shifty_tags = {}
for s = 1, screen.count() do
    shifty_tags = awful.util.table.join(shifty_tags, {
        ["w" .. s] = {
            layout    = awful.layout.suit.max,
            exclusive = false,
            position  = s,
            init      = true,
            screen    = s,
        }
    })
end

shifty.config.tags = awful.util.table.join(shifty_tags, {
    www = {
        layout      = awful.layout.suit.tile.bottom,
        exclusive   = true,
        -- max_clients = 1,
        position    = screen.count() + 1,
        spawn       = browser,
    },
    mail = {
        layout    = awful.layout.suit.tile,
        exclusive = false,
        position  = screen.count() + 2,
        spawn     = mail,
        slave     = true
    },
    win = {
        position  = 8
    },
    media = {
        layout    = awful.layout.suit.float,
        exclusive = false,
        position  = 9,
    },
})

-- SHIFTY: application matching rules
-- order here matters, early rules will be applied first
shifty.config.apps = {
    {
        match = {
            "Navigator",
            "Vimperator",
            "Gran Paradiso",
            "Firefox",
        },
        tag = "www",
    },
    {
        match = {
            "Shredder.*",
            "Thunderbird",
            "Sylpheed",
            "mutt",
        },
        tag = "mail",
    },
    {
        match = {
            "pcmanfm",
        },
        slave = true
    },
    {
        match = {
            "OpenOffice.*",
            "Abiword",
            "Gnumeric",
        },
        tag = "office",
    },
    {
        match = {
            "rdesktop",
        },
        tag = "win",
    },
    {
        match = {
            "Mplayer.*",
            "mplayer2",
            "Mirage",
            "gimp",
            "gtkpod",
            "Ufraw",
            "easytag",
        },
        tag = "media",
        -- nopopup = true,
    },
    {
        match = {
            "MPlayer",
            "mplayer2",
            "Gnuplot",
            "galculator",
        },
        float = true,
    },
    {
        match = {
            terminal,
        },
        honorsizehints = false,
        -- slave = true,
    },
    {
        match = {""},
        buttons = awful.util.table.join(
            awful.button({        }, 1, function(c) client.focus = c; c:raise() end),
            awful.button({ modkey }, 1,
                function(c)
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
            awful.button({ modkey }, 3, function(c) awful.mouse.client.resize() end)
        )
    },
}

-- SHIFTY: default tag creation rules
-- parameter description
--  * floatBars : if floating clients should always have a titlebar
--  * guess_name : should shifty try and guess tag names when creating
--                 new (unconfigured) tags?
--  * guess_position: as above, but for position parameter
--  * run : function to exec when shifty creates a new tag
--  * all other parameters (e.g. layout, mwfact) follow awesome's tag API
shifty.config.defaults = {
    layout = awful.layout.suit.tile,
    ncol = 1,
    mwfact = gold_number,
    floatBars = true,
    guess_name = true,
    guess_position = true,
}

-- {{{ Wibox
gapbox = wibox.widget.textbox()
gapbox:set_text(" ")

-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal }
    }
})

menubar.utils.terminal = terminal -- Set the terminal for applications that require it

-- Create a systray
mysystray = wibox.widget.systray()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ }, 3, function(tag) tag.selected = not tag.selected end),
    awful.button({ modkey }, 3, awful.client.toggletag),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
)

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ prompt = shiny.fg(beautiful.hilight, "Run: ") })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
        awful.button({ }, 1, function() awful.layout.inc(layouts, 1)  end),
        awful.button({ }, 2, function() mymainmenu:toggle()           end),
        awful.button({ }, 3, function() awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function() awful.layout.inc(layouts, 1)  end),
        awful.button({ }, 5, function() awful.layout.inc(layouts, -1) end)
    ))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create the wibox
    if s == 2 then
        mywibox[s] = awful.wibox({ position = "right", screen = s})
    elseif s == 3 then
        mywibox[s] = awful.wibox({ position = "left", screen = s})
    else
        mywibox[s] = awful.wibox({ position = "top", screen = s})
    end

    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylayoutbox[s])
    left_layout:add(gapbox)
    left_layout:add(mytaglist[s])
    left_layout:add(shiny.tasklist(s))
    left_layout:add(gapbox)
    if screen.count() > 1 then left_layout:add(shiny.screen(s)) end
    if screen.count() > 1 then left_layout:add(gapbox) end
    left_layout:add(mypromptbox[s])

    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(shiny.mpd())
    right_layout:add(shiny.battery())
    right_layout:add(gapbox)
    right_layout:add(shiny.net({["eth0"] = "lan", ["wlan0"] = "wlan"}))
    right_layout:add(shiny.cpu())
    right_layout:add(gapbox)
    right_layout:add(shiny.memory())
    right_layout:add(gapbox)
    right_layout:add(shiny.volume())
    right_layout:add(gapbox)
    if s == 1 then right_layout:add(mysystray) end
    if s == 1 then right_layout:add(gapbox) end
    right_layout:add(shiny.clock())
    right_layout:add(gapbox)
    right_layout:add(shiny.binclock(14, 28))

    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- SHIFTY: initialize shifty
-- the assignment of shifty.taglist must always be after its actually
-- initialized with awful.widget.taglist.new()
shifty.taglist = mytaglist
shifty.init()

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function() mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}



-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "h",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "l",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    -- Shifty: keybindings specific to shifty
    awful.key({ modkey            }, "d", shifty.del), -- delete a tag
    awful.key({ modkey, ctrl      }, "n", shifty.send_prev), -- client to prev tag
    awful.key({ modkey, alt       }, "n", shifty.send_next), -- client to next tag
    awful.key({ modkey, shift     }, "n",
        function()
            local t = awful.tag.selected()
            local s = awful.util.cycle(screen.count(), t.screen + 1)
            awful.tag.history.restore()
            t = shifty.tagtoscr(s, t)
            awful.tag.viewonly(t)
            awful.screen.focus_relative( 1)
            shiny.screen.update()
        end),
    awful.key({ modkey            }, "a", shifty.add), -- creat a new tag
    awful.key({ modkey, alt       }, "r", shifty.rename), -- rename a tag
    awful.key({ modkey, shift     }, "a", -- nopopup new tag
        function()
            shifty.add({nopopup = true})
        end),

    awful.key({ modkey,           }, "j",
        function()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function() mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, shift     }, "j",     function() awful.client.swap.byidx(  1) end),
    awful.key({ modkey, shift     }, "k",     function() awful.client.swap.byidx( -1) end),
    awful.key({ modkey            }, "n",     function() awful.screen.focus_relative( 1)
                                                         shiny.screen.update()        end),
    awful.key({ modkey            }, "p",     function() awful.screen.focus_relative(-1)
                                                         shiny.screen.update()        end),
    awful.key({ modkey,           }, "u",     awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return",function() awful.util.spawn(terminal)           end),
    awful.key({ modkey,           }, "space",
        function()
            if mouse.screen > 1 then
                teardrop("urxvtc", -15, nil, 0)
            else
                teardrop("urxvtc")
            end
            shiny.tasklist.update()
        end),

    awful.key({ modkey, ctrl      }, "r",     awesome.restart                                    ),
    awful.key({ modkey, shift     }, "q",     awesome.quit                                       ),

    awful.key({ modkey, alt       }, "l",     function() awful.tag.incmwfact( 0.01)           end),
    awful.key({ modkey, alt       }, "h",     function() awful.tag.incmwfact(-0.01)           end),
    awful.key({ modkey, ctrl      }, "j",     function() awful.client.incwfact(0.01)          end),
    awful.key({ modkey, ctrl      }, "k",     function() awful.client.incwfact(-0.01)         end),
    awful.key({ modkey, shift     }, "h",     function() awful.tag.incnmaster( 1)             end),
    awful.key({ modkey, shift     }, "l",     function() awful.tag.incnmaster(-1)             end),
    awful.key({ modkey, ctrl      }, "h",     function() awful.tag.incncol( 1)                end),
    awful.key({ modkey, ctrl      }, "l",     function() awful.tag.incncol(-1)                end),
    awful.key({ modkey,           }, ".",     function() awful.layout.inc(layouts,  1)        end),
    awful.key({ modkey,           }, ",",     function() awful.layout.inc(layouts, -1)        end),

    awful.key({                   }, slock,   function() shiny.lock.lock()                    end),
    awful.key({ modkey            }, "r",     function() mypromptbox[mouse.screen]:run()      end),
    awful.key({ modkey            }, "v",     function() shiny.luaprompt.prompt(mypromptbox)  end),
    awful.key({                   }, volup,   function() shiny.volume.up()                    end),
    awful.key({                   }, voldn,   function() shiny.volume.down()                  end),
    awful.key({ alt, ctrl         }, "j",     function() shiny.volume.down()                  end),
    awful.key({ alt, ctrl         }, "k",     function() shiny.volume.up()                    end),
    awful.key({ alt, ctrl         }, "m",     function() shiny.volume.mute()                  end),
    awful.key({ modkey, alt, ctrl }, "l",     function() shiny.keyboard.toggle()              end),
    awful.key({ alt, ctrl         }, "space", function() mpd.pause();      shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "s",     function() mpd.stop();       shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "h",     function() mpd.previous();   shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "l",     function() mpd.next();       shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "z",     function() shiny.mpd.info_rand()
                                                         shiny.mpd.update()                   end),
    awful.key({ alt, ctrl         }, "x",     function() shiny.mpd.info_crossfade()
                                                         shiny.mpd.update()                   end),
    awful.key({ alt, ctrl         }, "i",     function() shiny.mpd.info(3)                    end),
    awful.key({ modkey, alt, ctrl }, "x",     function() awful.util.spawn("xrandr --auto")    end),
    awful.key({ modkey            }, "F2",    function() revelation.revelation()              end),
    awful.key({ modkey            }, "s",
        function()
            for _, ttag in pairs(awful.tag.selectedlist(mouse.screen)) do
                for _, tclient in pairs(ttag:clients()) do
                    if tclient.minimized then
                        tclient.minimized = false
                        client.focus = tclient
                    end
                end
            end
        end),
    awful.key({ modkey            }, "e",      function() shiny.appstack.pop_appstack()     end),

    awful.key({ modkey, shift, ctrl }, 0,
        function()
            local c = client.focus
            local ison = false
            local scr = mouse.screen or 1

            for _, t in pairs(screen[scr]:tags()) do
                ison = false

                for _, m in pairs(c:tags()) do
                    if t == m then ison = true end
                end

                if not ison then
                    awful.client.toggletag(t)
                end
                client.focus = c
            end
            client.focus = c
        end)
)

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function(c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey            }, "c",      function(c) c:kill()                         end),
    awful.key({ modkey, ctrl      }, "space",  awful.client.floating.toggle                    ),
    awful.key({ modkey, ctrl      }, "Return", function(c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                       ),
    awful.key({ modkey, shift     }, "r",      function(c) c:redraw()                       end),
    awful.key({ modkey            }, "t",      awful.client.togglemarked                       ),
    awful.key({ modkey            }, "i",      function(c) c.minimized = true               end),
    awful.key({ modkey,           }, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),

    awful.key({ modkey, ctrl }, "t",
        function(c)
            if shiny.topapps[c.class] then
                shiny.topapps[c.class] = not topapps[c.class]
                c.ontop = shiny.topapps[c.class]
            else
                c.ontop = not c.ontop
            end
        end),

    awful.key({ modkey, ctrl      }, "i",
        function()
            local s = mouse.screen
            local string = ""
            if client.focus then
                if client.focus.class then
                    string = string .. shiny.bold("Class: ") .. client.focus.class .. "\n"
                end
                if client.focus.instance then
                    string = string .. shiny.bold("Instance: ") .. client.focus.instance .. "\n"
                end
                if client.focus.name then
                    string = string .. shiny.bold("Name: ") .. client.focus.name .. "\n"
                end
                if client.focus.role then
                    string = string .. shiny.bold("Role: ") .. client.focus.role
                end
                naughty.notify {
                    title = "Client Info",
                    text  = string,
                }
            end
        end),
    awful.key({ modkey, alt       }, "u",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 0, 2)
            end
        end),
    awful.key({ modkey, alt       }, "i",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, -2, 0, 2)
            end
        end),
    awful.key({ modkey, alt       }, "o",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 2, 0)
            end
        end),
    awful.key({ modkey, alt       }, "y",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(-2, 0, 2, 0)
            end
        end),
    awful.key({ modkey, alt, shift}, "u",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 0, -2)
            end
        end),
    awful.key({ modkey, alt, shift}, "i",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 2, 0, -2)
            end
        end),
    awful.key({ modkey, alt, shift}, "o",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, -2, 0)
            end
        end),
    awful.key({ modkey, alt, shift}, "y",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(2, 0, -2, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "u",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 2, 0, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "i",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, -2, 0, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "o",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(2, 0, 0, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "y",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(-2, 0, 0, 0)
            end
        end)
)

-- SHIFTY: assign client keys to shifty for use in
-- match() function(manage hook)
shifty.config.clientkeys = clientkeys
shifty.config.modkey = modkey

-- Compute the maximum number of digit we need, limited to 9
for i = 1, (shifty.config.maxtags or 9) do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, i,
            function()
                awful.tag.viewonly(shifty.getpos(i))
            end),
        awful.key({ modkey, ctrl }, i,
            function()
                local t = shifty.getpos(i)
                t.selected = not t.selected
            end),
        awful.key({ modkey, ctrl, shift }, i,
            function()
                if client.focus then
                    awful.client.toggletag(shifty.getpos(i))
                end
            end),
        -- move clients to other tags
        awful.key({ modkey, shift }, i,
            function()
                if client.focus then
                    local t = shifty.getpos(i)
                    awful.client.movetotag(t)
                    -- awful.tag.viewonly(t)
                end
            end)
    )
end

root.keys(globalkeys)

client.connect_signal("manage", function(c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    if not startup then
        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4
