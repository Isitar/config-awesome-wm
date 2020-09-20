local awful = require("awful")

A = {}

function A.autostart()
    -- transition / animation
    awful.spawn.with_shell("compton")

    -- spotify
    awful.spawn("spotify")
    -- awful.spawn("cvlc ~/Projects/KRK_stayawake/10hz_tone.wav --repeat")
    -- awful.spawn("gnome-terminal --command=\"cvlc Projects/KRK_stayawake/10hz_tone.wav --repeat\"", {
    --    tag = "music",
    --})
end

return A