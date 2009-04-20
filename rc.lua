-- Include awesome libraries, with lots of useful function!
require("awful")
require("wicked")
require("beautiful")
require("naughty")
require("revelation")
require("mpd")

-- {{{ Variable definitions
theme_path = "/usr/share/awesome/themes/shdb/theme"

beautiful.init(theme_path)

-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey  = "Mod4"
alt     = "Mod1"
ctrl    = "Control"
shift   = "Shift"
volup   = "XF86AudioRaiseVolume"
voldn   = "XF86AudioLowerVolume"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,            -- 1
--    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,    -- 2
--    awful.layout.suit.tile.top,
    awful.layout.suit.fair,        -- 3
    awful.layout.suit.fair.horizontal,        -- 4
--    awful.layout.suit.magnifier,
    awful.layout.suit.max,            -- 5
--    wful.layout.suit.max.fullscreen,
    awful.layout.suit.floating        -- 6
}

-- Table of clients that should be set floating. The index may be either
-- the application class or instance. The instance is useful when running
-- a console app in a terminal like (Music on Console)
--    xterm -name mocp -e mocp
floatapps =
{
    -- by class
    ["MPlayer"] = true,
    ["pinentry"] = true,
    ["gimp"] = true,
    -- by instance
    ["mocp"] = true
}

topapps =
{
    ["MPlayer"] = true,
    ["Gkrellm"] = true,
}

-- Applications to be moved to a pre-defined tag by class or instance.
-- Use the screen and tags indices.
apptags =
{
    ["Firefox"] = { screen = 1, tag = 3 },
    ["Thunderbird"] = { screen = 1, tag = 3 },
    -- ["mocp"] = { screen = 2, tag = 4 },
}

-- Define if we want to use titlebar on all applications.
use_titlebar = false
-- }}}

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
        tags[s][tagnumber] = tag(tagname)
        -- Add tags to screen one by one
        tags[s][tagnumber].screen = s
        awful.layout.set(layouts[tags_layout[tagnumber]], tags[s][tagnumber])
        awful.tag.setmwfact(tags_mwfact[tagnumber], tags[s][tagnumber])
        awful.tag.setproperty(tags[s][tagnumber], "setslave", tags_setslave[tagnumber])
    end
    -- I'm sure you want to see at least one tag.
    tags[s][1].selected = true
end
-- }}}

function file_exists(filename)
    local file = io.open(filename)
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function round_num(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function onoff(value)
    if value then
        return "on"
    else
        return "off"
    end
end

cardid  = 0
lastvol = 0
mute = false
function volume(mode, widget, channel)
    local function get_vol(channel)
        local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. channel)
        local status = fd:read("*all")
            fd:close()
    
        local volume = string.match(status, "(%d?%d?%d)%%")
        return string.format("% 3d", volume)
    end
    if mode == "update" then
        widget:bar_data_add("vol", get_vol(channel))
    elseif mode == "up" then
        if mute then
            mute = not mute
            awful.util.spawn("amixer -q -c " .. cardid .. " sset PCM 100%")
        end
        awful.util.spawn("amixer -q -c " .. cardid .. " sset " .. channel .. " 2%+")
        volume("update", widget, channel)
    elseif mode == "down" then
        awful.util.spawn("amixer -q -c " .. cardid .. " sset " .. channel .. " 2%-")
        volume("update", widget, channel)
    elseif mode == "init" then
        if tonumber(get_vol("PCM")) ~= 100 then
            mute = true
            awful.util.spawn("amixer -q -c " .. cardid .. " sset " .. channel .. " 0%")
        end
        volume("update", widget, channel)
    else
        local vol_chan = get_vol(channel)
        local vol_pcm
        if mute then
            vol_pcm = 100
        else
            vol_pcm = 0
            lastvol = 0
        end
        mute = not mute
        awful.util.spawn("amixer -q -c " .. cardid .. " sset " .. channel .. " " .. lastvol .. "%")
        awful.util.spawn("amixer -q -c " .. cardid .. " sset PCM " .. vol_pcm .. "%")
        volume("update", widget, channel)
        lastvol = vol_chan
    end
end

