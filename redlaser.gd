extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(10)
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_impact"):
			gameplay.play_impact(global_position, Color.WHITE, Color.RED)
		queue_free()
