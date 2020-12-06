local gears = require("gears")
local awful = require("awful")
local base = require("wibox.widget.base")
local helpers  = require("isitar.helpers")
local cairo = require("lgi").cairo
local wibox = require("wibox")

-- notifier for debug
local naughty = require("naughty")
local function message(text)
	naughty.notify({ preset = naughty.config.presets.critical,
	title = "",
	text = text })
end


local function factory(args)
	local mem_img_widget = base.make_widget()
	local mem_usage_widget = base.make_widget()

    local props = {}

    local args = args or {}
    -- functional args
	props.usage_mem_cmd = args.usage_mem_cmd or "free"
    -- style args
    props.main_color = args.main_color or gears.color("#00ff00")
	props.danger_color = args.danger_color or gears.color("#ff0000")
	props.mem_danger_threshold_perc = args.mem_danger_threshold_perc or 75
    props.font_family = args.font_family or "Courier"

	props.padding = args.padding or 0.1

    -- internal props
	props.mem_usage_byte = 0
	props.mem_total = 1
	props.usage_color = props.main_color

	local function get_usage_color()
		if (100 * props.mem_usage_byte / props.mem_total < props.mem_danger_threshold_perc) then
			return props.main_color
		end
		return props.danger_color

	end

	function mem_img_widget:fit(context, width, height)
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

	function mem_img_widget:draw(context, cr, width, height)
		cr:set_source(props.usage_color)
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

		local chip_width = (width - 2 * padding) /2
		x0 = x0 +  chip_width / 2 -- center chip
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

		local horz_pin_height = dye_height / (10 * num_pins)
		for i=1,num_pins do
			y_offset = y0 + pin_length_vert + i * (dye_height / (num_pins + 1))
			cr:rectangle(x0, y_offset - horz_pin_height / 2, pin_length_horz, horz_pin_height)
			cr:rectangle(x0 + pin_length_horz + dye_width, y_offset - horz_pin_height / 2, pin_length_horz, horz_pin_height)
		end
		cr:fill()
	end


	-- function to get the required space
	function mem_usage_widget:fit(context, width, height)
		return width , height
	end

	function round(num, numDecimalPlaces)
		local mult = 10^(numDecimalPlaces or 0)
		return math.floor(num * mult + 0.5) / mult
	end

    -- called when to draw the widget
	function mem_usage_widget:draw(context, cr, width, height)
		cr:set_source(props.usage_color)
		local padding = math.min(width, height) * props.padding
		-- debug_rects(cr, 0, 0, width, height, padding)
		local x0 = padding
		local y0 = padding

		local font_size = (height - (2 * y0)) / 2
		cr:move_to(x0, (height - (2 * y0)) - font_size / 2 + y0)
        cr:select_font_face(props.font_family, cairo.FontSlant.NORMAL, cairo.FontWeight.NORMAL)
        cr:set_font_size(font_size * 1.3)
		cr:show_text(math.floor(100 * props.mem_usage_byte / props.mem_total) .. "%")
		cr:set_font_size(font_size * 0.6)

		cr:show_text(" " .. round(props.mem_usage_byte /1024 / 1024, 2) .. " / " .. round(props.mem_total / 1024 / 1024, 2) .. " Gb")
	end


    -- refresh props based on real values
    local function update_props()
		helpers.async(props.usage_mem_cmd, function(usage_str)

			for total, used, free, shared, cache, available in string.gmatch(usage_str, "Mem:%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)") do

				props.mem_total = tonumber(total)
				local uesd = props.mem_total - tonumber(available)
				if uesd ~= props.mem_usage_byte then
					props.mem_usage_byte = uesd
					mem_usage_widget:emit_signal("widget::redraw_needed")
				end

				if (get_usage_color() ~= props.usage_color) then
					props.usage_color = get_usage_color()
					mem_img_widget:emit_signal("widget::redraw_needed")
					mem_usage_widget:emit_signal("widget::redraw_needed")
				end
			end
		end)
    end

    helpers.newtimer(string.format("mem_temp-%s", props.cmd), 10, update_props)

	local mem_ret_widget = wibox.widget ({
		mem_img_widget,
		mem_usage_widget,
		layout  = wibox.layout.fixed.horizontal
	})

	-- button / keybindings
    mem_ret_widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() -- left click
         	update_props()
        end)
     ))

    return mem_ret_widget
end

return factory