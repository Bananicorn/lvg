Lvg_svg = {}
Lvg_svg.__index = Lvg_svg

function Lvg_svg:create (objects, object_styles, infos, scale_factor, viewbox, initialize_canvas)
	local svg = {
		scale_factor = scale_factor,
		viewbox = viewbox,
		canvas = nil,
		quad = love.graphics.newQuad(0, 0, viewbox.w * scale_factor, viewbox.h * scale_factor, viewbox.w * scale_factor, viewbox.h * scale_factor),
		objects = objects,
		styles = object_styles,
		infos = infos,
		fill_color = nil,
		tint_color = {1, 1, 1, 1}, --ONLY applies to drawing the canvas, NOT direct draw
		stroke_color = nil
	}
	setmetatable(svg, Lvg_svg)
	if initialize_canvas then
		svg:draw_to_canvas()
	end
	return svg
end

function Lvg_svg:get_width ()
	return self.viewbox.w * self.scale_factor
end

function Lvg_svg:get_height ()
	return self.viewbox.h * self.scale_factor
end

function Lvg_svg:draw_to_canvas ()
	local w = (self.viewbox.w - self.viewbox.x) * self.scale_factor
	local h = (self.viewbox.h - self.viewbox.y) * self.scale_factor
	if self.canvas ~= nil then
		self.canvas:release()
		self.canvas = nil
	end
	-- self.canvas = love.graphics.newCanvas(w, h, {msaa = 4})
	self.canvas = love.graphics.newCanvas(w, h)

	love.graphics.push()
	love.graphics.setBlendMode("alpha", "alphamultiply")
	love.graphics.setCanvas({self.canvas, stencil=true})
	love.graphics.clear()
	self:direct_draw(-self.viewbox.x * self.scale_factor, -self.viewbox.y * self.scale_factor)
	love.graphics.setCanvas()
	love.graphics.pop()
	love.graphics.setColor(1, 1, 1, 1)
end

function Lvg_svg:do_lines_intersect (x1, y1, x2, y2, x3, y3, x4, y4)
	local denominator = ((x2 - x1) * (y4 - y3)) - ((y2 - y1) * (x4 - x3))
	local numerator1 = ((y1 - y3) * (x4 - x3)) - ((x1 - x3) * (y4 - y3))
	local numerator2 = ((y1 - y3) * (x2 - x1)) - ((x1 - x3) * (y2 - y1))

	-- Detect coincident lines (has a problem, read below)
	-- https://gamedev.stackexchange.com/questions/26004/how-to-detect-2d-line-on-line-collision
	if (denominator == 0) then
		return numerator1 == 0 and numerator2 == 0
	end

	local r = numerator1 / denominator
	local s = numerator2 / denominator

	-- return (r >= 0 and r <= 1) and (s >= 0 and s <= 1)
	return (s >= 0 and s <= 1)
end

function Lvg_svg:does_path_self_intersect (path)
	for i = 1, #path - 4, 2 do
		for j = 1, #path - 4, 2 do
			if i ~= j and self:do_lines_intersect(path[i], path[i + 1], path[i + 2], path[i + 3], path[i + 4],  path[j], path[j + 1], path[j + 2], path[j + 3], path[j + 4]) then
				return true
			end
		end
	end
	return false
end

function Lvg_svg:draw (x, y, rot, offset_x, offset_y)
	local rot = rot or 0
	local offset_x = offset_x or 0
	local offset_y = offset_y or 0
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(self.tint_color)
	if self.canvas ~= nil then
		love.graphics.draw(self.canvas, self.quad, x, y, rot, 1, 1, offset_x, offset_y)
	end
	love.graphics.setBlendMode("alpha")
end

function Lvg_svg:resize (scale_factor)
	self.quad = love.graphics.newQuad(0, 0, self.viewbox.w * scale_factor, self.viewbox.h * scale_factor, self.viewbox.w * scale_factor, self.viewbox.h * scale_factor)
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
	local x, x2, y, y2
	for i = 1, #path / 2, 2 do
		x = path[i]
		x2 = path[#path - (i - 1) - 1]
		y = path[i + 1]
		y2 = path[#path - (i  - 1)]

		path[i] = x2
		path[#path - (i - 1) - 1] = x
		path[i + 1] = y2
		path[#path - (i  - 1)] = y
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
	return result > 0
end

function Lvg_svg:draw_path (path)
	if self.fill_color then
		if self.fill_color[4] > 0 then
			love.graphics.setColor(self.fill_color)
			for i = 1, #path do
				local path_copy = {}
				if self:is_path_ccw(path[i]) then
					for j = 1, #path[i] do
						path_copy[j] = path[i][j]
					end
					path_copy = self:reverse_path_winding(path_copy)
				else
					path_copy = path[i]
				end

				if self:does_path_self_intersect(path_copy) then
					local function poly_stencil ()
						love.graphics.polygon("fill", path_copy)
					end
					love.graphics.stencil(poly_stencil, "invert", 1)
					love.graphics.setStencilTest("greater", 0)
					love.graphics.polygon("fill", path_copy)
					love.graphics.setStencilTest()
				else
					local triangles = love.math.triangulate(path_copy)
					for j = 1, #triangles do
						love.graphics.polygon("fill", triangles[j])
					end
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
