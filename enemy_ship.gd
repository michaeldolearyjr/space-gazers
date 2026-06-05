extends Area2D

var hp: int = 45
var speedx: float = 0
var speedy: float = 0
var bullet_timer: float = 0.0
var anim_timer: float = 0.0
var hit_timer: float = 0.0

func _ready() -> void:
	scale = Vector2(3.5, 3.5)
	collision_layer = 2
	collision_mask = 17
	body_entered.connect(_on_body_entered)
	
	if has_node("Sprite2D"):
		$Sprite2D.hframes = 1
		$Sprite2D.vframes = 1
		var tex = $Sprite2D.texture
		if tex:
			var frame_width = tex.get_width()
			var sprite_scale = 32.0 / frame_width
			$Sprite2D.scale = Vector2(sprite_scale, sprite_scale)
	
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 16.0
		$CollisionShape2D.shape = circle

	speedx = randf_range(-6.0, 6.0) * 10.0
	speedy = randf_range(1.0, 5.0) * 10.0
	bullet_timer = randf_range(0.5, 2.0)
	
	# Removed AnimationPlayer default play so custom animation logic works

func _process(delta: float) -> void:
	if hit_timer > 0:
		hit_timer -= delta
		if hit_timer <= 0 and has_node("Sprite2D"):
			$Sprite2D.modulate = Color.WHITE

	if has_node("Sprite2D"):
		$Sprite2D.rotation += 3.0 * delta # Continually rotate
		
			
	global_position.x += speedx * delta
	global_position.y += speedy * delta
	
	var viewport_rect = get_viewport_rect()
	if global_position.x < 0 or global_position.x > viewport_rect.size.x:
		speedx = -speedx
		
	if global_position.y > viewport_rect.size.y + 100:
		if get_node_or_null("/root/Global"):
			get_node("/root/Global").add_score(-int(speedy * 200))
		queue_free()

	queue_redraw()
	_handle_shooting(delta)

func _handle_shooting(delta: float):
	bullet_timer -= delta
	if bullet_timer <= 0:
		shoot()
		bullet_timer = randf_range(1.5, 3.5)

func shoot():
	if get_parent().get_parent().has_method("spawn_enemy_laser"):
		get_parent().get_parent().spawn_enemy_laser(global_position)

func take_damage(amount: int):
	hp -= amount
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(5, 0, 0, 1) # Bright solid red flash
		hit_timer = 0.1
		
	if hp <= 0:
		if get_node_or_null("/root/Global"):
			get_node("/root/Global").add_score(500000)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_explosion"):
			gameplay.play_explosion(global_position, Color.BLUE)
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(20)
		take_damage(1000)

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(1, 0, 0, 0.5))
