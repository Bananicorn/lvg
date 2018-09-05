function love.load ()
	svg_parser = require("lvg.svg_parser") --you only need one of these
	test_svg = svg_parser:load_svg("assets/bananicorn.svg")
	-- test_svg = svg_parser:load_svg("assets/test.svg")
end

function love.draw ()
	test_svg:draw(0,100)
end

function love.update (dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end
