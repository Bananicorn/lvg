
function render ()
	draw_paths()
end

function draw_paths ()
	-- love.graphics.setLineJoin("bevel")
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1,1,1,.2)
	for i = 1, #test_svg.paths do
		for j = 1, #test_svg.paths[i] do
			love.graphics.line(test_svg.paths[i][j])
		end
	end
	for i = 1, #test_svg.circles do
		love.graphics.circle("line", unpack(test_svg.circles[i]))
	end
	for i = 1, #test_svg.rects do
		love.graphics.rectangle("line", unpack(test_svg.rects[i]))
	end
end
