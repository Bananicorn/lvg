function love.load ()
	love.graphics.setBackgroundColor(1,1,1,1)
	svg_parser = require("lvg.svg_parser") --you only need one of these
	shapes_svg = svg_parser:load_svg("assets/test.svg")
	-- bananicorn_svg = svg_parser:load_svg("assets/Ghostbusters.svg")
	bananicorn_svg = svg_parser:load_svg("assets/bananicorn.svg")
	initial_window_height = 600
end

function love.draw ()
	local scale_factor = love.graphics.getHeight() / initial_window_height
	shapes_svg:draw(0, 20 * scale_factor)
	bananicorn_svg:draw(150 * scale_factor, 20 * scale_factor)
	love.graphics.setColor(0,0,0)
	love.graphics.print(love.timer.getFPS(), 10, 10)
end

function love.resize ()
	local scale_factor = love.graphics.getHeight() / initial_window_height
	bananicorn_svg:resize(scale_factor)
	shapes_svg:resize(scale_factor)
end

function love.update (dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end
