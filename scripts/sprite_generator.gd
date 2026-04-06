extends Node

# Utility script to generate placeholder sprites
# Run this in Godot editor to create basic test assets

static func generate_player_sprite():
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	# Draw simple character shape
	var body_color = Color(0.2, 0.5, 0.8)  # Blue shirt
	var head_color = Color(1.0, 0.8, 0.6)  # Skin tone

	# Body
	for y in range(16, 30):
		for x in range(8, 24):
			image.set_pixel(x, y, body_color)

	# Head
	for y in range(4, 16):
		for x in range(10, 22):
			image.set_pixel(x, y, head_color)

	# Eyes
	image.set_pixel(13, 10, Color.BLACK)
	image.set_pixel(19, 10, Color.BLACK)

	return ImageTexture.create_from_image(image)

static func generate_crop_sprites():
	var sprites = {}

	# Parsnip growth stages
	sprites["parsnip"] = []
	for stage in range(5):
		var size = 8 + stage * 4
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)

		# Green plant that grows
		var green = Color(0.2 + stage * 0.1, 0.6 + stage * 0.05, 0.2)
		for y in range(32 - size, 32):
			for x in range(16 - size/2, 16 + size/2):
				if x >= 0 and x < 32:
					image.set_pixel(x, y, green)

		sprites["parsnip"].append(ImageTexture.create_from_image(image))

	return sprites

static func generate_tileset():
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	# Grass tile (0,0)
	var grass = Color(0.3, 0.7, 0.3)
	fill_rect(image, 0, 0, 32, 32, grass)
	add_grass_details(image, 0, 0)

	# Dirt tile (32,0)
	var dirt = Color(0.6, 0.4, 0.2)
	fill_rect(image, 32, 0, 32, 32, dirt)

	# Tilled soil (64,0)
	var soil = Color(0.4, 0.25, 0.15)
	fill_rect(image, 64, 0, 32, 32, soil)
	# Add furrow lines
	for i in range(4, 32, 6):
		draw_line(image, 64, i, 96, i, Color(0.3, 0.2, 0.1), 1)

	# Water tile (96,0)
	var water = Color(0.2, 0.4, 0.8)
	fill_rect(image, 96, 0, 32, 32, water)

	return ImageTexture.create_from_image(image)

static func fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color):
	for cy in range(y, y + h):
		for cx in range(x, x + w):
			image.set_pixel(cx, cy, color)

static func draw_line(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color, thickness: int):
	var steps = max(abs(x2 - x1), abs(y2 - y1))
	for i in range(steps):
		var t = float(i) / steps
		var x = int(x1 + (x2 - x1) * t)
		var y = int(y1 + (y2 - y1) * t)
		for dy in range(-thickness/2, thickness/2 + 1):
			for dx in range(-thickness/2, thickness/2 + 1):
				image.set_pixel(x + dx, y + dy, color)

static func add_grass_details(image: Image, offset_x: int, offset_y: int):
	# Add some grass blade details
	var dark_green = Color(0.2, 0.5, 0.2)
	for i in range(20):
		var x = offset_x + randi() % 32
		var y = offset_y + randi() % 32
		image.set_pixel(x, y, dark_green)
