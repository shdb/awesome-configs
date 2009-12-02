local capi  = { timer = timer }
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
