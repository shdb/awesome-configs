local naughty = require("naughty")
local beautiful = require("beautiful")
local capi  = { timer = timer }
local io = { open  = io.open,
             close = io.close }
local string = { sub  = string.sub,
                 find = string.find }
local table = { insert = table.insert }
local math = { floor = math.floor }
module("shiny")

function register(func, tout)
    if not tout then tout = 60 end
    timer = capi.timer({ timeout = tout })
    timer:add_signal("timeout", func)
    timer:start()
    -- initial update
    func()
end

function fg(color, text)
	color = color or beautiful.fg_normal
    return '<span color="' .. color .. '">' .. text .. '</span>'
end

function bold(text)
    return '<b>' .. text .. '</b>'
end

function widget_base(content)
    if content and content ~= "" then
        return fg(beautiful.hilight, "[ ") .. content .. fg(beautiful.hilight, " ]")
    end
end

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

function remove_notify(notify)
    if notify then
        naughty.destroy(notify)
        notify = nil
    end
end

function file_exists(filename)
    local file = io.open(filename)
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function splitbywhitespace(str)
    values = {}
    start = 1
    splitstart, splitend = string.find(str, ' ', start)

    while splitstart do
        m = string.sub(str, start, splitstart-1)
        if m:gsub(' ','') ~= '' then
            table.insert(values, m)
        end

        start = splitend+1
        splitstart, splitend = string.find(str, ' ', start)
    end

    m = string.sub(str, start)
    if m:gsub(' ','') ~= '' then
        table.insert(values, m)
    end

    return values
end

function round_num(num, idp, dot)
    local mult = 10^(idp or 0)
    num = math.floor(num * mult + 0.5) / mult
    if dot then
        num = math.floor(num + 0.5)
    end
    return num
end
