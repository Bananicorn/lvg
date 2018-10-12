Lvg_svg = {}
Lvg_svg.__index = Lvg_svg

function Lvg_svg:create (objects, object_styles, infos, scale_factor, viewbox, initialize_canvas)
	local svg = {
		scale_factor = scale_factor,
		viewbox = viewbox,
		canvas = nil,
		quad = love.graphics.newQuad(0, 0, viewbox.w, viewbox.h, viewbox.w, viewbox.h),
		objects = objects,
		styles = object_styles,
		infos = infos,
		fill_color = nil,
		stroke_color = nil
	}
	setmetatable(svg, Lvg_svg)
	if initialize_canvas then
		svg:draw_to_canvas()
	end
	return svg
end

function Lvg_svg:draw_to_canvas ()
	local w = (self.viewbox.w - self.viewbox.x) * self.scale_factor
	local h = (self.viewbox.h - self.viewbox.y) * self.scale_factor
	if self.canvas then
		self.canvas:release()
	end
	self.canvas = love.graphics.newCanvas(w, h, {msaa = 4})

	love.graphics.push()
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas({self.canvas, stencil=true, msaa=4})
	self:direct_draw(-self.viewbox.x * self.scale_factor, -self.viewbox.y * self.scale_factor)
	love.graphics.pop()
	love.graphics.setCanvas()
end

function Lvg_svg:draw (x, y)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.canvas, self.quad, x, y, 0, self.scale_factor, self.scale_factor)
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
		self:set_style(self.styles[i])
		if self.infos[i].type == "p" then --path
			self:draw_path(self.objects[i])
		elseif self.infos[i].type == "c" then --circle
			self:draw_circle(self.objects[i])
		elseif self.infos[i].type == "r" then --rectangle
			self:draw_rect(self.objects[i])
		elseif self.infos[i].type == "e" then --ellipse
			self:draw_ellipse(self.objects[i])
		end
	end
	if crop_to_viewbox then
		love.graphics.setScissor()
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

function Lvg_svg:reverse_path_winding (path)
	for i = 1, #path / 2 do
		local a, b
		a = path[i]
		b = path[#path - (i - 1)]
		path[i] = b
		path[#path - (i - 1)] = a
	end
	return path
end

function Lvg_svg:is_path_ccw (path)
	--if the polygon isn't closed, then we close it for this, because for the fill will HAVE TO close it
	--doesn't work yet if I don't find out where the path actually breaks
	-- if path[1] ~= path[#path - 1] or path[2] ~= path[#path] then
		-- path[#path + 1] = path[1]
		-- path[#path + 1] = path[2]
	-- end
	local result = 0
	for i = 1, #path - 3, 2 do
		local current_edge = (path[i + 2] - path[i]) * (path[i + 3] + path[i + 1])
		result = current_edge + result
	end
	return result < 0
end

function Lvg_svg:draw_path (path)
	if self.fill_color then
		if self.fill_color[4] > 0 then
			love.graphics.setColor(self.fill_color)
			for i = 1, #path do
				if love.math.isConvex(path[i]) then
					if self:is_path_ccw(path[i]) then
						path[i] = self:reverse_path_winding(path[i])
					end
					
					local triangles = love.math.triangulate(path[i])
					for j = 1, #triangles do
						love.graphics.polygon("fill", triangles[j])
					end
				else
					local function poly_stencil ()
						love.graphics.polygon("fill", path[i])
					end
					if 1 then
						love.graphics.stencil(poly_stencil, "replace", 4)
						love.graphics.setStencilTest("greater", 3)
					else
						love.graphics.stencil(poly_stencil, "invert", 1)
						love.graphics.setStencilTest("greater", 0)
					end
					love.graphics.polygon("fill", path[i])
					love.graphics.setStencilTest()
				end
			end
		end
	end
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
