--------------------------
-- Matrix theme by ShdB --
--------------------------

local path = "~/.config/awesome/themes/shdb/"

theme = {}

theme.font          = "snap"

theme.bg_normal     = "#171717"
theme.bg_focus      = "#171717"
theme.bg_urgent     = "#171717"
theme.bg_minimize   = "#171717"

theme.hilight       = "#ffcc44"

theme.fg_normal     = "#449900"
theme.fg_focus      = "#66FF00"
theme.fg_urgent     = "#cc0000"

theme.graph_bg      = "#333333"
theme.graph_center  = "#779900"
theme.graph_end     = "#ff9900"

theme.border_width  = "1"
theme.border_normal = "#338000"
theme.border_focus  = "#66FF00"
theme.border_marked = "#66FF00"

theme.menu_height   = "10"
theme.menu_width    = "100"

theme.taglist_squares = "true"

theme.battery = path .. "icons/battery.png"
theme.volume = path .. "icons/volume.png"
theme.cpu = path .. "icons/cpu.png"
theme.temp = path .. "icons/temp.png"
theme.mail = path .. "icons/mail.png"
theme.mem = path .. "icons/mem.png"
theme.wireless = path .. "icons/wireless.png"
theme.network = path .. "icons/network.png"
theme.mpd_play = path .. "icons/mpd_play.png"
theme.mpd_pause = path .. "icons/mpd_pause.png"
theme.mpd_stop = path .. "icons/mpd_stop.png"

theme.layout_fairh = path .. "layouts/fairh.png"
theme.layout_fairv = path .. "layouts/fairv.png"
theme.layout_floating = path .. "layouts/floating.png"
theme.layout_max = path .. "layouts/max.png"
theme.layout_spiral = path .. "../default/layouts/spiralw.png"
theme.layout_tilebottom = path .. "layouts/tilebottom.png"
theme.layout_tile = path .. "layouts/tile.png"

return theme
