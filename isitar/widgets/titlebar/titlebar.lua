

local gears = require("gears")
local awful = require("awful")
local drawable = require("wibox.drawable")
local wibox = require("wibox")
local base = require("wibox.widget.base")
local rombus = require("isitar.widgets.titlebar.rombus")
local line = require("isitar.widgets.titlebar.line")
local polyborder = require("isitar.widgets.titlebar.polyborder")
local models = {}

local debugger = require("isitar.debugger")

local function factory(beautiful)

    -- Double click handler
    local double_click_timer = nil
    local function double_click_event_handler()
        if double_click_timer then
            double_click_timer:stop()
            double_click_timer = nil
            return true
        end
    
        double_click_timer = gears.timer.start_new(0.20, function()
            double_click_timer = nil
            return false
        end)
    end

    local function create_buttons(c)
        local buttons = gears.table.join(
                awful.button({ }, 1, function() -- left click
                    c:emit_signal("request::activate", "isibar", {raise = true})
                    if double_click_event_handler() then
                        c.maximized = not c.maximized
                        c:raise()
                    else
                        awful.mouse.client.move(c)
                    end
                end),
                awful.button({ }, 3, function() -- right click
                    if (c.maximized) then
                        c.maximized = false
                    end
                    c:emit_signal("request::activate", "isibar", {raise = true})
                    awful.mouse.client.resize(c)
                end)
        )
        return buttons
    end

    local function toolbar_content_widget(c)        
        local focused = client.focus == c

        local icon_margin = 5
        local color = gears.color(beautiful.colors.accent_dark)
        if focused then
            color = gears.color(beautiful.colors.accent)            
        end

        local icon_widget = wibox.widget({
            polyborder({color = color}),
            wibox.container.margin(awful.titlebar.widget.iconwidget(c),icon_margin,icon_margin,icon_margin,icon_margin),               
            layout  = wibox.layout.stack
        })

        local middle_widget = wibox.widget(
            {

                line({color = color}),
                {
                    {
                        { -- Title
                            align  = "center",
                            widget = awful.titlebar.widget.titlewidget(c)
                        },                    
                        layout  = wibox.layout.flex.horizontal, 
                    },
                    polyborder({color = color}),
                    layout  = wibox.layout.stack
                },
                line({color = color}),
                layout  = wibox.layout.flex.horizontal, 
        })


        local right_widget = wibox.widget({
            wibox.container.margin(
                wibox.widget({
                    awful.titlebar.widget.minimizebutton(c),
                    awful.titlebar.widget.maximizedbutton(c),
                    awful.titlebar.widget.closebutton    (c),
                    layout = wibox.layout.fixed.horizontal()
                }),
                icon_margin,icon_margin,icon_margin,icon_margin
            ),
            polyborder({color = color}),
            layout  = wibox.layout.stack
        })

        local buttons = create_buttons(c)
        
        return 
        wibox.container.background(
        wibox.container.margin(wibox.widget({
            icon_widget,
            middle_widget,
            right_widget,
            buttons = buttons,            
            layout = wibox.layout.align.horizontal
        }), 1,1,1,1),
            beautiful.bg_normal
        )
    end
    -- Initializes a new model with drawable content etc and saves it in models array
    local function setup_model(c, position)
        if (not models[c]) then
            local titlebar_function = c.titlebar_top
            -- get drawable
            local d = titlebar_function(c, beautiful.titlebar_height) -- size
            local container_drawable = drawable(d, { cleint = c, position = "top"}, "isibar")
            local content_widget = toolbar_content_widget(c)

            container_drawable:_inform_visible(true)
            container_drawable:set_bg("black")
            container_drawable:set_widget(content_widget)

            local model = {
                container_drawable = container_drawable,
                content_widget = content_widget
            }

            models[c] = model

            c:connect_signal("unmanage", function() container_drawable:_inform_visible(false) end)    
            c:connect_signal("focus", function()
                model.content_widget = toolbar_content_widget(c)
                container_drawable:set_widget(model.content_widget)
            end)  
            c:connect_signal("unfocus", function()
                model.content_widget = toolbar_content_widget(c)
                container_drawable:set_widget(model.content_widget)
            end)               
        end
        return models[c]        
    end

    

    -- creates the globally available buttons for the titlebar
    

    

    -- Add a titlebar if titlebars_enabled is set to true in the rules.
    client.connect_signal("request::titlebars", function(c)
            local model = setup_model(c)  
            return model.container_drawable
    end)
end

return factory