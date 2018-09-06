Lvg_svg = {}
Lvg_svg.__index = Lvg_svg

function Lvg_svg:create (objects, object_styles, object_types, scale_factor)
	local svg = {
		scale_factor = scale_factor,
		canvas = nil,
		objects = objects,
		object_styles = object_styles,
		object_types = object_types,
		fill_color = nil,
		stroke_color = nil
	}
	setmetatable(svg, Lvg_svg)
	return svg
end

function Lvg_svg:draw (x, y)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.scale(self.scale_factor)
	for i = 1, #self.objects do
		self:set_style(self.object_styles[i])
		if self.object_types[i] == "p" then --path
			self:draw_path(self.objects[i])
		elseif self.object_types[i] == "c" then --circle
			self:draw_circle(self.objects[i])
		elseif self.object_types[i] == "r" then --rectangle
			self:draw_rect(self.objects[i])
		elseif self.object_types[i] == "e" then --ellipse
			self:draw_ellipse(self.objects[i])
		end
	end
	love.graphics.pop()
end

function Lvg_svg:set_style (style)
	love.graphics.setLineWidth(style.stroke_width or 1)

	self.stroke_color = nil
	self.fill_color = nil
	if style.stroke then
		self.stroke_color = style.stroke
	end
	if style.fill then
		self.fill_color = style.fill
	end
end

function Lvg_svg:draw_path (path)
	if self.stroke_color then
		love.graphics.setColor(self.stroke_color)
		for i = 1, #path do
			love.graphics.line(path[i])
		end
	end
end

function Lvg_svg:draw_circle (circle)
	if self.fill_color then
		love.graphics.setColor(self.fill_color)
		love.graphics.circle("fill", unpack(circle))
	end
	if self.stroke_color then
		love.graphics.setColor(self.stroke_color)
		love.graphics.circle("line", unpack(circle))
	end
end

function Lvg_svg:draw_rect (rect)
	if self.fill_color then
		love.graphics.setColor(self.fill_color)
		love.graphics.rectangle("fill", unpack(rect))
	end
	if self.stroke_color then
		love.graphics.setColor(self.stroke_color)
		love.graphics.rectangle("line", unpack(rect))
	end
end

function Lvg_svg:draw_ellipse (ellipse)
	if self.fill_color then
		love.graphics.setColor(self.fill_color)
		love.graphics.ellipse("fill", unpack(ellipse))
	end
	if self.stroke_color then
		love.graphics.setColor(self.stroke_color)
		love.graphics.ellipse("line", unpack(ellipse))
	end
end
