-- inspired by dmj's widget
local awful = require("awful")
local beautiful = require("beautiful")
local shiny = require("shiny")
local imap = require("imap")
local login = require("login")

local setmetatable = setmetatable
local widget, image = widget, image

module("shiny.imap")
local icon = widget({ type = "imagebox", align = "right" })
local infobox = widget({type = "textbox", name = "batterybox", align = "right" })
local openbox = widget({ type = "textbox", align = "right" })

icon.image = image(beautiful.mail)

o_imap = imap.new(login.imap_host, 143, "none", "Inbox", 5)
_, o_imap.errmsg = o_imap:connect()

_, o_imap.errmsg = o_imap:login(login.imap_user, login.imap_pass)

function update()
    if o_imap.logged_in then
    -- The check() function returns a table with the number of unread, recent
    -- and total messages in the mailbox.
    --
    -- In addition the imap library provides three separate functions that
    -- return the number of total, unread and recent messages: o_imap:recent(),
    -- o_imap:unread() and o_imap:total().
        local res, msg = o_imap:check()
        o_imap.errmsg = msg
        if res then
            if res.unread > 0 then
                infobox.text = shiny.fg("#ff0000", res.unread) .. shiny.fg(beautiful.hilight, " / ") .. res.total
            else
                infobox.text = res.unread .. shiny.fg(beautiful.hilight, " / ") .. res.total
            end
        else
            infobox.text = "E/E"
        end
    else
        if o_imap.errmsg then
            infobox.text = "E/E"
            o_imap:connect()
            o_imap:login(imap_user, imap_pass)
        else
            infobox.text = "-/-"
        end
    end
    infobox.text = infobox.text .. shiny.fg(beautiful.hilight, " ] ")
end

openbox.text = shiny.fg(beautiful.hilight, " [ ")

shiny.register(update, 60)

setmetatable(_M, { __call = function () return {infobox, icon, openbox, layout = awful.widget.layout.horizontal.rightleft} end })
