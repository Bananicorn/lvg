
function render ()
	for i = 1, #test_svg.objects do
		set_style(test_svg.object_styles[i])
		if test_svg.object_types[i] == "p" then --path
			draw_path(test_svg.objects[i])
		elseif test_svg.object_types[i] == "c" then --circle
			draw_circle(test_svg.objects[i])
		elseif test_svg.object_types[i] == "r" then --rectangle
			draw_rect(test_svg.objects[i])
		elseif test_svg.object_types[i] == "e" then --ellipse
			draw_ellipse(test_svg.objects[i])
		end
	end
end

function set_style (style)
	love.graphics.setColor(1, 1, 1, .2)
end

function draw_path (path)
	for i = 1, #path do
		love.graphics.line(path[i])
	end
end

function draw_circle (circle)
	love.graphics.circle("line", unpack(circle))
end

function draw_rect (rect)
	love.graphics.rectangle("line", unpack(rect))
end

function draw_ellipse (ellipse)
	love.graphics.ellipse("line", unpack(ellipse))
end
