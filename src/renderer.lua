
function render ()
	draw_paths()
end

function draw_paths ()
	-- love.graphics.setLineJoin("bevel")
	-- love.graphics.setLineWidth(5)
	love.graphics.setColor(1,1,1,.2)
		-- love.graphics.line(test_svg.paths[1][1][1], test_svg.paths[1][1][2], test_svg.paths[1][1][3], test_svg.paths[1][1][4], test_svg.paths[1][1][5], test_svg.paths[1][1][6], test_svg.paths[1][1][7], test_svg.paths[1][1][8], test_svg.paths[1][1][9], test_svg.paths[1][1][10], test_svg.paths[1][1][11], test_svg.paths[1][1][12], test_svg.paths[1][1][13], test_svg.paths[1][1][14], test_svg.paths[1][1][15], test_svg.paths[1][1][16], test_svg.paths[1][1][17], test_svg.paths[1][1][18], test_svg.paths[1][1][19], test_svg.paths[1][1][20])
		-- love.graphics.line(unpack(test_svg.paths[1][1]))
		-- love.graphics.line(test_svg.paths[1][1][5], test_svg.paths[1][1][6], test_svg.paths[1][1][7], test_svg.paths[1][1][8])
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
