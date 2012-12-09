local awful   = require("awful")

-- locks the screen
lock = {}

function lock.lock(c)
    awful.util.spawn_with_shell("killall unclutter; i3lock -c 000000 -d; unclutter -grab -idle 1 &")
end

return lock
