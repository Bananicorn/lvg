local svg_parser = {
	scale_factor = 1,
	canvas = nil,
	paths = {},
	path_styles = {},
	circles = {},
	circle_styles = {},
	rects = {},
	rect_styles = {}
}


function svg_parser:reset()
	self.scale_factor = 1
	self.canvas = nil
	self.paths = {}
	self.path_styles = {}
	self.circles = {}
	self.circle_styles = {}
	self.rects = {}
	self.rect_styles = {}
end

function svg_parser:iterator_to_table(iterator)
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
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

--for parsing svg files - obviously
function svg_parser.path_next_number (str)
	return tonumber(str:match("(%-?%d+%.?%d-)[ %D]"))
end

--just returns the INDEX of the next svg command (a single letter) in the string
function svg_parser.next_svg_command (str)
	return str:find("[MmLlVvHhZzAaSsCcQqTt]")
end

function svg_parser:is_valid_color (color_string)
	if
		color_string ~= "none" and
		color_string ~= ""
	then
		return true
	end
	return false
end

function svg_parser:load_svg (file)
	local file = assert(io.open(love.filesystem.getSourceBaseDirectory() .. '/' .. file, "rb"))
	local content = file:read("*all")

	local svg = require("xmlSimple").newParser():ParseXmlText(content)
	local tag = svg:children()
	self:traverse_tree(svg)
	return_svg = {
		scale_factor = self.scale_factor,
		canvas = nil,
		paths = self.paths,
		path_styles = self.path_styles,
		circles = self.circles,
		circle_styles = self.circle_styles,
		rects = self.rects,
		rect_styles = self.rect_styles
	}
	self:reset()
	return return_svg
end

function svg_parser:traverse_tree (parent_tag)
	local tags = parent_tag:children()
	if tags then
		for i = 1, #tags do
			if tags[i]:children() then
				if self["parse_" .. tags[i]:name()] ~= nil then
					local object = self["parse_" .. tags[i]:name()](self, tags[i])
					local styles = self:get_styles(tags[i])
					self:add_object(tags[i]:name(), object, styles)
				else
					self:traverse_tree(tags[i], self.scale_factor)
				end
			end
		end
	end
	return nil
end

