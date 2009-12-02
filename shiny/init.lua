local capi  = { timer = timer }
local beautiful = require("beautiful")
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

