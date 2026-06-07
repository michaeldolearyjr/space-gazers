extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15
var laser_color: Color = Color.RED

func _ready() -> void:
	collision_layer = 8
	collision_mask = 7 # 1 (Player) + 2 (Enemies) + 4 (Asteroids)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 4.0
		$CollisionShape2D.shape = circle
		
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
	particles.color = laser_color
	
	var light = PointLight2D.new()
	light.texture = preload("res://assets/images/light.png")
	light.color = laser_color
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

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(10)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_impact"):
			gameplay.play_impact(global_position, Color.WHITE, Color.RED)
		queue_free()

func _on_area_entered(area: Area2D):
	if area.name.begins_with("Gazer") or area.name == "OuterHitbox" or area.name.begins_with("Asteroid"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_impact"):
			gameplay.play_impact(global_position, Color.WHITE, Color.RED)
		queue_free()

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(1, 0, 0, 0.5))
