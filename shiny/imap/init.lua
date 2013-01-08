-- inspired by dmj's widget
local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local imap      = require("imap")
local login     = require("login")
local wibox     = require("wibox")

local setmetatable = setmetatable
local image = image

-- display new mails
imap = { mt = {} }


local icon = wibox.widget.imagebox()
local infobox = wibox.widget.textbox()
local openbox = wibox.widget.textbox()

icon:set_image(image(beautiful.mail))

o_imap = imap.new(login.imap_host, 143, "none", "Inbox", 5)
_, o_imap.errmsg = o_imap:connect()

_, o_imap.errmsg = o_imap:login(login.imap_user, login.imap_pass)

function imap.update()
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
                infobox:set_markup(shiny.fg("#ff0000", res.unread) .. shiny.fg(beautiful.hilight, " / ") .. res.total)
            else
                infobox:set_markup(res.unread .. shiny.fg(beautiful.hilight, " / ") .. res.total)
            end
        else
            infobox:set_text("E/E")
        end
    else
        if o_imap.errmsg then
            infobox:set_text("E/E")
            o_imap:connect()
            o_imap:login(imap_user, imap_pass)
        else
            infobox:set_text("-/-")
        end
    end
    infobox:set_text(infobox.text .. shiny.fg(beautiful.hilight, " ] "))
end

openbox:set_markup(shiny.fg(beautiful.hilight, " [ "))

shiny.register(imap.update, 60)

function imap.mt:__call
	local layout = wibox.layout.fixed.horizontal()
	layout:add(infobox)
	layout:add(icon)
	layout:add(openbox)
    return layout
end

return setmetatable(imap, imap.mt)
