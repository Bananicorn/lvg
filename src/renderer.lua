
function render ()
	draw_paths()
end

function draw_paths ()
	love.graphics.setLineWidth(5)
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
