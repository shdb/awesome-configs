local awful   = require("awful")

module("shiny.lock")

function lock(c)
    awful.util.spawn_with_shell("killall unclutter; xtrlock; unclutter -grab -idle 1 &")
end
