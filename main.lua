function love.load ()
	love.graphics.setBackgroundColor(1,1,1,1)
	svg_parser = require("lvg.svg_parser") --you only need one of these
	shapes_svg = svg_parser:load_svg("assets/test.svg")
	bananicorn_svg = svg_parser:load_svg("assets/Ghostbusters.svg")
	initial_window_height = 600
end

function love.draw ()
	local new_scale_factor = love.graphics.getHeight() / initial_window_height
	shapes_svg:draw(0, 20 * new_scale_factor)
	bananicorn_svg:draw(150 * new_scale_factor, 20 * new_scale_factor)
end

function love.resize ()
	local new_scale_factor = love.graphics.getHeight() / initial_window_height
	bananicorn_svg:resize(new_scale_factor)
	shapes_svg:resize(new_scale_factor)
end

function love.update (dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end
