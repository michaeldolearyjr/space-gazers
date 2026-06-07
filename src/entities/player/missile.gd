extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 200
var distance_traveled: float = 0.0
var max_range: float = 0.0

func _ready() -> void:
	collision_layer = 16
	collision_mask = 6
	area_entered.connect(_on_area_entered)
	
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 40.0
		$CollisionShape2D.shape = circle
	
	max_range = get_viewport_rect().size.y / 2.0


func _process(delta: float) -> void:
	var move_step = velocity * delta
	global_position += move_step
	distance_traveled += move_step.length()
	
	if distance_traveled >= max_range:
		explode()
		return
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()
	queue_redraw()

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage") and not area.name.begins_with("Player"):
		explode()

func explode():
	var explosion = load("res://src/effects/expanding_explosion.gd").new()
	explosion.max_radius = 250.0
	explosion.duration = 0.4
	explosion.ring_color = Color.GREEN
	explosion.clears_bullets = false
	explosion.global_position = global_position
	get_parent().call_deferred("add_child", explosion)
	queue_free()

func _draw() -> void:
	# Draw the green ring around the missile
	draw_arc(Vector2.ZERO, 40.0, 0, TAU, 32, Color.GREEN, 2.0, true)
	
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(0, 1, 0, 0.2))
