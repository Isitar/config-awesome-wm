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
    props.temp_cmd = args.temp_cmd or "cat"
	props.temp_path = args.temp_path or "/sys/class/hwmon/hwmon2/temp1_input"
	props.usage_cmd = args.usage_cmd or "cat"
    props.usage_path = args.usage_path or "/proc/stat"
    -- style args
    props.main_color = args.main_color or gears.color("#00ff00")
	props.danger_color = args.danger_color or gears.color("#ff0000")
	props.temp_danger_threshold_deg = args.temp_danger_threshold_deg or 75
    props.font_family = args.font_family or "Courier"    

	props.padding = args.padding or 0.1

    -- internal props
	props.temp_mdeg = 0    
	props.idle_last = {0}
	props.total_last = {0}
	props.load_percentage = {0}	

    -- function to get the required space
	function widget:fit(context, width, height)		
		if (width < height * 2) then
			return width, width /2
		else 
			return height * 2, height
		end
    end

    -- called when to draw the widget
	function widget:draw(context, cr, width, height)
		if (props.temp_mdeg / 1000 < props.temp_danger_threshold_deg) then
			cr:set_source(props.main_color)
		else
			cr:set_source(props.danger_color)
		end
		
		
		if (width < height * 2) then
			heihgt = width /2
		else 
			width = height * 2
		end

		-- debug rect
		--cr:move_to(0,0)
		--cr:rectangle(0,0,width, height)
		--cr:rectangle(0,0,width / 2, height)
		--cr:stroke()

		-- draw chip
		x0 = props.padding * width / 2
		y0 = props.padding * height

		chip_width = width / 2 - 2 * props.padding * width / 2
		pin_length_horz = chip_width / 8
		dye_width = chip_width - 2 * pin_length_horz

		chip_height = height - 2 * props.padding * height
		pin_length_vert = chip_height / 8
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

		font_size = (height - (2 * y0)) / 2
		
		-- debug rect
		-- cr:rectangle(width / 2 + x0, (height - (2 * y0)) - font_size / 2 + y0, width / 2 - 2 * x0, -font_size)
		-- cr:stroke()
		cr:move_to(width / 2 + x0, (height - (2 * y0)) - font_size / 2 + y0)
        cr:select_font_face(props.font_family, cairo.FontSlant.NORMAL, cairo.FontWeight.NORMAL)
        cr:set_font_size(font_size * 1.3)
        cr:show_text(math.floor(props.temp_mdeg / 1000) .. "°")

		local cnt = 0
		cores_per_col = 10
		for i,perc in pairs(props.load_percentage) do
			x = width + ((i-1) // cores_per_col) * 70
			y = y0 + ((i-1) % cores_per_col) * 20
		
			if (perc < 75) then
				cr:set_source(props.main_color)
			else
				cr:set_source(props.danger_color)
			end
			
			cr:move_to(x, y)
			cr:set_font_size(15)
			cr:show_text(i .. ": " .. perc)		
		end
    end

    -- refresh props based on real values
    function widget:update_props()        
        helpers.async(string.format("%s %s", props.temp_cmd, props.temp_path), function(temp_str)
            local temp_mdeg = tonumber(temp_str)
            
            if temp_mdeg ~= props.temp_mdegthen then
                props.temp_mdeg = temp_mdeg                 
                widget:emit_signal("widget::redraw_needed")                                           
            end
		end)
		
		helpers.async(string.format("%s %s", props.usage_cmd, props.usage_path), function(usage_str)			
			for cpu_i, user, nice, system, idle, iowait, irq, softirq in string.gmatch(usage_str, "cpu(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+)") do -- i ignore guest
				local i = cpu_i + 1
				local currIdle =  tonumber(idle) + tonumber(iowait)

				local currNonIdle = tonumber(user) + tonumber(nice) + tonumber(system) + tonumber(irq) + tonumber(softirq)
				
				local currTotal = currIdle + currNonIdle
				
				local delta_total = currTotal - (props.total_last[i] or 0)				
				local delta_idle = currIdle - (props.idle_last[i] or 0)

				
				props.load_percentage[i] = math.floor(100 * 100 * (delta_total - delta_idle) / delta_total) / 100
				props.total_last[i] = currTotal
				props.idle_last[i] = currIdle				
			end
			widget:emit_signal("widget::redraw_needed")    
            
        end)
    end


	-- button / keybindings
    widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() -- left click                        
            widget.update_props()
        end)
    ))

    helpers.newtimer(string.format("cpu_temp-%s-%s", props.cmd, props.path), 10, widget.update_props)

    return widget
end

return factory