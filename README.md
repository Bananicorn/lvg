# lvg - Lovable Vector Graphics (display SVGs in the Löve engine)

Want to use simple SVGs with *curves* in your Löve game?

![showcase](https://github.com/Bananicorn/lvg/blob/master/screenshots/try-7.png "Some shapes and a Bananicorn, ripped right from an unsuspecting SVG")

## Code example:

```lua
	function love.load ()
		love.graphics.setBackgroundColor(1,1,1,1)
		svg_parser = require("lvg.svg_parser") --you only need one of these
		test_svg = svg_parser:load_svg("assets/test.svg")
		bananicorn_svg = svg_parser:load_svg("assets/bananicorn.svg")
	end

	function love.draw ()
		test_svg:draw(0,20)
		bananicorn_svg:draw(150, 20)
	end
```

At this point in time this is *not* a feature-complete SVG renderer.
Not by a long shot - but I've only just begun.

## Currently supported:
###Shapes
- Rectangles (fill & stroke)
- Circles (fill & stroke)
- Ellipses (fill and stroke)
- Paths (stroke only)

###Styles
- basic fill and stroke color
- stroke width
