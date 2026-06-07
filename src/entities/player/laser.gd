extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15

func _ready() -> void:
	scale = Vector2(0.5, 0.5)
	collision_layer = 16
	collision_mask = 6
	area_entered.connect(_on_area_entered)
	
	if has_node("Sprite2D"):
		$Sprite2D.hide()
		
	var particles = CPUParticles2D.new()
	particles.amount = 5
	particles.lifetime = 0.1
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 3.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 6.0
	particles.gravity = Vector2(0, 0)
	particles.color = Color.GREEN
	
	var light = PointLight2D.new()
	light.texture = preload("res://assets/images/light.png")
	light.color = Color.GREEN
	light.energy = 1.5
	light.texture_scale = 0.3
	particles.add_child(light)
	
	add_child(particles)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()
	queue_redraw()

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage"):
		if not area.name.begins_with("Asteroid"):
			area.take_damage(damage)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_impact"):
			var tc = Color.WHITE
			if area.name.begins_with("Gazer"): tc = Color.PURPLE
			elif area.name.begins_with("Asteroid"): tc = Color.GRAY
			elif area.name.begins_with("EnemyShip"): tc = Color.BLUE
			gameplay.play_impact(global_position, tc, Color.GREEN)
		queue_free()

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(0, 1, 0, 0.5))