-- {{{ Widgets
-- Set background color
function bg(color, text)
    return '<bg color="' .. color .. '" />' .. text
end

-- Set foreground color
function fg(color, text)
    return '<span color="' .. color .. '">' .. text .. '</span>'
end

-- Boldify text
function bold(text)
    return '<b>' .. text .. '</b>'
end

-- Widget base
-- [content]
function widget_base(content)
    if content and content ~= "" then
        return fg(beautiful.hilight, "[ ") .. content .. fg(beautiful.hilight, " ]")
    end
end

function widget_basel(content)
    if content and content ~= "" then
        return fg(beautiful.hilight, " [ ") .. content .. fg(beautiful.hilight, " |")
    end
end

function widget_baser(content)
    if content and content ~= "" then
        return " " .. content .. fg(beautiful.hilight, " ]")
    end
end

-- Widget section
-- <b>label:</b> content (| next_section)?
function widget_section(label, content, next_section)
    local section
    if content and content then
        if label and label ~= "" then
            section = bold(label .. ": ") .. content
        else
            section = content
        end
        if next_section and next_section ~= "" then
            section = section .. fg(beautiful.hilight, " | ") .. next_section
        end
    else
        section = next_section
    end
    return section
end

-- Widget value
-- content (/ next_value)?
function widget_value(content, next_value)
    local value
    if content and content then
        value = content
        if next_value and next_value ~= "" then
            value = value .. fg(beautiful.hilight, " / ") .. next_value
        end
    else
        value = next_value
    end
    return value
end

-- naughty calendar
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
        cal = string.gsub(cal, "%s" .. tonumber(os.date("%d")) .. "%s", bold(fg(beautiful.hilight, "%1")))
        cal = string.gsub(cal, "^(%s*%w+%s+%d+)", bold(fg(beautiful.hilight, "%1")))
    end
    calendar = naughty.notify {
        text = string.format('<span font_desc="%s">%s</span>', "monospace", cal),
        timeout = 0,
        hover_timeout = 0.5,
        width  = 245,
        height = 400,
    }
end

function hook_mpd()
    mpdbox.text = widget_mpd()
end

-- Get and format MPD status
-- (need the mpd lib for lua)
last_songid = nil
mpd.scroll  = 0
function widget_mpd()
    local state = ""
    local function timeformat(t)
        if tonumber(t) >= 60 * 60 then -- more than one hour !
            return os.date("%X", t)
        else
            return os.date("%M:%S", t)
        end
    end
    mpd.currentsong()
    mpd.status()

    local function unknowize(x)
        return awful.util.escape(x or "(unknow)")
    end

    if not mpd.is_connected() then
        return ""
    end

    if mpd.is_stop() then
        last_songid = false
        return widget_base(widget_section("MPD", "stopped."))
    end

    if not mpd.is_playing() then
        state = " (" .. mpd.get_state() .. ")"
    end

    if use_naughty then
        if not last_songid or last_songid ~= mpd.songid() then
            last_songid = mpd.songid()
            naughty.notify {
                text = string.format("%s: %s\n%s:  %s\n%s: %s",
                bold("artist"), unknowize(mpd.artist),
                bold("album"),  unknowize(mpd.album),
                bold("title"),  unknowize(mpd.title)),
                width = 280,
                timeout = 2
            }
        end
    end

    return widget_base(
        widget_section("", awful.util.escape(mpd.artist()) .. " - " .. awful.util.escape(mpd.title()) .. state,
        widget_section("", widget_value(timeformat(mpd.elapsed_time()), timeformat(mpd.time())))))
end

function mpd_rand()
    local stat = mpd.toggle_random()
    naughty.notify {
        title = "mpd",
        text  = "random " .. onoff(stat),
        timeout = 2
    }
end

function mpd_crossfade()
    local stat = mpd.toggle_crossfade()
    naughty.notify {
        title = "mpd",
        text  = "crossfade " .. onoff(stat),
        timeout = 2
    }
end

function net_get_up()
    local lfd, wfd, lan, wlan
    lfd = io.open("/sys/class/net/eth0/operstate")
    lan = lfd:read()
    lfd:close()
    if file_exists("/sys/class/net/wlan0/operstate") then
        wfd = io.open("/sys/class/net/wlan0/operstate")
        wlan = wfd:read()
        wfd:close()
    end
    if lan and lan == "up" then
        return "lan", "eth0"
    elseif wlan and wlan == "up" then
        return "wlan", "wlan0"
    else
        return nil, nil
    end
end

function net_get_essid(iface)
    local f = io.popen("/sbin/iwgetid " .. iface)
    local ret = ""
    for line in f:lines() do
        local _, _, essid = string.find(line, "ESSID:\"(.*)\"")
        if essid then
            ret = ret .. essid
        end
    end
    f:close()
    return ret
end

net_if = nil
net_name = nil
net_last_update = 0
function net_update(w1, w2, w3)
    local nname, nif = net_get_up()
    if not nname and not nif then
        wicked.unregister(w1, false)
        wicked.unregister(w2, false)
        openboxnet.text = ""
        w3.text = ""
        neticon.image = nil
    elseif net_if ~= nif then
        wicked.unregister(w1, true)
        wicked.unregister(w2, true)
        wicked.register(w1, wicked.widgets.net,"${" .. nif .. " down_kb}",2,"down")
        wicked.register(w2, wicked.widgets.net,"${" .. nif .. " up_kb}",2,"up")
        if nif == "wlan0" then
            neticon.image = image(beautiful.wireless)
            w3.text = bold(net_get_essid(nif)) .. fg(beautiful.hilight, " ] ")
            openboxnet.text = fg(beautiful.hilight, "[ ")
        elseif nif == "eth0" then
            neticon.image = image(beautiful.network)
            w3.text = ""
            openboxnet.text = ""
        end
        net_if = nif
        net_name = nname
    elseif nif == "wlan0" then
        net_last_update = net_last_update + 1
        if net_last_update == 3 then
            openboxnet.text = fg(beautiful.hilight, "[ ")
            w3.text = bold(net_get_essid(nif)) .. fg(beautiful.hilight, " ] ")
            --neticon.image = image(beautiful.wireless)
            net_last_update = 0
        end
    end
end

-- {{{ Wibox
gapboxr = widget { type = "textbox", align = "right" }
gapboxr.text = " "
gapboxl = widget { type = "textbox", align = "left" }
gapboxl.text = " "
openbox = widget { type = "textbox", align = "right" }
openbox.text = fg(beautiful.hilight, "[ ")
closebox = widget { type = "textbox", align = "right" }
closebox.text = fg(beautiful.hilight, " ]")
sepbox = widget { type = "textbox", align = "right" }
sepbox.text = fg(beautiful.hilight, " | ")

clockbox = widget({ type  = 'textbox',
                    name  = 'clock_wid',
                    align = 'right'
})
wicked.register(clockbox, wicked.widgets.date, widget_base("%d/%m/%Y " .. bold("%H:%M:%S")))
clockbox.mouse_enter = function() add_calendar(0) end
clockbox.mouse_leave = function() remove_notify(calendar) end

clockbox:buttons {
    button({ }, 1, function() add_calendar(-1) end),
    button({ }, 3, function() add_calendar(1)  end),
}

mpdbox = widget { type = "textbox", align = "right" }
wicked.register(mpdbox, function() return widget_mpd() end, "$1", 1)
mpdboxpopup = nil
mpdbox.mouse_enter = function()
    remove_notify(mpdboxpopup)
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
    mpdboxpopup = naughty.notify({
            title = "mpd",
            text = string,
            timeout = 0,
            hover_timeout = 0.5,
           })
end
mpdbox.mouse_leave = function() remove_notify(mpdboxpopup) end

function build_mpd_menu()
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

mpd.menu = awful.menu.new({
    id    = "mpd",
    items = build_mpd_menu()
})
 
mpdbox:buttons({
    button({ }, 1,
        function()
            mpd.pause()
            hook_mpd()
        end),
    button({ }, 3,
        function ()
            if #mpd.menu.items == 0 then
                mpd.menu = awful.menu.new({
                    id    = "mpd",
                    items = build_mpd_menu() 
                })
            end
            mpd.menu:toggle()
        end)
})

batteryicon = widget({ type = "imagebox", align = "right" })
batterybox = widget({type = "textbox", name = "batterybox", align = "right" })
openboxbat = widget({ type = "textbox", align = "right" })
closeboxbat = widget({ type = "textbox", align = "right" })
wicked.register(batterybox,
    function()
        local adapter = "BAT0"
        if file_exists("/sys/class/power_supply/"..adapter) then
            spacer = " "
            local fcur = io.open("/sys/class/power_supply/"..adapter.."/energy_now")    
            local fcap = io.open("/sys/class/power_supply/"..adapter.."/energy_full")
            local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
            local cur = fcur:read()
            local cap = fcap:read()
            local sta = fsta:read()
            local battery = math.floor(cur * 100 / cap)
            if sta:match("Charging") then
                battery = battery .. "% A/C"
            elseif sta:match("Discharging") then
                if tonumber(battery) <= 3 then
                    naughty.notify({
                        title      = "Battery Warning",
                        text       = "Battery low!"..spacer..battery.."%"..spacer.."left!",
                        timeout    = 5,
                        position   = "top_right",
                        fg         = beautiful.fg_focus,
                        bg         = beautiful.bg_focus,
                    })
                end
                if tonumber(battery) < 10 then
                    battery = fg("#ff0000", battery .. "%")
                elseif tonumber(battery) < 20 then
                    battery = fg("#ffff00", battery .. "%")
                else
                    battery = battery .. "%"
                end
            else
                battery = "A/C"
            end
            fcur:close()
            fcap:close()
            fsta:close()
            openboxbat.text = fg(beautiful.hilight, " [ ")
            closeboxbat.text = fg(beautiful.hilight, " ]")
            batteryicon.image = image(beautiful["battery"])
            return battery
        else
            openboxbat.text = ""
            closeboxbat.text = ""
            batteryicon.image = nil
            return ""
        end
    end,
"$1", 5)

batteryboxpopup = nil
batterybox.mouse_enter = function()
    local function battery_remaining()
        local f = io.popen("acpi -t")
        local ret = nil
        for line in f:lines() do
            local _, _, rem = string.find(line, "(..:..:..) remaining")
            if rem then
                ret = rem
            end
        end
        f:close()
        return ret
    end
    remove_notify(batteryboxpopup)
    local timerem = battery_remaining()
    if timerem then
        batteryboxpopup = naughty.notify({
                title = "battery",
                text = timerem .. " remaining",
                timeout = 0,
                hover_timeout = 0.5,
               })
    end
end
batterybox.mouse_leave = function() remove_notify(batteryboxpopup) end

cpuicon = widget({ type = "imagebox", align = "right" })
cpuicon.image = image(beautiful["cpu"])
cpubox = widget({type = "textbox", name = "cpubox", align = "right" })
wicked.register(cpubox,
    function()
        local fhz = io.open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
        local hz = fhz:read();
        fhz:close()
        return round_num(hz/10^6, 1) .. " GHz"
    end,
"$1")

volumeicon = widget({ type = "imagebox", align = "right" })
volumeicon.image = image(beautiful["volume"])
volumeicon:buttons({
    button({ }, 1, function() volume("mute", volumebar, "Master") end)
})
volumebar =  widget({ type = "progressbar", name = "volumebar", align = "right" })
volumebar.width = 4
volumebar.height = 1.0
volumebar.border_padding = 0
volumebar.border_width = 0
volumebar.ticks_count = 5
volumebar.vertical = true

volumebar:bar_properties_set("vol", 
{ 
    bg           = beautiful.bg_normal,
    fg           = beautiful.fg_normal,
    fg_off       = beautiful.graph_bg,
    border_color = beautiful.bg_normal,
    reverse      = false
})
volume("init", volumebar, "Master")
volumebar:buttons({
    button({ }, 1, function() volume("mute", volumebar, "Master") end)
})

cpugraph = widget({
    type  = 'graph',
    name  = 'cpugraph',
    align = 'right'
})

cpugraph.height = 0.85
cpugraph.width = 35
cpugraph.bg = beautiful.graph_bg
cpugraph.border_color = beautiful.bg_normal
cpugraph.grow = 'right'

cpugraph:plot_properties_set('cpu', {
    fg = beautiful.fg_normal,
    vertical_gradient = false
})

wicked.register(cpugraph, wicked.widgets.cpu, '$1', 1, 'cpu')

memicon = widget({ type = "imagebox", align = "right" })
memicon.image = image(beautiful["mem"])
membar =  widget({ type = "progressbar", align = "right" })
membar.width = 4
membar.height = 1.0
membar.border_padding = 0
membar.border_width = 0
membar.ticks_count = 5
membar.vertical = true

membar:bar_properties_set("mem", 
{ 
    bg           = beautiful.bg_normal,
    fg           = beautiful.fg_normal,
    fg_center    = beautiful.graph_center,
    fg_end       = beautiful.graph_end,
    fg_off       = beautiful.graph_bg,
    border_color = beautiful.bg_normal,
    reverse      = false
})

wicked.register(membar, wicked.widgets.mem, '$1', 1, 'mem')

-- CPU Temp Widget
cputempicon = widget({ type = "imagebox", align = "right" })
cputempicon.image = image(beautiful["temp"])
cputempbox = widget({type = "textbox", align="right"})

wicked.register(cputempbox,
    function ()
        local f = io.popen("acpi -t")
        local ret = ""
        for line in f:lines() do
            local _, _, temp = string.find(line, "(..)\.. degrees")
            if temp then
                ret = ret .. temp .. "C, "
            end
        end
        f:close()
        ret = ret:sub(0, ret:len() - 2)
        return ret
    end,
"$1", 5)

-- net
netbox = widget({type = "textbox", name = "netbox", align = "right" })
openboxnet = widget { type = "textbox", align = "right" }
neticon = widget({ type = "imagebox", align = "right" })
netgraph_down = widget({
   type  = 'graph',
   name  = 'netgraph_down',
   align = 'right'
})
netgraph_up = widget({
    type  = 'graph',
    name  = 'netgraph_up',
    align = 'right'
})
netgraph_down.height = 0.85
netgraph_down.width = 35
netgraph_down.bg = beautiful.graph_bg
netgraph_down.border_color = beautiful.bg_normal
netgraph_down.grow = 'right'

netgraph_up.height = 0.85
netgraph_up.width = 35
netgraph_up.bg = beautiful.graph_bg
netgraph_up.border_color = beautiful.bg_normal
netgraph_up.grow = 'right'

netgraph_down:plot_properties_set('down', {
    fg                = beautiful.fg_normal,
    vertical_gradient = false
})
netgraph_up:plot_properties_set('up', {
    fg                = beautiful.fg_normal,
    vertical_gradient = false
})
net_update(netgraph_down, netgraph_up, netbox)

--[[
netwidget = widget({
                      type = 'textbox',
                      name = 'netwidget',
                      align = 'right'

                   })
wicked.register(netwidget, wicked.widgets.net,
                'wlan0:  ${wlan0 down_kb} / ${wlan0 up_kb}',
                nil, nil, 8)
--]]

-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu.new({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal }
    }
})

--mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
--                                     menu = mymainmenu })

-- Create a systray
mysystray = widget({ type = "systray", align = "right" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = {
    button({ }, 1, awful.tag.viewonly),
    button({ modkey }, 1, awful.client.movetotag),
    button({ }, 3, function (tag) tag.selected = not tag.selected end),
    button({ modkey }, 3, awful.client.toggletag),
    button({ }, 4, awful.tag.viewnext),
    button({ }, 5, awful.tag.viewprev)
}
mytasklist = {}
--[[
mytasklist.buttons = { button({ }, 1, function (c)
                                          if not c:isvisible() then
                                              awful.tag.viewonly(c:tags()[1])
                                          end
                                          client.focus = c
                                          c:raise()
                                      end),
                       button({ }, 3, function () if instance then instance:hide() end instance = awful.menu.clients({ width=250 }) end),
                       button({ }, 4, function ()
                                          awful.client.focus.byidx(1)
                                          if client.focus then client.focus:raise() end
                                      end),
                       button({ }, 5, function ()
                                          awful.client.focus.byidx(-1)
                                          if client.focus then client.focus:raise() end
                                      end) }
]]--

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = widget({ type = "textbox", align = "left" })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = widget({ type = "imagebox", align = "left" })
    mylayoutbox[s]:buttons({
        button({ }, 1, function () awful.layout.inc(layouts, 1) end),
        button({ }, 3, function () awful.layout.inc(layouts, -1) end),
        button({ }, 4, function () awful.layout.inc(layouts, 1) end),
        button({ }, 5, function () awful.layout.inc(layouts, -1) end)
    })
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist.new(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    --[[
    mytasklist[s] = awful.widget.tasklist.new(function(c)
                                                  return awful.widget.tasklist.label.currenttags(c, s)
                                              end, mytasklist.buttons)
    ]]--
    mytasklist[s] = widget({ type = "textbox", align = "left" })

    -- Create the wibox
    mywibox[s] = wibox({ position = "top", fg = beautiful.fg_normal, bg = beautiful.bg_normal })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        --mylauncher,
        mylayoutbox[s],
        gapboxl,
        mytaglist[s],
        mytasklist[s],
        gapboxl,
        mypromptbox[s],
        mpdbox,
        openboxbat, batteryicon, batterybox, closeboxbat,
        gapboxr,
        openboxnet, neticon, netbox, netgraph_down, netwidget, netgraph_up,
        gapboxr,
        openbox, cpuicon, cpubox, sepbox, cputempicon, cputempbox, closebox,
        gapboxr,
        cpugraph,
        gapboxr,
        memicon, membar,
        gapboxr,
        volumeicon, volumebar,
        gapboxr,
        clockbox,
        s == 1 and mysystray or nil
    }
    mywibox[s].screen = s
end
-- }}}

-- {{{ Mouse bindings
root.buttons({
    button({ }, 3, function () mymainmenu:toggle() end),
    button({ }, 4, awful.tag.viewnext),
    button({ }, 5, awful.tag.viewprev)
})
-- }}}

-- {{{ Key bindings
globalkeys =
{
    key({ modkey,           }, "Left",  awful.tag.viewprev       ),
    key({ modkey,           }, "Right", awful.tag.viewnext       ),
    key({ modkey,           }, "Escape",awful.tag.history.restore),

    key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    key({ modkey, shift     }, "j",     function () awful.client.swap.byidx(  1) end),
    key({ modkey, shift     }, "k",     function () awful.client.swap.byidx( -1) end),
    key({ modkey, ctrl      }, "j",     function () awful.screen.focus( 1)       end),
    key({ modkey, ctrl      }, "k",     function () awful.screen.focus(-1)       end),
    key({ modkey,           }, "u",     awful.client.urgent.jumpto),
    key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    key({ modkey,           }, "Return",function () awful.util.spawn(terminal) end),
    key({ modkey, ctrl      }, "r",     awesome.restart),
    key({ modkey, shift     }, "q",     awesome.quit),

    key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.01)    end),
    key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.01)    end),
    key({ modkey, ctrl      }, "j",     function () awful.client.incwfact(0.01)   end),
    key({ modkey, ctrl      }, "k",     function () awful.client.incwfact(-0.01)  end),
    key({ modkey, shift     }, "h",     function () awful.tag.incnmaster( 1)      end),
    key({ modkey, shift     }, "l",     function () awful.tag.incnmaster(-1)      end),
    key({ modkey, ctrl      }, "h",     function () awful.tag.incncol( 1)         end),
    key({ modkey, ctrl      }, "l",     function () awful.tag.incncol(-1)         end),
    key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    key({ modkey, shift     }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    key({ modkey }, "F1",
        function ()
            awful.prompt.run({ prompt = fg(beautiful.hilight, "Run: ") },
            mypromptbox[mouse.screen],
            awful.util.spawn, awful.completion.bash,
            awful.util.getdir("cache") .. "/history")
        end),

    key({ modkey }, "F4",
        function ()
            awful.prompt.run({ prompt = "Run Lua code: " },
            mypromptbox[mouse.screen],
            awful.util.eval, awful.prompt.bash,
            awful.util.getdir("cache") .. "/history_eval")
        end),

    key({                   }, volup,   function () volume("up", volumebar, "Master") end),
    key({                   }, voldn,   function () volume("down", volumebar, "Master") end),
    key({ alt, ctrl         }, "j",     function () volume("down", volumebar, "Master") end),
    key({ alt, ctrl         }, "k",     function () volume("up", volumebar, "Master") end),
    key({ alt, ctrl         }, "m",     function () volume("mute", volumebar, "Master") end),
    key({ alt, ctrl         }, "space", function () mpd.pause();  hook_mpd() end),
    key({ alt, ctrl         }, "s",     function () mpd.stop();         hook_mpd() end),
    key({ alt, ctrl         }, "h",     function () mpd.previous();     hook_mpd() end),
    key({ alt, ctrl         }, "l",     function () mpd.next();         hook_mpd() end),
    key({ alt, ctrl         }, "z",     function () mpd_rand();         hook_mpd() end),
    key({ alt, ctrl         }, "x",     function () mpd_crossfade();         hook_mpd() end),
    key({ modkey, alt, ctrl }, "x",     function () awful.util.spawn("xrandr --auto") end),
    key({ modkey            }, "F2",    function () revelation.revelation() end),
    key({ modkey            }, "s",
        function()
            for unused, ttag in pairs(awful.tag.selectedlist(mouse.screen)) do
                for unused, tclient in pairs(ttag:clients()) do
                    if tclient.minimized then
                        tclient.minimized = false
                    end
                end
            end
        end),
}

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys =
{
    key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    key({ modkey            }, "c",      function (c) c:kill()                         end),
    key({ modkey, ctrl      }, "space",  awful.client.floating.toggle                     ),
    key({ modkey, ctrl      }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    key({ modkey, shift     }, "r",      function (c) c:redraw()                       end),
    key({ modkey            }, "t",      awful.client.togglemarked                        ),
    key({ modkey            }, "i",      function(c) c.minimized = true                end),
    key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),

    key({ modkey, ctrl }, "t",
        function (c)
            if topapps[c.class] then
                topapps[c.class] = not topapps[c.class]
                c.ontop = topapps[c.class]
            else
                c.ontop = not c.ontop
            end
        end),

    key({ modkey, "Ctrl" }, "i",
        function ()
            local s = mouse.screen
            local string = ""
            if client.focus then
                if client.focus.class then
                    string = string .. bold("Class: ") .. client.focus.class .. "\n"
                end
                if client.focus.instance then
                    string = string .. bold("Instance: ") .. client.focus.instance .. "\n"
                end
                if client.focus.role then
                    string = string .. bold("Role: ") .. client.focus.role
                end
                naughty.notify {
                    title = "Client Info",
                    text  = string,
                }
            end
        end),
    key({ modkey, alt       }, "j",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 0, 2)
            end
        end),
    key({ modkey, alt       }, "k",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, -2, 0, 2)
            end
        end),
    key({ modkey, alt       }, "l",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 2, 0)
            end
        end),
    key({ modkey, alt       }, "h",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(-2, 0, 2, 0)
            end
        end),
    key({ modkey, alt, shift}, "j",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, 0, -2)
            end
        end),
    key({ modkey, alt, shift}, "k",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 2, 0, -2)
            end
        end),
    key({ modkey, alt, shift}, "l",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 0, -2, 0)
            end
        end),
    key({ modkey, alt, shift}, "h",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(2, 0, -2, 0)
            end
        end),
    key({ modkey, alt, ctrl }, "j",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, 2, 0, 0)
            end
        end),
    key({ modkey, alt, ctrl }, "k",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(0, -2, 0, 0)
            end
        end),
    key({ modkey, alt, ctrl }, "l",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(2, 0, 0, 0)
            end
        end),
    key({ modkey, alt, ctrl }, "h",
        function(c)
            if awful.client.floating.get(c) then
                awful.client.moveresize(-2, 0, 0, 0)
            end
        end),
}

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
    keynumber = math.min(9, math.max(#tags[s], keynumber));
end

for i = 1, keynumber do
    table.insert(globalkeys,
        key({ modkey }, i,
            function ()
                local screen = mouse.screen
                if tags[screen][i] then
                    awful.tag.viewonly(tags[screen][i])
                end
            end))
    table.insert(globalkeys,
        key({ modkey, ctrl }, i,
            function ()
                local screen = mouse.screen
                if tags[screen][i] then
                    tags[screen][i].selected = not tags[screen][i].selected
                end
            end))
    table.insert(globalkeys,
        key({ modkey, shift   }, i,
            function ()
                if client.focus and tags[client.focus.screen][i] then
                    awful.client.movetotag(tags[client.focus.screen][i])
                end
            end))
    table.insert(globalkeys,
        key({ modkey, ctrl, shift   }, i,
            function ()
                if client.focus and tags[client.focus.screen][i] then
                    awful.client.toggletag(tags[client.focus.screen][i])
                end
            end))
end


for i = 1, keynumber do
    table.insert(globalkeys, key({ modkey, shift   }, "F" .. i,
        function ()
            local screen = mouse.screen
            if tags[screen][i] then
                for k, c in pairs(awful.client.getmarked()) do
                    awful.client.movetotag(tags[screen][i], c)
                end
            end
        end))
end

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Hooks
-- Hook function to execute when focusing a client.
awful.hooks.focus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_focus
    end
end)

-- Hook function to execute when unfocusing a client.
awful.hooks.unfocus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_normal
    end
end)

