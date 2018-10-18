# lvg - Lovable Vector Graphics (display SVGs in the Löve engine)

Want to use simple SVGs with *curves* in your Löve game?

Try it with `love ./` while in the project folder and you should see this:

![showcase](https://github.com/Bananicorn/lvg/blob/master/screenshots/try-9.png "Some shapes and a Bananicorn, ripped right from an unsuspecting SVG")

## Code example:

```lua
function love.load ()
	love.graphics.setBackgroundColor(1,1,1,1)
	svg_parser = require("lvg.svg_parser") --you only need one of these
	shapes_svg = svg_parser:load_svg("assets/test.svg")
	bananicorn_svg = svg_parser:load_svg("assets/bananicorn.svg")
	initial_window_height = 600
end

--we're just getting the scale factor here to also adjust the positions, so our SVGs don't overlap
function love.draw ()
	local new_scale_factor = love.graphics.getHeight() / initial_window_height
	shapes_svg:draw(0, 20 * new_scale_factor)
	bananicorn_svg:draw(150 * new_scale_factor, 20 * new_scale_factor)
end

function love.resize ()
	--only taking into account the height of the window, but do whatever you want
	local new_scale_factor = love.graphics.getHeight() / initial_window_height
	bananicorn_svg:resize(new_scale_factor)
	shapes_svg:resize(new_scale_factor)
end
```
## Note:
currently, every path is drawn with the even-odd fill rule, but I'm working on implementing nonzero-winding as well

At this point in time this is *not* a feature-complete SVG renderer.
Not by a long shot - but I've only just begun.

## Currently supported:
### Shapes
- Rectangles (fill & stroke)
- Circles (fill & stroke)
- Ellipses (fill and stroke)
- Paths (stroke and even-odd fill-rule)

### Styles (*only inline*)
- basic fill and stroke color
- stroke width
