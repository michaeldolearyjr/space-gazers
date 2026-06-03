extends Area2D

var hp: int = 200
var speedy: float = 0

func _ready() -> void:
	speedy = randf_range(2.0, 16.0) * 10.0

func _process(delta: float) -> void:
	global_position.y += speedy * delta
	
	var viewport_rect = get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100:
		queue_free()

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		if get_node_or_null("/root/Global"):
			get_node("/root/Global").add_score(100)
		queue_free()
