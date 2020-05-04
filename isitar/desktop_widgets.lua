local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

-- define widgets
local function setup(beautiful)
    local cpu_temp = require("isitar.widgets.cpu_temp")
    cpu_temp_widget = cpu_temp({
        main_color = gears.color(beautiful.sound_bar_volume_color),
        max_width = 50,
        font_family = beautiful.font_family,
        font_size = beautiful.font_size * 20,
    })

    awful.screen.connect_for_each_screen(function(s)
    -- custom wibox
    wibox({
        x = 10,
        y = 10,
        
        width = 1000,
        height = 500,
        screen = s,
        widget = cpu_temp_widget,
        opacity = 1,
        visible = true,
        type = "desktop",
        bg = "#00000000" -- transparent
    })
    end)
end

return setup