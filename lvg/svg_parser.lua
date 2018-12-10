require("lvg.svg")
local svg_parser = {
	scale_factor = 1,
	decimal_precision = 2,
	curve_detail = 5,
	initialize_canvases = true,
	objects = {},
	object_styles = {},
	infos = {},
	path_vars = {
		coords = "",
		sub_coords = {},
		path_x = 0,
		path_y = 0,
		path_x2 = 0,
		path_y2 = 0,
		first_x = 0,
		first_y = 0,
		curr_poly = {}
	}
}

function svg_parser:round (num)
	local mult = 10^(self.decimal_precision)
	return math.floor(num * mult + 0.5) / mult
end

function svg_parser:join_paths (path_1, path_2)
	if self:round(path_1[#path_1 - 1]) == self:round(path_2[1]) and self:round(path_1[#path_1]) == self:round(path_2[2]) then
		table.remove(path_2, 1)
		table.remove(path_2, 1)
	end
	for i = 1, #path_2 do
		path_1[#path_1 + 1] = path_2[i]
	end
	return path_1
end

function svg_parser:remove_double_points (path)
	for i = 1, #path - 2, 4 do
		local x, y = path[i], path[i + 1]
		local x2, y2 = path[i + 2], path[i +3]
		if x and y and x2 and y2 then
			if self:round(x) == self:round(x2) and self:round(y) == self:round(y2) then
				table.remove(path, i)
				table.remove(path, i)
			end
		end
	end
	return path
end

function svg_parser:reset ()
	-- self.scale_factor = 1
	self.canvas = nil
	self.objects = {}
	self.object_styles = {}
	self.infos = {}
end

function svg_parser:reset_path_vars ()
	self.path_vars = {
		coords = "",
		sub_coords = {},
		path_x = 0,
		path_y = 0,
		path_x2 = 0,
		path_y2 = 0,
		first_x = 0,
		first_y = 0,
		curr_poly = {}
	}
end

function svg_parser:iterator_to_table (iterator)
	local table = {}
	if iterator then
		local i = 1
		for value in iterator do
			table[i] = value
			i = i + 1
		end
	end
	return table
end

function svg_parser.split (str, sep)
	if str and sep then
		local sep, fields = sep or ":", {}
		local pattern = string.format("([^%s]+)", sep)
		str:gsub(pattern, function(c) fields[#fields+1] = c end)
		return fields
	end
	return nil
end

--for parsing svg files - obviously
function svg_parser.path_next_number (str)
	--[[
	
	okay, so an explanation of the pattern:
	This gets the a decimal, or non-decimal number, and also includes signs (it searches greedily after the decimal point)
	(%-?%d+%.?%d*)

	this marks the end of the pattern, which means either a comma, a space, or any regular letter except for e,
	since that is used for scientific notation
	 [a-df-zA-DF-Z,]
	]]--
	return tonumber(str:match("(%-?%d+%.?%d*)[ a-df-zA-DF-Z,]"))
end

--just returns the INDEX of the next svg command (a single letter) in the string
function svg_parser.next_svg_command (str)
	return str:find("[MmLlVvHhZzAaSsCcQqTt]")
end

function svg_parser:is_value_list (attr)
	local num = "%d+%.?%d*"
	return attr:find(num .. "%s*,%s*" .. num)
end

function svg_parser:is_number (attr)
	return type(tonumber(attr)) == "number"
end

--currently not taking stroke into account, because that's a whole different beast
function svg_parser:calc_viewbox ()
	local vx, vy, vw, vh
	local max_x = -math.huge
	local max_y = -math.huge
	local min_x = math.huge
	local min_y = math.huge
	for i = 1, #self.objects do
		local object = self.objects[i]
		if self.infos[i].type == "p" then --path
			for j = 1, #object do
				for k = 1, #object[j], 2 do
					max_x = math.max(object[j][k], max_x)
					max_y = math.max(object[j][k + 1], max_y)
					min_x = math.min(object[j][k], min_x)
					min_y = math.min(object[j][k + 1], min_y)
				end
			end
		elseif self.infos[i].type == "c" then --circle
			max_x = math.max(object[1] + object[3], max_x)
			max_y = math.max(object[2] + object[3], max_y)
			min_x = math.min(object[1] - object[3], min_x)
			min_y = math.min(object[2] - object[3], min_y)
		elseif self.infos[i].type == "r" then --rectangle
			max_x = math.max(object[1] + object[3], max_x)
			max_y = math.max(object[2] + object[4], max_y)
			min_x = math.min(object[1] + object[3], min_x)
			min_y = math.min(object[2] + object[4], min_y)
		elseif self.infos[i].type == "e" then --ellipse
			max_x = math.max(object[1] + object[3], max_x)
			max_y = math.max(object[2] + object[4], max_y)
			min_x = math.min(object[1] - object[3], min_x)
			min_y = math.min(object[2] - object[4], min_y)
		end
	end
	vx = min_x
	vy = min_y
	vw = max_x
	vh = max_y
	return vx, vy, vw, vh
end

function svg_parser:is_valid_color (color_string)
	local is_color = false
	color_string = color_string:gsub("^%s*(.*)%s*$", "%1")
	if color_string:find("#") and color_string:find("#") == 1 then
		is_color = true
	elseif color_string:find("rgb(") and color_string:find(")") then
		is_color = true
	elseif color_string == "none" or color_string == "" then
		is_color = true
	end
	return is_color
end

function svg_parser:load_svg (filename)
	local content = love.filesystem.read("string", filename)
	if not content then
		file = assert(io.open(love.filesystem.getSourceBaseDirectory() .. '/' .. filename, "rb"))
		content = file:read("*all")
	end
	local svg = require("lvg.xmlSimple").newParser():ParseXmlText(content)
	local tag = svg:children()
	local vx, vy, vw, vh = 0, 0, 1, 1
	local viewbox = self.split(svg["svg"]["@viewBox"], " ")
	self:traverse_tree(svg)
	
	if viewbox then
		vx, vy, vw, vh = unpack(viewbox)
		vx = tonumber(vx)
		vy = tonumber(vy)
		vw = tonumber(vw)
		vh = tonumber(vh)
	else
		vx, vy, vw, vh = self:calc_viewbox()
	end
	return_svg = Lvg_svg:create(
		self.objects,
		self.object_styles,
		self.infos,
		self.scale_factor,
		{x = vx, y = vy, w = vw, h = vh},
		self.initialize_canvases
	)
	self:reset()
	return return_svg
end

function svg_parser:get_infos(tag)
	--type is the most important attribute in here
	local type = tag:name():sub(1,1):lower()
	--we search for title and desc attributes
	local title = nil
	local desc = nil
	if tag:children() then
		if tag["title"] then
			title = tag["title"]:value()
		end
		if tag["desc"] then
			desc = tag["desc"]:value()
		end
	end
	if tag["@transform"] then
		transform = tag["@transform"]
	end
	return {
		type = type,
		title = title,
		transform = transform,
		desc = desc
	}
end

function svg_parser:traverse_tree (parent_tag)
	local tags = parent_tag:children()
	if tags then
		for i = 1, #tags do
			if tags[i]:children() then
				if self["parse_" .. tags[i]:name()] ~= nil then
					local object = self["parse_" .. tags[i]:name()](self, tags[i])
					local infos = self:get_infos(tags[i])
					local styles = self:get_styles(tags[i])
					self:add_object(tags[i]:name(), object, styles, infos)
				else
					self:traverse_tree(tags[i], self.scale_factor)
				end
			end
		end
	end
	return nil
end

function svg_parser:add_object (name, object, styles, infos)
	--apply transform here
	self.objects[#self.objects + 1] = object
	self.object_styles[#self.object_styles + 1] = styles
	self.infos[#self.infos + 1] = infos
end

function svg_parser:parse_style_value (val_string)
	local value = val_string
	if value == "none" or value == "" then
		value = nil
	elseif self:is_number(val_string) then
		value = tonumber(val_string)
	elseif self:is_value_list(value) then
		value = self.split(value, ",")
	elseif self:is_valid_color(val_string) then
		value = self:parse_color(val_string)
	elseif val_string:find("%d+.?%d*") then
		value = val_string:match("%d+.?%d*")
		value = tonumber(value)
	else
		value = {0, 0, 0, 0}
	end
	return value
end

function svg_parser:post_process_styles (styles)
	--this should also be the place to apply transformations
	if styles.fill_opacity then
		if styles.fill then
			styles.fill[4] = styles.fill_opacity * styles.fill[4]
		end
		styles.fill_opacity = nil
	end
	if styles.stroke_opacity then
		if styles.stroke then
			styles.stroke[4] = styles.stroke_opacity * styles.stroke[4]
		end
		styles.stroke_opacity = nil
	end
	return styles
end

function svg_parser:get_styles (tag)
	if tag["@style"] then
		local styles = {}
		local style_string = tag["@style"] .. ";" --our pattern doesn't work if we don't append a semicolon here
		local attributes = style_string:gmatch("[^;].-:.-[;$]")
		for attr in attributes do
			local name = self.split(attr, ":")[1]:gsub("[;:]", ""):gsub("-", "_")
			local val = self:parse_style_value(self.split(attr, ":")[2]:gsub("[;:]", ""))
			styles[name] = val
		end
		return self:post_process_styles(styles)
	end
	return nil
end

function svg_parser:parse_circle (tag)
	local shape_x = tonumber(tag["@cx"])
	local shape_y = tonumber(tag["@cy"])
	local radius = tonumber(tag["@r"])

	return {
		shape_x,
		shape_y,
		radius
	}
end

function svg_parser:parse_ellipse (tag)
	local x = tonumber(tag["@cx"])
	local y = tonumber(tag["@cy"])
	local rx = tonumber(tag["@rx"])
	local ry = tonumber(tag["@ry"])

	return {
		x,
		y,
		rx,
		ry
	}
end

function svg_parser:parse_rect (tag)
	local x = tonumber(tag["@x"])
	local y = tonumber(tag["@y"])
	local w = tonumber(tag["@width"])
	local h = tonumber(tag["@height"])

	return {
		x,
		y,
		w,
		h
	}
end

function svg_parser:parse_path_m (path, char)
	self.path_vars.path_x2 = self.path_next_number(self.path_vars.coords)
	self.path_vars.coords = path:sub(path:find(self.path_vars.path_x2) + #tostring(self.path_vars.path_x2), self.next_svg_command(path))
	if char == "m" and i > 1 then
		self.path_vars.path_x = self.path_vars.path_x + self.path_vars.path_x2
		i = i + 1
	else
		self.path_vars.path_x = self.path_vars.path_x2
	end

	self.path_vars.path_y2 = self.path_next_number(self.path_vars.coords)
	self.path_vars.coords = path:sub(path:find(self.path_vars.path_y2) + #tostring(self.path_vars.path_y2), self.next_svg_command(path))
	if char == "m" then
		self.path_vars.path_y = self.path_vars.path_y + self.path_vars.path_y2
		i = i + 1
	else
		self.path_vars.path_y = self.path_vars.path_y2
	end

	if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
		self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
		self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
	end

	self.path_vars.first_x = self.path_vars.path_x
	self.path_vars.first_y = self.path_vars.path_y
	--here a new subpath begins, anything before the next command is treated as regular straight line_to (L or l)
	if self.path_next_number(self.path_vars.coords) then
		self.path_vars.sub_coords = self.path_vars.coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*")
		for coord in self.path_vars.sub_coords do
			self.path_vars.path_x2 = tonumber(self.split(coord, ",")[1])
			self.path_vars.path_y2 = tonumber(self.split(coord, ",")[2])
			if char == "m" and i > 1 then
				self.path_vars.path_x2 = self.path_vars.path_x + self.path_vars.path_x2
				self.path_vars.path_y2 = self.path_vars.path_y + self.path_vars.path_y2
			end
			if self.path_vars.path_y2 ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or self.path_vars.path_x2 ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
				self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x2
				self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y2
			end
			self.path_vars.path_x = self.path_vars.path_x2
			self.path_vars.path_y = self.path_vars.path_y2
		end
	end
end

function svg_parser:parse_path_v (char)
	self.path_vars.sub_coords = self.path_vars.coords:gmatch("%-?%d+%.?%d*")
	for coord in self.path_vars.sub_coords do
		self.path_vars.path_y2 = tonumber(coord)
		if char == "v" then
			self.path_vars.path_y2 = self.path_vars.path_y + self.path_vars.path_y2
		end
		self.path_vars.path_y = self.path_vars.path_y2
		if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
		end
	end
end

function svg_parser:parse_path_h (char)
	self.path_vars.sub_coords = self.path_vars.coords:gmatch("%-?%d+%.?%d*")
	for coord in self.path_vars.sub_coords do
		self.path_vars.path_x2 = tonumber(coord)
		if char == "h" then
			self.path_vars.path_x2 = self.path_vars.path_x + self.path_vars.path_x2
		end
		self.path_vars.path_x = self.path_vars.path_x2
		if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
		end
	end
end

function svg_parser:parse_path_l (char)
	self.path_vars.sub_coords = self.path_vars.coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*")

	for coord in self.path_vars.sub_coords do
		self.path_vars.path_x2 = tonumber(self.split(coord, ",")[1])
		self.path_vars.path_y2 = tonumber(self.split(coord, ",")[2])
		if char == "l" then
			self.path_vars.path_x2 = self.path_vars.path_x + self.path_vars.path_x2
			self.path_vars.path_y2 = self.path_vars.path_y + self.path_vars.path_y2
		end
		if self.path_vars.path_y2 ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or self.path_vars.path_x2 ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x2
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y2
			self.path_vars.path_x = self.path_vars.path_x2
			self.path_vars.path_y = self.path_vars.path_y2
		end
	end
end

function svg_parser:parse_path_c (char)
	self.path_vars.sub_coords = self:iterator_to_table(self.path_vars.coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*"))
	local control_points = {}
	local curve = {}

	--get the control points for the curve
	for i = 1, #self.path_vars.sub_coords do
		self.path_vars.path_x2 = tonumber(self.split(self.path_vars.sub_coords[i], ",")[1])
		self.path_vars.path_y2 = tonumber(self.split(self.path_vars.sub_coords[i], ",")[2])

		if char == "c" then
			self.path_vars.path_x2 = self.path_vars.path_x + self.path_vars.path_x2
			self.path_vars.path_y2 = self.path_vars.path_y + self.path_vars.path_y2
		end
		control_points[#control_points + 1] = self.path_vars.path_x2
		control_points[#control_points + 1] = self.path_vars.path_y2
		if #control_points == 6 then
			curve = love.math.newBezierCurve(self.path_vars.path_x, self.path_vars.path_y, unpack(control_points)):render(self.curve_detail)
			curve = self:remove_double_points(curve)
			-- oh wtf am I doing
			-- curve[#curve] = nil
			-- curve[#curve] = nil
			self.path_vars.curr_poly = self:join_paths(self.path_vars.curr_poly, curve)
			self.path_vars.path_x = self.path_vars.path_x2
			self.path_vars.path_y = self.path_vars.path_y2
			control_points = {}
		end
		self.path_vars.path_x = self.path_vars.curr_poly[#self.path_vars.curr_poly - 1]
		self.path_vars.path_y = self.path_vars.curr_poly[#self.path_vars.curr_poly]
	end
end

function svg_parser:parse_path_z ()
	local return_path = nil
	self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.first_x
	self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.first_y
	self.path_vars.curr_poly = self:remove_double_points(self.path_vars.curr_poly)
	return_path = self.path_vars.curr_poly
	self.path_vars.curr_poly = {}
	self.path_vars.path_x = self.path_vars.first_x
	self.path_vars.path_y = self.path_vars.first_y
	if #return_path > 3 then
		return return_path
	end
end

function svg_parser:parse_path (tag)
	self:reset_path_vars()
	local char = ""
	local return_paths = {}
	--if there's no type then we just make it an edge shape
	local path = tag["@d"]
	if path then
		self.path_vars.coords = path
		i = self.next_svg_command(path)
		while i do
			char = path:sub(i, i)
			path = path:sub(i + 1)
			self.path_vars.coords = path:sub(0, self.next_svg_command(path))
			self.path_vars.coords = self.path_vars.coords:gsub("% *[MmLlVvHhZz]", "")
			if char == "M" or char == "m" then
				if #self.path_vars.curr_poly > 4 then
					return_paths[#return_paths + 1] = self.path_vars.curr_poly
					self.path_vars.curr_poly = {}
				end
				self:parse_path_m(path, char)
			elseif char == "v" or char == "V" then
				self:parse_path_v(char)
			elseif char == "h" or char == "H" then
				self:parse_path_h(char)
			elseif char == "l" or char == "L" then
				self:parse_path_l(char)
			elseif char == "c" or char == "C" then
				self:parse_path_c(char)
			elseif char == "s" or char == "S" then
			elseif char == "q" or char == "Q" then
			elseif char == "a" or char == "A" then
			elseif char == "t" or char == "T" then
			elseif char == "z" or char == "Z" then
				return_paths[#return_paths + 1] = self:parse_path_z()
			end
			i = self.next_svg_command(path)
		end
	end
	if #self.path_vars.curr_poly > 3 then
		return_paths[#return_paths + 1] = self.path_vars.curr_poly
	end
	return return_paths
end

function svg_parser:apply_transforms (paths, transforms)
	for i = 0, #paths do
		for j = 1, #paths[i] do
			
		end
	end
end


function svg_parser.rgb_to_color (rgb_string)
	if rgb_string and rgb_string:find("rgb%(") then
		rgb = rgb_string:gmatch("rgb%((%d-)[,)%)]")
		local color = {}
		for val in rgb do
			color[#color + 1] = tonumber(val) / 255
		end
		return color
	end
	return {0, 0, 0, 0}
end

function svg_parser.hex_to_color (hex_string)
	if hex_string then
		hex_string = hex_string:gsub("#", "")
		local color = {}
		local step_size = math.floor(#hex_string / 3)
		for i = 1, #hex_string, step_size do
			local hex_part = hex_string:sub(i, i + step_size - 1)
			color[#color + 1] = tonumber(hex_part, 16) / 255
		end
		return color
	end
	return {0, 0, 0, 0}
end

function svg_parser:parse_color (color_string)
	local color = {0, 0, 0, 0}
	if color_string:find("#") then
		color = self.hex_to_color(color_string)
	else
		color = self.rgb_to_color(color_string)
	end
	if color and #color < 4 then
		color[#color + 1] = 1
	end
	return color
end

return svg_parser
