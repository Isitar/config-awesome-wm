local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")


-- local naughty = require("naughty")

-- define widgets
local function setup(beautiful)
    local cpu_stat = require("isitar.widgets.cpu_stat")
    cpu_stat_widget = cpu_stat({
        main_color = gears.color(beautiful.sound_bar_volume_color),
        max_width = 50,
        font_family = beautiful.font_family,
        font_size = beautiful.font_size * 20,
    })

    local mem_stat = require("isitar.widgets.mem_stat")
    mem_stat_widget = mem_stat({
        main_color = gears.color(beautiful.sound_bar_volume_color),
        max_width = 50,
        font_family = beautiful.font_family,
        font_size = beautiful.font_size * 20,
    })

    local dummy = wibox.widget{
        markup = '<b>Dummy widget</b>',
        align  = 'center',
        valign = 'center',
        widget = wibox.widget.textbox,
    }

    local verWibox = wibox.widget {
        dummy,
        cpu_stat_widget,
        mem_stat_widget,
        dummy,
        dummy,
        layout  = wibox.layout.flex.vertical
    }

    local screenWibox = {}
    
    local function setupWidgets(s) 
        --  
        --  CPU USAGE / TEMP
        --  MEM USAGE
        --  DISK USAGE
        --        
        
        screen_height = s.geometry.height - beautiful.toolbar_height        
        
        x0 = s.geometry.x 
        y0 = s.geometry.y

        if (nil == screenWibox[s]) then
            screenWibox[s] = wibox({
                x = x0,
                y = y0,
                height = screen_height,
                width = s.geometry.width,
                widget = verWibox,
                spacing = 2,
                opacity = 1,
                visible = true,
                type = "desktop",
                bg = "#00000000" -- transparent
            })
        else                            
            screenWibox[s].x = x0
            screenWibox[s].y = y0
            screenWibox[s].height = screen_height
            screenWibox[s].width = s.geometry.width
            screenWibox[s].widget = verWibox
            screenWibox[s].spacing = 2
            screenWibox[s].opacity = 1
            screenWibox[s].visible = true
            screenWibox[s].type = "desktop"
            screenWibox[s].bg = "#00000000" -- transparent

            screenWibox[s]:emit_signal("widget::redraw_needed")
        end
    end


    screen.connect_signal("property::geometry", setupWidgets)
    awful.screen.connect_for_each_screen(function(s)
        screenWibox[s] = nil
        setupWidgets(s)     
    end)
end



return setup