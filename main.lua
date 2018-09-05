require("renderer")
function love.load ()
	svg_parser = require("svg_parser")
	-- test_svg = svg_parser:load_svg("assets/bananicorn.svg")
	test_svg = svg_parser:load_svg("assets/test.svg")
end

function love.draw ()
	render()
end

function love.update (dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end
