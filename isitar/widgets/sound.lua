local gears = require("gears")
local awful = require("awful")
local base = require("wibox.widget.base")
local surface = require("gears.surface")
local helpers  = require("lain.helpers")

-- notifier for debug
local naughty = require("naughty")

local function factory(args)
    local widget = base.make_widget()

    local props = {}

    props.args = args or {}
    props.main_color = args.main_color or gears.color("#00ff00")
    props.muted_color = args.muted_color or gears.color("#ff0000")
    props.max_width = args.max_width or 200
    props.num_bars = args.num_bars or 4
    props.cmd = args.cmd or "amixer"
    props.channel = args.channel or "Master"


    props.muted = false
    props.level = 100

    props.padding_top = args.padding_top or 0.1
    props.padding_bottom = args.padding_bottom or 0.1
    

    

    -- function to get the required space
    function widget:fit(context, width, height)
        return math.min(props.max_width, width), height
    end

    function draw_bar(cr, x0, y0, width, height)        
        cr:rectangle(x0,y0,width,height)
        cr:fill()
    end

    function draw_speaker(cr, x0, y0, width, height)                        
        -- start left middle
        cr:move_to(x0, y0 + 0.5 * height)
        -- curve to top right
        cr:curve_to(x0 + 0.75 * width, y0 + 0.375 * height,  x0 + width, y0, x0 + width, y0)      
        -- line down
        cr:line_to(x0 + width  , y0 + height)
        -- curve back up
        cr:curve_to(x0 + 0.75 * width, y0 + 0.625 * height, x0, y0 + 0.5 * height, x0, y0 + 0.5 * height)        
        cr:fill()
    end

    -- called when to draw the widget
    function widget:draw(context, cr, width, height)
        
        local triangle_width = 0.2 * width;

        local pt = props.padding_top * height
        local bar_height = height - pt - props.padding_bottom * height

  
        if (props.muted) then
            cr:set_source(props.muted_color)            
        else
            cr:set_source(props.main_color)
        end

        -- draw sepaker
        draw_speaker(cr, 0, pt, triangle_width, bar_height)

        if (props.muted) then                
            cr:move_to(0,0)
            cr:line_to(2 * triangle_width, height)
            cr:stroke()
        end
        -- draw bars
        local bar_space = (width - triangle_width) / props.num_bars
        local bar_width = 0.5 * bar_space
        for i=0,props.num_bars - 1 do
            if (props.muted or i / props.num_bars >= (props.level / 100)) then
                cr:set_source(props.muted_color)
            else
                cr:set_source(props.main_color)
            end
            draw_bar(cr, triangle_width + (i * bar_space) + bar_width, pt, bar_width, bar_height)
        end
        
    end

    -- refresh props based on real values
    function widget:update_props()
        local format_cmd = string.format("%s get %s", props.cmd, props.channel)
        helpers.async(format_cmd, function(mixer)
            local vol, playback = string.match(mixer, "([%d]+)%%.*%[([%l]*)")
            
            if not vol or not playback then return end

            local muted = playback == "off"

            if vol ~= props.level or muted ~= props.muted then
                props.level = tonumber(vol)
                props.muted = muted         
                widget:emit_signal("widget::redraw_needed")                                           
            end
        end)
    end



    -- button / keybindings
    widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() -- left click                        
            awful.spawn(string.format("%s -e alsamixer", terminal))
            widget:update_props()
        end),
        awful.button({}, 2, function() -- middle click
           os.execute(string.format("%s set %s 100%%", props.cmd, props.channel))
           widget:update_props()
        end),
        awful.button({}, 3, function() -- right click
            os.execute(string.format("%s set %s toggle", props.cmd, props.channel))
            widget:update_props()
        end),
        awful.button({}, 4, function() -- scroll up
            os.execute(string.format("%s set %s 1%%+", props.cmd, props.channel))
            widget:update_props()
        end),
        awful.button({}, 5, function() -- scroll down
            os.execute(string.format("%s set %s 1%%-", props.cmd, props.channel))
            widget:update_props()
        end)
    ))



    helpers.newtimer(string.format("alsabar-%s-%s", props.cmd, props.channel), 5, widget.update_props)

    return widget
end

return factory