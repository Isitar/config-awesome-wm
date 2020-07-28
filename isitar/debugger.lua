local naughty = require("naughty")

local debugger = {}

function debugger.message(text)
	naughty.notify({ preset = naughty.config.presets.critical,
	title = "",
	text = text })
end

return debugger