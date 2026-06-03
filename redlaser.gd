extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
