local gears = require("gears")
local base = require("wibox.widget.base")
    


-- local debugger = require("isitar.debugger")

local function factory(args)
    local polyborder_widget = base.make_widget()

    local props = {}
    local args = args or {}
    props.color = args.color or gears.color('#ff0000')
    props.corner_width = args.corner_width or 15

    function polyborder_widget:fit(context, width, height)		        
        return height, height
    end


    function polyborder_widget:draw(context, cr, width, height)
        cr:set_source(props.color)        

        cr:move_to(0, height / 2)
        cr:line_to(props.corner_width, height)
        cr:line_to(width - props.corner_width, height)
        cr:line_to(width, height / 2)
        cr:line_to(width - props.corner_width, 0)
        cr:line_to(props.corner_width, 0)
        cr:line_to(0, height / 2)        
        cr:stroke()
    end

    return polyborder_widget
end

return factory