local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

-- define widgets
local function setup(beautiful)
    local cpu_stat = require("isitar.widgets.cpu_stat")
    cpu_stat_widget = cpu_stat({
        main_color = gears.color(beautiful.sound_bar_volume_color),
        max_width = 50,
        font_family = beautiful.font_family,
        font_size = beautiful.font_size * 20,
    })

    local dummy = wibox.widget{
        markup = '<b>Dummy widget</b>',
        align  = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }

    awful.screen.connect_for_each_screen(function(s)
        --  
        --  CPU USAGE / TEMP
        --  MEM USAGE
        --  DISK USAGE
        --        
        
        widgets = {
            cpu_stat_widget,
            dummy,
            dummy,
        }

        widget_height = s.geometry.height / (#widgets+ 1)


        x0 = s.geometry.x 
        y0 = s.geometry.y + widget_height / 2
        
        for i=0,#widgets -1  do
            -- custom wibox
            wibox({
                x = x0,
                y = y0 + i * widget_height,                
                width = s.geometry.width,
                height = widget_height,
                screen = s,
                widget = widgets[i + 1],
                opacity = 1,
                visible = true,
                type = "desktop",
                bg = "#00000000" -- transparent
            })
        end       
    end)
end

return setup