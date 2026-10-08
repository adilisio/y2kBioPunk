extends TextureRect

func _ready() -> void:
	var img = Image.new()
	var err = img.load("res://sprites/menu_bg.jpg")
	if err == OK:
		self.texture = ImageTexture.create_from_image(img)
	else:
		print("Failed to load menu_bg.jpg: ", err)
