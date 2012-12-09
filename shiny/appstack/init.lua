local awful = require("awful")
local socket = require("socket")

local pairs, ipairs, screen, mouse, client, table, setmetatable
    = pairs, ipairs, screen, mouse, client, table, setmetatable

-- organize minimized clients in a stack
local appstack = {}


appstack.apps = {}

function appstack.push_appstack(c, m)
    if not c.minimized then return end
    table.insert(appstack.apps, {
        client = c,
        time = socket.gettime()
    })
end

function appstack.pop_appstack()
    local lscreen = mouse.screen
    local latest, ison, j
    for i, cm in ipairs(appstack.apps) do
        ison = false
        for _, ttag in pairs(awful.tag.selectedlist(lscreen)) do
            for _, m in pairs(cm['client']:tags()) do
                if ttag == m then ison = true end
            end
            if ison then
                if not latest or latest < cm['time'] then
                    latest = cm['time']
                    j = i
                end
            end
        end
    end
    if latest then
        local c = appstack.apps[j]['client']
        c.minimized = false -- the callback removes the client from the apps list
        client.focus = c
    end
end

function appstack.clean_appstack(c)
    if c.minimized then return end
    for i, minc in ipairs(appstack.apps) do
        if minc['client'] == c then
            table.remove(appstack.apps, i)
            appstack.clean_appstack(c)
            return
        end
    end
end

client.add_signal("manage", function(c, startup)
    c:add_signal("property::minimized", function(c)
        appstack.push_appstack(c)
        appstack.clean_appstack(c)
    end)
end)

return appstack
