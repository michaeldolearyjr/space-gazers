extends Area2D

var type: String = "health"
var speedy: float = 0

func _ready() -> void:
	speedy = randf_range(5.0, 12.0) * 10.0
	body_entered.connect(_on_body_entered)
	collision_layer = 32
	collision_mask = 1
	
	# Type is now explicitly set by gameplay.gd before adding to the tree
		
	if has_node("Sprite2D"):
		if type == "health":
			$Sprite2D.texture = preload("res://assets/images/healthpack.png")
			$Sprite2D.modulate = Color.WHITE
			scale = Vector2(1.5, 1.5)
		else:
			$Sprite2D.hide()
			scale = Vector2(2.0, 2.0)
			
			var bg = ColorRect.new()
			bg.color = Color.ORANGE
			bg.size = Vector2(16, 20)
			bg.position = Vector2(-8, -10)
			add_child(bg)
			
			var lbl = Label.new()
			if type == "rapid":
				lbl.text = "R"
			elif type == "missile":
				lbl.text = "M"
			elif type == "bomb":
				lbl.text = "B"
				
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color.BLACK)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.size = bg.size
			lbl.position = bg.position
			add_child(lbl)
			
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 16.0
		$CollisionShape2D.shape = circle

func _process(delta: float) -> void:
	global_position.y += speedy * delta
	
	var viewport_rect = get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		if type == "health":
			if body.has_method("heal"):
				body.heal(65)
			else:
				body.health = min(body.health + 65, 196)
		elif type == "rapid":
			body.rapid_fire_ammo += 50
		elif type == "missile":
			body.missiles_ammo += 3
		elif type == "bomb":
			body.bombs_ammo += 1
			
		var global = get_node_or_null("/root/Global")
		if global:
			global.add_score(25000)
			
		queue_free()
