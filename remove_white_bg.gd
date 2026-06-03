@tool
extends EditorScript

func _run() -> void:
	print("Starting white background removal...")
	var dir = DirAccess.open("res://assets/images")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var path = "res://assets/images/" + file_name
				var img = Image.load_from_file(path)
				if img:
					var modified = false
					for y in range(img.get_height()):
						for x in range(img.get_width()):
							var c = img.get_pixel(x, y)
							# Check if pixel is white (or very close to white)
							if c.r > 0.95 and c.g > 0.95 and c.b > 0.95 and c.a > 0.0:
								c.a = 0.0
								img.set_pixel(x, y, c)
								modified = true
					if modified:
						img.save_png(path)
						print("Processed: " + file_name)
			file_name = dir.get_next()
		print("Finished removing white backgrounds!")
	else:
		print("Failed to open res://assets/images directory.")