-- Hook function to execute when marking a client
awful.hooks.marked.register(function (c)
    c.border_color = beautiful.border_marked
end)

-- Hook function to execute when unmarking a client.
awful.hooks.unmarked.register(function (c)
    c.border_color = beautiful.border_focus
end)

-- Hook function to execute when the mouse enters a client.
awful.hooks.mouse_enter.register(function (c)
    -- Sloppy focus, but disabled for magnifier layout
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- Hook function to execute when a new client appears.
awful.hooks.manage.register(function (c, startup)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for filtered windows (i.e. no dock, etc).
    if not startup and awful.client.focus.filter(c) then
        c.screen = mouse.screen
    end

    if use_titlebar then
        -- Add a titlebar
        awful.titlebar.add(c, { modkey = modkey })
    end
    -- Add mouse bindings
    c:buttons({
        button({ }, 1, function (c) client.focus = c; c:raise() end),
        button({ modkey }, 1, awful.mouse.client.move),
        button({ modkey }, 3, awful.mouse.client.resize)
    })
    -- New client may not receive focus
    -- if they're not focusable, so set border anyway.
    c.border_width = beautiful.border_width
    c.border_color = beautiful.border_normal

    -- Check if the application should be floating.
    local cls = c.class
    local inst = c.instance
    if floatapps[cls] then
        awful.client.floating.set(c, floatapps[cls])
    elseif floatapps[inst] then
        awful.client.floating.set(c, floatapps[inst])
    end

    -- Check application->screen/tag mappings.
    local target
    if apptags[cls] then
        target = apptags[cls]
    elseif apptags[inst] then
        target = apptags[inst]
    end
    if target then
        c.screen = target.screen
        awful.client.movetotag(tags[target.screen][target.tag], c)
    end

    -- Do this after tag mapping, so you don't see it on the wrong tag for a split second.
    client.focus = c

    -- Set key bindings
    c:keys(clientkeys)

    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if awful.tag.getproperty(c:tags()[1], "setslave") then
        awful.client.setslave(c)
    end

    -- no offscreen or over the statusbar placement - except flash in fullscreen
    if not cls == "Firefox" and not inst == "Firefox" then
        awful.placement.no_offscreen(c)
    end

    -- Honor size hints: if you want to drop the gaps between windows, set this to false.
    -- c.size_hints_honor = false
    if cls == "MPlayer" then
        c.size_hints_honor = true
    else
        c.size_hints_honor = false
    end

end)

-- Hook function to execute when arranging the screen.
-- (tag switch, new client, etc)
awful.hooks.arrange.register(function (screen)
    local layout = awful.layout.getname(awful.layout.get(screen))
    if layout and beautiful["layout_" ..layout] then
        mylayoutbox[screen].image = image(beautiful["layout_" .. layout])
    else
        mylayoutbox[screen].image = nil
    end

    -- Give focus to the latest client in history if no window has focus
    -- or if the current window is a desktop or a dock one.
    if not client.focus then
        local c = awful.client.focus.history.get(screen, 0)
        if c then client.focus = c end
    end

    -- tasklist and topapps
    local ccount = 0
    local selc = 0
    local mcount = 0
    for unused, ttag in pairs(awful.tag.selectedlist(screen)) do
        for unused, tclient in pairs(ttag:clients()) do
            if topapps[tclient.class] and not tclient.fullscreen then
                tclient.ontop = true
            end
            ccount = ccount + 1
            if tclient == client.focus then
                selc = ccount
            end
            if tclient.minimized then
                mcount = mcount + 1
                ccount = ccount - 1
            end
        end
    end
    if mcount > 0 then
        mytasklist[screen].text = widget_base(
            widget_section("", widget_value(selc, ccount),
            widget_section("", mcount)))
    else
        mytasklist[screen].text = widget_base(widget_section("", widget_value(selc, ccount)))
    end

    -- borders
    local tiledclients = awful.client.tiled(screen)
    if (#tiledclients == 0) then return end
    for unused, current in pairs(tiledclients) do
        if awful.client.floating.get(current) or layout == "floating" then
            current.border_width = beautiful.border_width
        elseif (#tiledclients == 1) or layout == "max" then
            current.border_width = 0
        else
            current.border_width = beautiful.border_width
        end
    end
end)


awful.hooks.timer.register(5, function ()
    volume("update", volumebar, "Master")
    net_update(netgraph_down, netgraph_up, netbox)
end)
-- }}}

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4