function svg_parser:add_object (name, object, styles)
	if name == "path" then
		self.paths[#self.paths + 1] = object
		self.path_styles[#self.path_styles + 1] = styles
	elseif name == "circle" then
		self.circles[#self.circles + 1] = object
		self.circle_styles[#self.circle_styles + 1] = styles
	elseif name == "rect" then
		self.rects[#self.rects + 1] = object
		self.rect_styles[#self.rect_styles + 1] = styles
	end
end

function svg_parser:get_styles (tag)
	if tag["@style"] then
		local styles = {}
		local style_string = tag["@style"]:gsub("-", "_")
		local attributes = style_string:gmatch("[^;].-:.-[;$]")
		for attr in attributes do
			name = self.split(attr, ":")[1]:gsub("[;:]", "")
			val = self.split(attr, ":")[2]:gsub("[;:]", "")
			if val ~= "none" then
				styles[name] = val
			end
		end
		return styles
	end
	return nil
end

function svg_parser:parse_g (tag)
	return {}
end

function svg_parser:parse_circle (tag)
	local shape_x = tonumber(tag["@cx"]) * self.scale_factor
	local shape_y = tonumber(tag["@cy"]) * self.scale_factor
	local radius = tonumber(tag["@r"]) * self.scale_factor
	
	return {
		shape_x,
		shape_y,
		radius
	}
end

function svg_parser:parse_rect (tag)
	local w = tonumber(tag["@width"]) * self.scale_factor
	local h = tonumber(tag["@height"]) * self.scale_factor
	local shape_x = (tonumber(tag["@x"]) * self.scale_factor) + (w / 2)
	local shape_y = (tonumber(tag["@y"]) * self.scale_factor) + (h / 2)
	
	return {
		shape_x,
		shape_y,
		w,
		h
	}
end

function svg_parser:parse_path (tag)
	local char = ""
	local coords = ""
	local sub_coords = {}
	local path_x = 0
	local path_y = 0
	local path_x2 = 0
	local path_y2 = 0
	local first_x = 0
	local first_y = 0
	local curve_detail = 3
	local return_paths = {}
	local current_path = {}
	local obj_type = ""
	local id = tag["@id"]
	local curr_poly = {}
	
	--if there's no type then we just make it an edge shape
	local path = tag["@d"]
	if path then
		local coords = path
		i = self.next_svg_command(path)
		while i do
			char = path:sub(i, i)
			path = path:sub(i + 1)
			coords = path:sub(0, self.next_svg_command(path))
			coords = coords:gsub("% *[MmLlVvHhZz]", "")
			if char == "M" or char == "m" then
				path_x2 = self.path_next_number(coords)
				coords = path:sub(path:find(path_x2) + #tostring(path_x2), self.next_svg_command(path))
				if char == "m" and i > 1 then
					path_x = path_x + (path_x2 * self.scale_factor)
					i = i + 1
				else
					path_x = path_x2 * self.scale_factor
				end
				
				path_y2 = self.path_next_number(coords)
				coords = path:sub(path:find(path_y2) + #tostring(path_y2), self.next_svg_command(path))
				if char == "m" then
					path_y = path_y + (path_y2 * self.scale_factor)
					i = i + 1
				else
					path_y = path_y2 * self.scale_factor
				end
				
				if #curr_poly > 3 then
					return_paths[#return_paths + 1] = curr_poly
					loops = false
					curr_poly = {}
				end
				
				if path_y ~= curr_poly[#curr_poly] or path_x ~= curr_poly[#curr_poly - 1] then
					curr_poly[#curr_poly + 1] = path_x
					curr_poly[#curr_poly + 1] = path_y
				end
				
				first_x = path_x
				first_y = path_y
				--here a new subpath begins, anything before the next command is treated as regular straight line_to (L or l)
				if self.path_next_number(coords) then
					sub_coords = coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*")
					for coord in sub_coords do
						path_x2 = tonumber(self.split(coord, ",")[1]) * self.scale_factor
						path_y2 = tonumber(self.split(coord, ",")[2]) * self.scale_factor
						if char == "m" and i > 1 then
							path_x2 = path_x + path_x2
							path_y2 = path_y + path_y2
						end
						if path_y2 ~= curr_poly[#curr_poly] or path_x2 ~= curr_poly[#curr_poly - 1] then
							curr_poly[#curr_poly + 1] = path_x2
							curr_poly[#curr_poly + 1] = path_y2
						end
						path_x = path_x2
						path_y = path_y2
					end
				end
			elseif char == "v" or char == "V" then
				sub_coords = coords:gmatch("%-?%d+%.?%d*")
				for coord in sub_coords do
					path_y2 = tonumber(coord) * self.scale_factor
					if char == "v" then
						path_y2 = path_y + path_y2
					end
					path_y = path_y2
					if path_y ~= curr_poly[#curr_poly] or path_x ~= curr_poly[#curr_poly - 1] then
						curr_poly[#curr_poly + 1] = path_x
						curr_poly[#curr_poly + 1] = path_y
					end
				end
			elseif char == "h" or char == "H" then
				sub_coords = coords:gmatch("%-?%d+%.?%d*")
				for coord in sub_coords do
					path_x2 = tonumber(coord) * self.scale_factor
					if char == "h" then
						path_x2 = path_x + path_x2
					end
					path_x = path_x2
					if path_y ~= curr_poly[#curr_poly] or path_x ~= curr_poly[#curr_poly - 1] then
						curr_poly[#curr_poly + 1] = path_x
						curr_poly[#curr_poly + 1] = path_y
					end
				end
			elseif char == "l" or char == "L" then
				sub_coords = coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*")
				for coord in sub_coords do
					path_x2 = tonumber(self.split(coord, ",")[1]) * self.scale_factor
					path_y2 = tonumber(self.split(coord, ",")[2]) * self.scale_factor
					if char == "l" then
						path_x2 = path_x + path_x2
						path_y2 = path_y + path_y2
					end
					if path_y2 ~= curr_poly[#curr_poly] or path_x2 ~= curr_poly[#curr_poly - 1] then
						curr_poly[#curr_poly + 1] = path_x2
						curr_poly[#curr_poly + 1] = path_y2
					end
					path_x = path_x2
					path_y = path_y2
				end
			elseif char == "c" or char == "C" then
				sub_coords = self:iterator_to_table(coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*"))
				-- local control_points = {path_x, path_y}
				local control_points = {}
				local curve = {}
				--get the control points for the curve
				for i = 1, #sub_coords do
					path_x2 = tonumber(self.split(sub_coords[i], ",")[1]) * self.scale_factor
					path_y2 = tonumber(self.split(sub_coords[i], ",")[2]) * self.scale_factor
					if char == "c" then
						path_x2 = path_x + path_x2
						path_y2 = path_y + path_y2
					end
					if path_y2 ~= curr_poly[#curr_poly] or path_x2 ~= curr_poly[#curr_poly - 1] then
						control_points[#control_points + 1] = path_x2
						control_points[#control_points + 1] = path_y2
					end
					if #control_points == 8 then
						-- curve = join_tables(curve, control_points)
						-- curve = join_tables(curve, love.math.newBezierCurve(control_points):render(curve_detail))
						control_points = {}
						if i + 1 < #sub_coords then
							path_x = path_x2
							path_y = path_y2
						end
					end
				end
				
				if obj_type ~= "" then
					join_tables(curr_poly, curve)
				else
					for i = 1, #curve, 2 do
						path_x2 = curve[i]
						path_y2 = curve[i + 1]
						if path_y2 ~= curr_poly[#curr_poly] or path_x2 ~= curr_poly[#curr_poly - 1] then
							curr_poly[#curr_poly + 1] = path_x2
							curr_poly[#curr_poly + 1] = path_y2
						end
						path_x = path_x2
						path_y = path_y2
					end
				end
			elseif char == "s" or char == "S" then
				
			elseif char == "q" or char == "Q" then
				sub_coords = coords:gmatch("%-?%d+%.?%d*,%-?%d+%.?%d*")
				for coord in sub_coords do
					path_x2 = tonumber(self.split(coord, ",")[1]) * self.scale_factor
					path_y2 = tonumber(self.split(coord, ",")[2]) * self.scale_factor
					if char == "q" then
						path_x2 = path_x + path_x2
						path_y2 = path_y + path_y2
					end
					curr_poly[#curr_poly + 1] = path_x2
					curr_poly[#curr_poly + 1] = path_y2
					path_x = path_x2
					path_y = path_y2
				end
			elseif char == "a" or char == "A" then
				
			elseif char == "T" or char == "t" then
				
			elseif char == "z" or char == "Z" then
				--actually, whether or not the shape is closed is completely dependent on the z at the end of the path
				curr_poly[#curr_poly + 1] = first_x
				curr_poly[#curr_poly + 1] = first_y
				return_paths[#return_paths + 1] = curr_poly
				curr_poly = {}
				path_x = first_x
				path_y = first_y
			end
			i = self.next_svg_command(path)
		end
	end
	if #curr_poly > 3 then
		return_paths[#return_paths + 1] = curr_poly
	end
	return return_paths
end

function rgb_to_color (rgb_string)
	if rgb_string then
		rgb = rgb_string:gmatch("(%d-)[,)]")
		local color = {}
		for val in rgb do
			color[#color + 1] = tonumber(val) / 255
		end
		return color
	end
	return {0, 0, 0}
end

function hex_to_color (hex_string)
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
	return {0, 0, 0}
end

function parse_color (color_string)
	if color_string:find("#") then
		color = hex_to_color(color_string)
	else
		color = rgb_to_color(color_string)
	end
	if #color < 4 then
		color[#color + 1] = 1
	end
	return color
end


return svg_parser
