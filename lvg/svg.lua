Lvg_svg = {}
Lvg_svg.__index = Lvg_svg

function Lvg_svg:create (objects, object_styles, object_types, scale_factor)
	local svg = {
		scale_factor = scale_factor,
		canvas = nil,
		objects = objects,
		object_styles = object_styles,
		object_types = object_types
	}
	setmetatable(svg, Lvg_svg)
	return svg
end

function Lvg_svg:draw ()
	for i = 1, #self.objects do
		self.set_style(self.object_styles[i])
		if self.object_types[i] == "p" then --path
			self.draw_path(self.objects[i])
		elseif self.object_types[i] == "c" then --circle
			self.draw_circle(self.objects[i])
		elseif self.object_types[i] == "r" then --rectangle
			self.draw_rect(self.objects[i])
		elseif self.object_types[i] == "e" then --ellipse
			self.draw_ellipse(self.objects[i])
		end
	end
end

function Lvg_svg.set_style (style)
	love.graphics.setColor(1, 1, 1, .2)
end

function Lvg_svg.draw_path (path)
	for i = 1, #path do
		love.graphics.line(path[i])
	end
end

function Lvg_svg.draw_circle (circle)
	love.graphics.circle("line", unpack(circle))
end

function Lvg_svg.draw_rect (rect)
	love.graphics.rectangle("line", unpack(rect))
end

function Lvg_svg.draw_ellipse (ellipse)
	love.graphics.ellipse("line", unpack(ellipse))
end
