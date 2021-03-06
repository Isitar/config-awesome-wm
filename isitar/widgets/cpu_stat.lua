local gears = require("gears")
local awful = require("awful")
local base = require("wibox.widget.base")
local helpers  = require("isitar.helpers")
local cairo = require("lgi").cairo
local wibox = require("wibox")

-- notifier for debug
-- local naughty = require("naughty")

local function factory(args)
	local cpu_img_widget = base.make_widget()
	local cpu_temp_widget = base.make_widget()
	local cpu_core_usage_widget = base.make_widget()

    local props = {}

    local args = args or {}
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

	props.cores_per_col = args.cores_per_col or 5

	props.padding = args.padding or 0.1

    -- internal props
	props.temp_mdeg = 0    
	props.idle_last = {0}
	props.total_last = {0}
	props.load_percentage = {0}	
	props.temp_color = props.main_color

	local function get_temp_color()
		if (props.temp_mdeg / 1000 < props.temp_danger_threshold_deg) then						
			return props.main_color
		end
		return props.danger_color
		
	end

	function cpu_img_widget:fit(context, width, height)
		if (width < height) then
			return width, width
		else 
			return height, height
		end
	end 

	local function debug_rects(cr, x0, y0, width, height, padding)
		cr:rectangle(x0, y0, width, height)
		cr:rectangle(padding, padding, width - 2 * padding, height - 2 * padding)		
		cr:stroke()
	end

	function cpu_img_widget:draw(context, cr, width, height)
		cr:set_source(props.temp_color)
		-- fixed ratio
		if (width < height) then
			heihgt = width
		else 
			width = height
		end

		local padding = math.min(width, height) * props.padding
		--debug_rects(cr, 0, 0, width, height, padding)

		-- draw chip
		local x0 = padding
		local y0 = padding

		local chip_width = width - 2 * padding
		local pin_length_horz = chip_width / 8
		local dye_width = chip_width - 2 * pin_length_horz

		local chip_height = height - 2 * padding
		local pin_length_vert = chip_height / 8
		local dye_height = chip_height - 2 * pin_length_vert

		-- dye
		cr:rectangle(x0 + pin_length_horz, y0 + pin_length_vert, dye_width, dye_height)
		cr:fill()
		-- pins
		local num_pins = 6
		local vert_pin_width = dye_width / (10 * num_pins)

		for i=1,num_pins do
			local x_offset = x0 + pin_length_horz + i * (dye_width / (num_pins + 1))		
			cr:rectangle(x_offset - vert_pin_width / 2, y0, vert_pin_width, pin_length_vert)					
			cr:rectangle(x_offset - vert_pin_width / 2, y0 + pin_length_vert + dye_height, vert_pin_width, pin_length_vert)
		end
		local horz_pin_height = dye_height / (10 * num_pins)
		for i=1,num_pins do
			local y_offset = y0 + pin_length_vert + i * (dye_height / (num_pins + 1))			
			cr:rectangle(x0, y_offset - horz_pin_height / 2, pin_length_horz, horz_pin_height)		
			cr:rectangle(x0 + pin_length_horz + dye_width, y_offset - horz_pin_height / 2, pin_length_horz, horz_pin_height)			
		end
		cr:fill() 
	end


	-- function to get the required space
	function cpu_temp_widget:fit(context, width, height)		
		local padding = math.min(width, height) * props.padding
		local font_size = (height - (2 * padding)) / 2
		return font_size * 3, height		
	end
    -- called when to draw the widget
	function cpu_temp_widget:draw(context, cr, width, height)
		cr:set_source(props.temp_color)
		local padding = math.min(width, height) * props.padding
		-- debug_rects(cr, 0, 0, width, height, padding)
		local x0 = padding
		local y0 = padding

		font_size = (height - (2 * y0)) / 2
		cr:move_to(x0, (height - (2 * y0)) - font_size / 2 + y0)
        cr:select_font_face(props.font_family, cairo.FontSlant.NORMAL, cairo.FontWeight.NORMAL)
        cr:set_font_size(font_size * 1.3)
        cr:show_text(math.floor(props.temp_mdeg / 1000) .. "°")
	end
	
	-- function to get the required space
	function cpu_core_usage_widget:fit(context, width, height)	
		local padding = math.min(width, height) * props.padding
		local cores_per_col = props.cores_per_col
		local col_height = ((height - 2 * padding) / cores_per_col)
		local font_size = col_height / 1.5
		local width_requested = font_size * 6 *(24 / cores_per_col) + 2 * padding
		return width_requested, height		
	end
    -- called when to draw the widget
	function cpu_core_usage_widget:draw(context, cr, width, height)		
		local padding = math.min(width, height) * props.padding
		-- debug_rects(cr, 0, 0, width, height, padding)
		local x0 = padding
		local y0 = padding
		
		local cnt = 0
		local cores_per_col = props.cores_per_col
		local col_height = ((height - 2 * padding) / cores_per_col)
		local font_size = col_height / 1.5
		for i,perc in pairs(props.load_percentage) do
			local x = x0 + ((i - 1) // (cores_per_col)) * (font_size * 6)
			local col = (i - 1) % (cores_per_col)
			local y = y0 + (col + 1) * col_height
		
			if (perc < 75) then
				cr:set_source(props.main_color)
			else
				cr:set_source(props.danger_color)
			end
			
			cr:move_to(x, y)
			cr:set_font_size(font_size)
			cr:show_text(i .. ": " .. perc)		
		end
    end

    -- refresh props based on real values
    local function update_props()        
        helpers.async(string.format("%s %s", props.temp_cmd, props.temp_path), function(temp_str)
            local temp_mdeg = tonumber(temp_str)
            
            if temp_mdeg ~= props.temp_mdeg then
                props.temp_mdeg = temp_mdeg                 
                cpu_temp_widget:emit_signal("widget::redraw_needed")
			end
			
			if (get_temp_color() ~= props.color) then
				props.temp_color = get_temp_color()
				cpu_temp_widget:emit_signal("widget::redraw_needed")
				cpu_img_widget:emit_signal("widget::redraw_needed")
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
			cpu_core_usage_widget:emit_signal("widget::redraw_needed")    
            
        end)
    end

    helpers.newtimer(string.format("cpu_temp-%s-%s", props.cmd, props.path), 10, update_props)

	local cpu_ret_widget = wibox.widget ({
		cpu_img_widget,
		cpu_core_usage_widget,
		cpu_temp_widget,
		layout  = wibox.layout.fixed.horizontal
	})

	-- button / keybindings
    cpu_ret_widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() -- left click                        
        	update_props()
        end)
    ))

    return cpu_ret_widget
end

return factory