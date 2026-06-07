extends Area2D

var max_radius: float = 250.0
var duration: float = 0.5
var ring_color: Color = Color.ORANGE
var clears_bullets: bool = false
var damage_amount: int = 1000

var current_radius: float = 0.0

@onready var collision_shape: CollisionShape2D = null
@onready var shape: CircleShape2D = null

func _ready() -> void:
	collision_layer = 0
	# Mask enemies (2), asteroids (4). If clears_bullets, also mask enemy bullets (8).
	collision_mask = 6 if not clears_bullets else 14
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	collision_shape = CollisionShape2D.new()
	shape = CircleShape2D.new()
	shape.radius = 0.0
	collision_shape.shape = shape
	add_child(collision_shape)
	
	var tween = create_tween()
	tween.tween_property(self, "current_radius", max_radius, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.8).set_delay(duration * 0.2)
	
	tween.finished.connect(queue_free)
	
	var gameplay = get_tree().current_scene
	if gameplay and gameplay.has_method("play_explosion"):
		gameplay.play_explosion(global_position, ring_color)

func _process(delta: float) -> void:
	if shape:
		shape.radius = current_radius
	queue_redraw()

func _draw() -> void:
	if current_radius > 0:
		draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, ring_color, 8.0, true)
		draw_arc(Vector2.ZERO, current_radius - 8.0, 0, TAU, 64, Color.WHITE, 2.0, true)

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage") and not area.name.begins_with("Player"):
		area.take_damage(damage_amount)
	elif clears_bullets and area.collision_layer == 8:
		area.queue_free()

func _on_body_entered(body: Node2D):
	if body.has_method("take_damage") and not body.name.begins_with("Player"):
		body.take_damage(damage_amount)
