local awful = require("awful")

A = {}

function A.autostart()
    -- monitor rendering
    awful.spawn("xrandr --output DP-0 --primary --mode 2560x1440 --rate 60 --output HDMI-0 --mode 1920x1080 --rate 60 --right-of DP-0")
    -- transition / animation
    awful.spawn.with_shell("compton")

    -- spotify
    awful.spawn("spotify")
    -- awful.spawn("cvlc ~/Projects/KRK_stayawake/10hz_tone.wav --repeat")
end

return A