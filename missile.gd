extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 200

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage") and (area.name == "Gazer" or area.name == "EnemyShip" or area.name == "Asteroid"):
		# AoE explosion in old game for missiles
		var explosion_radius = 250.0
		if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("Enemies"):
			var enemies = get_parent().get_parent().get_node("Enemies").get_children()
			for enemy in enemies:
				if enemy.has_method("take_damage") and enemy.global_position.distance_to(global_position) < explosion_radius:
					enemy.take_damage(damage)
		queue_free()
