Lvg_svg = {}
Lvg_svg.__index = Lvg_svg

function Lvg_svg:create (objects, object_styles, object_types, scale_factor, viewbox)
	local svg = {
		scale_factor = scale_factor,
		viewbox = viewbox,
		canvas = nil,
		objects = objects,
		object_styles = object_styles,
		object_types = object_types,
		fill_color = nil,
		stroke_color = nil
	}
	setmetatable(svg, Lvg_svg)
	svg:draw_to_canvas()
	return svg
end

function Lvg_svg:draw_to_canvas ()
	local w = (self.viewbox.w - self.viewbox.x) * self.scale_factor
	local h = (self.viewbox.h - self.viewbox.y) * self.scale_factor
	self.canvas = love.graphics.newCanvas(w, h)

	love.graphics.push()
	love.graphics.scale()
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas(self.canvas)
	self:direct_draw(-self.viewbox.x * self.scale_factor, -self.viewbox.y * self.scale_factor)
	love.graphics.pop()
	love.graphics.setCanvas()
end

function Lvg_svg:draw (x, y)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.canvas, x, y)
end

function Lvg_svg:resize (scale_factor)
	self.scale_factor = scale_factor
	self:draw_to_canvas()
end

function Lvg_svg:direct_draw (x, y, crop_to_viewbox)
	local crop_to_viewbox = crop_to_viewbox or false
	love.graphics.push()

	if crop_to_viewbox then
		local w = (self.viewbox.w - self.viewbox.x) * self.scale_factor
		local h = (self.viewbox.h - self.viewbox.y) * self.scale_factor
		love.graphics.setScissor(x, y, w, h)
		love.graphics.translate(x - self.viewbox.x * self.scale_factor, y - self.viewbox.y * self.scale_factor)
	else
		love.graphics.translate(x, y)
	end
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
	if crop_to_viewbox then
		love.graphics.setScissor()
	end
	if use_stencil then
		love.graphics.setStencilTest()
	end

	love.graphics.pop()
end

function Lvg_svg:rasterize (x, y)
	
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
