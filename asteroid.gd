extends Area2D

var hp: int = 200
var speedy: float = 0

var rotation_speed: float = 0

func _ready() -> void:
	speedy = randf_range(2.0, 16.0) * 10.0
	rotation_speed = randf_range(-3.0, 3.0)
	scale = Vector2(0.125, 0.125)
	collision_layer = 4
	collision_mask = 17
	body_entered.connect(_on_body_entered)
	
	var textures = [
		preload("res://assets/images/asteroidsm.png"),
		preload("res://assets/images/asteroidmd.png"),
		preload("res://assets/images/asteroidlg.png"),
		preload("res://assets/images/asteroidlg2.png")
	]
	var tex = textures[randi() % textures.size()]
	if has_node("Sprite2D"):
		$Sprite2D.texture = tex
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = max(tex.get_width(), tex.get_height()) / 2.0
		$CollisionShape2D.shape = circle

func _process(delta: float) -> void:
	global_position.y += speedy * delta
	rotation += rotation_speed * delta
	
	var viewport_rect = get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100:
		queue_free()
	queue_redraw()

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		if get_node_or_null("/root/Global"):
			get_node("/root/Global").add_score(10000)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_explosion"):
			gameplay.play_explosion(global_position, Color.GRAY)
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(100)
		take_damage(1000)

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(1, 0, 0, 0.5))
