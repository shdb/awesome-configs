local awful   = require("awful")

module("shiny.lock")

function lock(c)
    awful.util.spawn_with_shell("killall unclutter; i3lock -c 000000 -d; unclutter -grab -idle 1 &")
end
