local gears = require("gears")
local base = require("wibox.widget.base")
    


-- local debugger = require("isitar.debugger")

local function factory(args)
    local rombus_widget = base.make_widget()

    local props = {}
    local args = args or {}
    props.color = args.color or gears.color('#ff0000')


    function rombus_widget:fit(context, width, height)		        
        return height, height
    end


    function rombus_widget:draw(context, cr, width, height)
        cr:set_source(props.color)
            
        cr:move_to(0, height / 2)
        cr:line_to(width / 2, height)
        cr:line_to(width, height / 2)
        cr:line_to(width / 2, 0)
        cr:line_to(0, height / 2)
        cr:stroke()
    end

    return rombus_widget
end

return factory