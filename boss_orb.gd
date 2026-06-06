extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 30
var emit_timer: float = 0.0
var angle: float = 0.0
var rotate_speed: float = 5.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 # Player
	body_entered.connect(_on_body_entered)
	
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	var shape = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = circle
	add_child(shape)
	
	var particles = CPUParticles2D.new()
	particles.amount = 50
	particles.lifetime = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.gravity = Vector2(0, 0)
	var grad = Gradient.new()
	grad.add_point(0.0, Color.MAGENTA)
	grad.add_point(1.0, Color.PURPLE)
	particles.color_initial_ramp = grad
	
	var light = PointLight2D.new()
	light.texture = preload("res://assets/images/light.png")
	light.color = Color.MAGENTA
	light.energy = 2.0
	light.texture_scale = 1.0
	particles.add_child(light)
	add_child(particles)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	angle += rotate_speed * delta
	emit_timer -= delta
	if emit_timer <= 0:
		emit_timer = 0.1 # shoot 10 small bullets a second
		_fire_bullet()
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()
	queue_redraw()

func _fire_bullet():
	var gameplay = get_tree().current_scene
	if gameplay and gameplay.has_node("EnemyBullets") and gameplay.get("red_laser_template"):
		var laser = gameplay.red_laser_template.duplicate()
		laser.show()
		laser.global_position = global_position
		laser.laser_color = Color.MAGENTA
		if laser.has_node("Sprite2D"):
			laser.get_node("Sprite2D").modulate = Color.MAGENTA
		var dir = Vector2(cos(angle), sin(angle))
		laser.velocity = dir * 250.0
		gameplay.get_node("EnemyBullets").add_child(laser)

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(damage)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_impact"):
			gameplay.play_impact(global_position, Color.WHITE, Color.MAGENTA)
		queue_free()

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(1, 0, 1, 0.5))
