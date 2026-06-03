extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage") and (area.name == "Gazer" or area.name == "EnemyShip" or area.name == "Asteroid"):
		area.take_damage(damage)
		queue_free()
