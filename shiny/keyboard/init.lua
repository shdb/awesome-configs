local awful   = require("awful")
local naughty = require("naughty")

local io = {
    popen = io.popen,
    close = io.close
}
local string = string

-- change keyboard layout
keyboard = {}


local function getkb()
    local f = io.popen("setxkbmap -print")
    for line in f:lines() do
        local _, _, lo = string.find(line, "+(..)+")
        if lo then
            f:close()
            return lo
        end
    end
    f:close()
end

function keyboard.toggle()
    if not layout then
        layout = getkb()
    end
    if layout == "ch" then
        awful.util.spawn_with_shell("setxkbmap -layout us; "
                .. "xmodmap " .. awful.util.getdir("config") .. "/../../.Xmodmap")
        layout = "us"
    else
        awful.util.spawn_with_shell("setxkbmap -layout ch; "
                .. "xmodmap " .. awful.util.getdir("config") .. "/../../.Xmodmap")
        layout = "ch"
    end
    naughty.notify {
        title = "keyboard layout",
        text  = "current layout: " .. layout,
        timeout = 2
    }
end

return keyboard
