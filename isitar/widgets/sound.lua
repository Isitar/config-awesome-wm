local gears = require("gears")
local awful = require("awful")
local base = require("wibox.widget.base")
local helpers  = require("isitar.helpers")

-- notifier for debug
local naughty = require("naughty")
local function message(text)
	naughty.notify({ preset = naughty.config.presets.critical,
	title = "",
	text = text })
end

local function factory(args)
    local widget = base.make_widget()

    local props = {}

    props.args = args or {}
    -- functional args
    props.cmd = args.cmd or "pactl"
    props.channel = args.channel or "0"
    -- style args
    props.main_color = args.main_color or gears.color("#00ff00")
    props.muted_color = args.muted_color or gears.color("#ff0000")
    props.max_width = args.max_width or 200
    props.num_bars = args.num_bars or 4

    props.speaker_padding_top = args.speaker_padding_top or 0.1
    props.speaker_padding_bottom = args.speaker_padding_bottom or 0.1
    props.padding_top = args.padding_top or 0.1
    props.padding_bottom = args.padding_bottom or 0.1
    
    -- internal props
    props.muted = false
    props.level = 100

    -- function to get the required space
    function widget:fit(context, width, height)
        return math.min(props.max_width, width), height
    end

    
    local function draw_bar(cr, x0, y0, width, height)        
        cr:rectangle(x0,y0,width,height)
        cr:fill()
    end

    local function draw_speaker(cr, x0, y0, width, height)                        
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

    function draw_normal(context, cr, width, height)
        local triangle_width = 0.2 * width;
  
        if (props.muted) then
            cr:set_source(props.muted_color)            
        else
            cr:set_source(props.main_color)
        end

        -- draw sepaker
        local speaker_pt = props.speaker_padding_top * height
        local speaker_height = height - speaker_pt - props.speaker_padding_bottom * height

        draw_speaker(cr, 0, speaker_pt, triangle_width, speaker_height)

        local pt = props.padding_top * height
        local bar_height = height - pt - props.padding_bottom * height

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

    function draw_nyan(context, cr, width, height)

        local triangle_width = 0.2 * width;
  
        local alpha = 1
        if (props.muted) then
            alpha = 0.5
        end


        local padding = height / 8
        local cat_width = height * 1.5
        local cat_height = height - 2 * padding
        local cat_head_width = cat_width * 0.3
        local cat_head_height = cat_height * 0.5
        local cat_body_width = cat_width * 0.6
        local bar_height = (height - (2 * padding)) / 6

        local rainbow_width = (width - cat_width) * (props.level / 100)

        local set_gray = function()
            cr:set_source_rgba(0.5,0.5,0.5,alpha)
        end

        cr:set_source_rgba(1, 0, 0, alpha)        
        cr:rectangle(0,0*bar_height + padding,rainbow_width,bar_height)
        cr:fill()
        cr:set_source_rgba(1, 0.5, 0, alpha)        
        cr:rectangle(0,1*bar_height + padding,rainbow_width,bar_height)
        cr:fill()
        cr:set_source_rgba(1, 1, 0, alpha)        
        cr:rectangle(0,2*bar_height + padding,rainbow_width,bar_height)
        cr:fill()
        cr:set_source_rgba(0, 1, 0, alpha)        
        cr:rectangle(0,3*bar_height + padding,rainbow_width,bar_height)
        cr:fill()
        cr:set_source_rgba(0, 0, 1, alpha)        
        cr:rectangle(0,4*bar_height + padding,rainbow_width,bar_height)
        cr:fill()
        cr:set_source_rgba(0.5, 0, 1, alpha)        
        cr:rectangle(0,5*bar_height + padding,rainbow_width,bar_height)
        cr:fill()
        
        -- cat body
        cr:set_source_rgba(1,0,1,alpha)
        cr:rectangle(rainbow_width, padding, cat_body_width, height - 2 * padding)
        cr:fill()
        cr:set_source_rgba(0,0,0,alpha)
        cr:rectangle(rainbow_width, padding, cat_body_width, height - 2 * padding)
        cr:stroke()

        -- cat head    
        local cat_head_x0 = rainbow_width + 0.75 * cat_body_width
        local cat_head_y0 = padding + cat_height - cat_head_height
        local cat_head_ear_width = cat_head_width * 0.3
        local cat_head_ear_height = cat_head_height * 0.3
        local cat_head_ear2_x0 = cat_head_x0 + cat_head_width - cat_head_ear_width
        
        set_gray()
        --cr:set_source_rgba(0.5,0.5,0.5,alpha)
        -- ear 1
        cr:move_to(cat_head_x0, cat_head_y0)
        cr:line_to(cat_head_x0 + cat_head_ear_width / 2, cat_head_y0 - cat_head_ear_height)
        cr:line_to(cat_head_x0 + cat_head_ear_width, cat_head_y0)
        cr:line_to(cat_head_ear2_x0, cat_head_y0)
        -- ear 2
        cr:line_to(cat_head_ear2_x0 + cat_head_ear_width / 2, cat_head_y0 - cat_head_ear_height)
        cr:line_to(cat_head_ear2_x0 + cat_head_ear_width, cat_head_y0)
        -- rest of head
        cr:line_to(cat_head_x0 + cat_head_width, cat_head_y0 + cat_head_height)
        cr:line_to(cat_head_x0, cat_head_y0 + cat_head_height)
        cr:line_to(cat_head_x0, cat_head_y0)        
        cr:fill()

        cr:set_source_rgba(0,0,0,alpha)
        -- ear 1
        cr:move_to(cat_head_x0, cat_head_y0)
        cr:line_to(cat_head_x0 + cat_head_ear_width / 2, cat_head_y0 - cat_head_ear_height)
        cr:line_to(cat_head_x0 + cat_head_ear_width, cat_head_y0)
        cr:line_to(cat_head_ear2_x0, cat_head_y0)
        -- ear 2
        cr:line_to(cat_head_ear2_x0 + cat_head_ear_width / 2, cat_head_y0 - cat_head_ear_height)
        cr:line_to(cat_head_ear2_x0 + cat_head_ear_width, cat_head_y0)
        -- rest of head
        cr:line_to(cat_head_x0 + cat_head_width, cat_head_y0 + cat_head_height)
        cr:line_to(cat_head_x0, cat_head_y0 + cat_head_height)
        cr:line_to(cat_head_x0, cat_head_y0)        
        cr:stroke()

        -- eyes
        cr:set_line_width(1)
        cr:set_source_rgba(0,0,0,alpha)
        cr:rectangle(cat_head_x0 + cat_head_width / 3, cat_head_y0 + padding, padding, padding)
        cr:stroke()
        cr:rectangle(cat_head_x0 + 2 * cat_head_width / 3, cat_head_y0 + padding, padding, padding)
        cr:stroke()

        -- tail
        set_gray()
        cr:move_to(rainbow_width, padding + 0.5 * cat_height)
        cr:line_to(rainbow_width - 0.3 *cat_body_width, padding + 0.25 * cat_height)
        cr:line_to(rainbow_width, padding + 0.75 * cat_height)
        cr:fill()
        cr:set_source_rgba(0,0,0,alpha)
        cr:move_to(rainbow_width, padding + 0.5 * cat_height)
        cr:line_to(rainbow_width - 0.3 *cat_body_width, padding + 0.25 * cat_height)
        cr:line_to(rainbow_width, padding + 0.75 * cat_height)
        cr:stroke()

        -- feet
        for i=0,3 do
            set_gray()
            cr:rectangle(rainbow_width + i * 0.25 * cat_body_width, padding + cat_height - 0.5 * padding, 0.125 * cat_body_width,  padding)
            cr:fill()
            cr:set_source_rgba(0,0,0,alpha)
            cr:rectangle(rainbow_width + i * 0.25 * cat_body_width, padding + cat_height - 0.5 * padding, 0.125 * cat_body_width,  padding)
            cr:stroke()
        end    
        
    end

    -- called when to draw the widget
    function widget:draw(context, cr, width, height)
        draw_nyan(context, cr, width, height)
    end

    -- refresh props based on real values
    function widget:update_props()
        -- local format_cmd = string.format("%s list sinks | sed -n -e '/Sink #%s/,/Sink #/ p' | sed -n -e '/Mute:/,/Volume:/ p'", props.cmd, props.channel)
        local format_cmd = string.format("%s list sinks", props.cmd)

        helpers.async(format_cmd, function(sinkOutputs)

            local sinkExtractionPattern = string.format('.*Sink #%s(.*)Sink #', props.channel);          
            local relevantSinkOutput = string.match(sinkOutputs, sinkExtractionPattern)
            if (nil == relevantSinkOutput) then
                sinkExtractionPattern = string.format('.*Sink #%s(.*)', props.channel);    
                relevantSinkOutput = string.match(sinkOutputs, sinkExtractionPattern)                
            end
            local mute = string.match(relevantSinkOutput, "Mute: (%w*)")
            local vol = string.match(relevantSinkOutput, "Volume: front--left: %d+ /%s*(%d*)%%")
       
            if not vol or not mute then return end

            local muted = mute == "yes"

            if vol ~= props.level or muted ~= props.muted then
                props.level = tonumber(vol)
                props.muted = muted         
                widget:emit_signal("widget::redraw_needed")                                           
            end
        end)
    end

    function widget:open_mixer()
        awful.spawn(string.format("pavucontrol", terminal))
        widget:update_props()
    end

    function widget:mute()
        os.execute(string.format("%s set-sink-mute %s 1", props.cmd, props.channel))
        widget:update_props()
    end

    function widget:unmute()
        os.execute(string.format("%s set-sink-mute %s 0", props.cmd, props.channel))
        widget:update_props()
    end

    function widget:full_power()
        if (props.muted) then
            widget:unmute()
        end
        os.execute(string.format("%s set-sink-volume %s 100%%", props.cmd, props.channel))
        widget:update_props()
    end

    function widget:increse_volume()
        os.execute(string.format("%s set-sink-volume %s +1%%", props.cmd, props.channel))
        widget:update_props()
    end

    function widget:decrease_volume()
        os.execute(string.format("%s set-sink-volume %s -1%%", props.cmd, props.channel))
        widget:update_props()
    end

    -- button / keybindings
    widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() -- left click                        
            widget:open_mixer()
        end),
        awful.button({}, 2, function() -- middle click
            widget:full_power()
        end),
        awful.button({}, 3, function() -- right click
            if (props.muted) then
                widget:unmute()
            else 
                widget:mute()
            end           
        end),
        awful.button({}, 4, function() -- scroll up
            widget:increse_volume()
        end),
        awful.button({}, 5, function() -- scroll down
            widget:decrease_volume()
        end)
    ))



    helpers.newtimer(string.format("alsabar-%s-%s", props.cmd, props.channel), 5, widget.update_props)

    return widget
end

return factory