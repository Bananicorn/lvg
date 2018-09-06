function love.load ()
	love.graphics.setBackgroundColor(1,1,1,1)
	svg_parser = require("lvg.svg_parser") --you only need one of these
	test_svg = svg_parser:load_svg("assets/test.svg")
	bananicorn_svg = svg_parser:load_svg("assets/bananicorn.svg")
end

function love.draw ()
	test_svg:draw(0,20)
	bananicorn_svg:draw(150, 20)
end

function love.update (dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end
