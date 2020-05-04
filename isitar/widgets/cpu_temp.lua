local gears = require("gears")
local awful = require("awful")
local base = require("wibox.widget.base")
local helpers  = require("lain.helpers")
local cairo = require("lgi").cairo
local wibox = require("wibox")

-- notifier for debug
local naughty = require("naughty")

local function factory(args)
    local widget = base.make_widget()

    local props = {}

    args = args or {}
    -- functional args
    props.cmd = args.cmd or "cat"
    props.path = args.path or "/sys/class/hwmon/hwmon2/temp1_input"
    -- style args
    props.main_color = args.main_color or gears.color("#00ff00")
	props.danger_color = args.danger_color or gears.color("#ff0000")
	props.danger_threshold_deg = args.danger_threshold_deg or 75
    props.font_family = args.font_family or "Courier"
    props.font_size = args.font_size or 20

	props.padding = args.padding or 0.1

    -- internal props
    props.temp_mdeg = 0    

    -- function to get the required space
    function widget:fit(context, width, height)
        return width, height
    end

    -- called when to draw the widget
	function widget:draw(context, cr, width, height)
		if (props.temp_mdeg / 1000 < props.danger_threshold_deg) then
			cr:set_source(props.main_color)
		else
			cr:set_source(props.danger_color)
		end
		
		
		-- draw chip
		x0 = props.padding * width
		y0 = props.padding * height

		chip_width = width / 2 - 2 * props.padding * width
		pin_length_horz = chip_width / 8
		chip_height = height - 2 * props.padding * height
		pin_length_vert = chip_height / 8
		dye_width = chip_width - 2 * pin_length_horz
		dye_height = chip_height - 2 * pin_length_vert

		-- dye
		cr:rectangle(x0 + pin_length_horz, y0 + pin_length_vert, dye_width, dye_height)
		cr:fill()
		-- pins
		num_pins = 6
		vert_pin_width = dye_width / (10 * num_pins)

		for i=1,num_pins do
			x_offset = x0 + pin_length_horz + i * (dye_width / (num_pins + 1))		
			cr:rectangle(x_offset - vert_pin_width / 2, y0, vert_pin_width, pin_length_vert)					
			cr:rectangle(x_offset - vert_pin_width / 2, y0 + pin_length_vert + dye_height, vert_pin_width, pin_length_vert)
		end
		horz_pin_height = dye_height / (10 * num_pins)
		for i=1,num_pins do
			y_offset = y0 + pin_length_vert + i * (dye_height / (num_pins + 1))			
			cr:rectangle(x0, y_offset - horz_pin_height / 2, pin_length_horz, horz_pin_height)		
			cr:rectangle(x0 + pin_length_horz + dye_width, y_offset - horz_pin_height / 2, pin_length_horz, horz_pin_height)			
		end
		cr:fill() 

        
        cr:move_to(width / 2 + x0, y0 + (height - y0) / 2 )
        cr:select_font_face(props.font_family, cairo.FontSlant.NORMAL, cairo.FontWeight.NORMAL)
        cr:set_font_size(props.font_size)
        cr:show_text(math.floor(props.temp_mdeg / 1000) .. "°")

    end

    -- refresh props based on real values
    function widget:update_props()
        local format_cmd = string.format("%s %s", props.cmd, props.path)
        helpers.async(format_cmd, function(temp_str)
            local temp_mdeg = tonumber(temp_str)
            
            if temp_mdeg ~= props.temp_mdegthen then
                props.temp_mdeg = temp_mdeg                 
                widget:emit_signal("widget::redraw_needed")                                           
            end
        end)
    end


    helpers.newtimer(string.format("cpu_temp-%s-%s", props.cmd, props.path), 5, widget.update_props)

    return widget
end

return factory