-- Include awesome libraries, with lots of useful function!
require("awful")
require("awful.autofocus")
require("awful.rules")
require("beautiful")
theme_path = awful.util.getdir("config") .. "/themes/shdb/theme.lua"
beautiful.init(theme_path)
require("naughty")
require("revelation")
require("mpd")
require("teardrop")
require("shiny")
require("shiny.appstack")
require("shiny.battery")
require("shiny.binclock")
require("shiny.borders")
require("shiny.clock")
require("shiny.cpu")
require("shiny.keyboard")
require("shiny.mpd")
require("shiny.memory")
require("shiny.net")
require("shiny.tasklist")
require("shiny.topapps")
require("shiny.volume")
require("shiny.lock")

-- {{{ Variable definitions

-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
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
--    awful.layout.suit.tile.top,
    awful.layout.suit.fair,            -- 3
    awful.layout.suit.fair.horizontal, -- 4
--    awful.layout.suit.magnifier,
    awful.layout.suit.max,             -- 5
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.floating
}

-- {{{ Tags
gold_number   = 0.618
tags_name     = { "sys",       "ssh",       "www",       "dev",       "etc" }
tags_layout   = {     1,           3,           2,           1,           2 }
tags_mwfact   = {  0.65, gold_number,        0.85, gold_number, gold_number }
tags_setslave = { false,       false,        true,       false,       false }

-- Define tags table.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = {}
    -- Create all tags on each screen
    for tagnumber, tagname in ipairs(tags_name) do
        tags[s][tagnumber] = tag({name = tagname})
        -- Add tags to screen one by one
        tags[s][tagnumber].screen = s
        awful.tag.setproperty(tags[s][tagnumber], "layout", layouts[tags_layout[tagnumber]])
        awful.tag.setproperty(tags[s][tagnumber], "mwfact", tags_mwfact[tagnumber])
        awful.tag.setproperty(tags[s][tagnumber], "setslave", tags_setslave[tagnumber])
    end
    -- I'm sure you want to see at least one tag.
    tags[s][1].selected = true
end
-- }}}

-- {{{ Wibox
gapbox = widget { type = "textbox" }
gapbox.text = " "

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

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ }, 3, function (tag) tag.selected = not tag.selected end),
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
        awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
        awful.button({ }, 2, function () mymainmenu:toggle() end),
        awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
        awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
    ))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = 15 })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylayoutbox[s],
            gapbox,
            mytaglist[s],
            shiny.tasklist(s),
            gapbox,
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        gapbox,
        shiny.binclock(12, 28, true),
        gapbox,
        shiny.clock(),
        s == 1 and mysystray or nil,
        gapbox,
        shiny.volume(),
        gapbox,
        shiny.memory(),
        gapbox,
        shiny.cpu(),
        shiny.net({["eth0"] = "lan", ["wlan0"] = "wlan"}),
        gapbox,
        shiny.battery(),
        shiny.mpd(),
        layout = awful.widget.layout.horizontal.rightleft
    }
    mywibox[s].screen = s
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, shift     }, "j",     function () awful.client.swap.byidx(  1) end),
    awful.key({ modkey, shift     }, "k",     function () awful.client.swap.byidx( -1) end),
    awful.key({ modkey, ctrl      }, "j",     function () awful.screen.focus( 1)       end),
    awful.key({ modkey, ctrl      }, "k",     function () awful.screen.focus(-1)       end),
    awful.key({ modkey,           }, "u",     awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return",function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "space", function () teardrop("urxvtc"); shiny.tasklist.update() end),
    awful.key({ modkey, ctrl      }, "r",     awesome.restart),
    awful.key({ modkey, shift     }, "q",     awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.01)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.01)    end),
    awful.key({ modkey, ctrl      }, "j",     function () awful.client.incwfact(0.01)   end),
    awful.key({ modkey, ctrl      }, "k",     function () awful.client.incwfact(-0.01)  end),
    awful.key({ modkey, shift     }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, shift     }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, ctrl      }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, ctrl      }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, ".", function () awful.layout.inc(layouts,  1)     end),
    awful.key({ modkey,           }, ",", function () awful.layout.inc(layouts, -1)     end),

    awful.key({                   }, slock,   function () shiny.lock.lock()                    end),
    awful.key({ modkey            }, "r",     function () mypromptbox[mouse.screen]:run()      end),
    awful.key({                   }, volup,   function () shiny.volume.up()                    end),
    awful.key({                   }, voldn,   function () shiny.volume.down()                  end),
    awful.key({ alt, ctrl         }, "j",     function () shiny.volume.down()                  end),
    awful.key({ alt, ctrl         }, "k",     function () shiny.volume.up()                    end),
    awful.key({ alt, ctrl         }, "m",     function () shiny.volume.mute()                  end),
    awful.key({ modkey, alt, ctrl }, "l",     function () shiny.keyboard.toggle()       end),
    awful.key({ alt, ctrl         }, "space", function () mpd.pause();        shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "s",     function () mpd.stop();         shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "h",     function () mpd.previous();     shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "l",     function () mpd.next();         shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "z",     function () shiny.mpd.info_rand();      shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "x",     function () shiny.mpd.info_crossfade(); shiny.mpd.update() end),
    awful.key({ alt, ctrl         }, "i",     function () shiny.mpd.info(3)                    end),
    awful.key({ modkey, alt, ctrl }, "x",     function () awful.util.spawn("xrandr --auto")    end),
    awful.key({ modkey            }, "F2",    function () revelation.revelation()              end),
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
    awful.key({ modkey            }, "p",      function () shiny.appstack.pop_appstack()     end)
)

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey            }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, ctrl      }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, ctrl      }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, shift     }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey            }, "t",      awful.client.togglemarked                        ),
    awful.key({ modkey            }, "i",      function (c) c.minimized = true               end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),

    awful.key({ modkey, ctrl }, "t",
        function (c)
            if shiny.topapps[c.class] then
                shiny.topapps[c.class] = not topapps[c.class]
                c.ontop = shiny.topapps[c.class]
            else
                c.ontop = not c.ontop
            end
        end),

    awful.key({ modkey, "Ctrl" }, "i",
        function ()
            local s = mouse.screen
            local string = ""
            if client.focus then
                if client.focus.class then
                    string = string .. shiny.bold("Class: ") .. client.focus.class .. "\n"
                end
                if client.focus.instance then
                    string = string .. shiny.bold("Instance: ") .. client.focus.instance .. "\n"
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
    awful.key({ modkey, alt       }, "j",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 0, 2)
            end
        end),
    awful.key({ modkey, alt       }, "k",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, -2, 0, 2)
            end
        end),
    awful.key({ modkey, alt       }, "l",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 2, 0)
            end
        end),
    awful.key({ modkey, alt       }, "h",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(-2, 0, 2, 0)
            end
        end),
    awful.key({ modkey, alt, shift}, "j",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 0, -2)
            end
        end),
    awful.key({ modkey, alt, shift}, "k",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 2, 0, -2)
            end
        end),
    awful.key({ modkey, alt, shift}, "l",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, -2, 0)
            end
        end),
    awful.key({ modkey, alt, shift}, "h",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(2, 0, -2, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "j",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 2, 0, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "k",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, -2, 0, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "l",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(2, 0, 0, 0)
            end
        end),
    awful.key({ modkey, alt, ctrl }, "h",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(-2, 0, 0, 0)
            end
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
    keynumber = math.min(9, math.max(#tags[s], keynumber));
end


for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
    awful.key({ modkey }, i,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
    awful.key({ modkey, ctrl }, i,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
    awful.key({ modkey, shift }, i,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
    awful.key({ modkey, shift, ctrl }, i,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          local c = client.focus
                          awful.client.toggletag(tags[client.focus.screen][i])
                          client.focus = c
                      end
                  end),
    awful.key({ modkey, shift }, "F" .. i,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          for k, c in pairs(awful.client.getmarked()) do
                              awful.client.movetotag(tags[screen][i], c)
                          end
                      end
                   end))
end

globalkeys = awful.util.table.join(globalkeys,
    awful.key({ modkey, shift, ctrl }, 0,
                  function ()
                      local c = client.focus
                      local ison = false
                      for t = 1, keynumber do
                          ison = false
                          for _, m in pairs(c:tags()) do
                              if tags[client.focus.screen][t] == m then ison = true end
                          end
                          if not ison then
                              awful.client.toggletag(tags[client.focus.screen][t])
                          end
                          client.focus = c
                      end
                      client.focus = c
                  end))

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true,
                     size_hints_honor = true } },
    { rule = { class = "mplayer2" },
      properties = { floating = true,
                     size_hints_honor = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][3] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)
        if awful.tag.getproperty(c:tags()[1], "setslave") then
            awful.client.setslave(c)
        end

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)
-- }}}

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4
