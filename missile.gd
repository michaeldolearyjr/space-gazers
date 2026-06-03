extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 200

func _ready() -> void:
	collision_layer = 16
	collision_mask = 6
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.has_point(global_position):
		queue_free()

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage") and (area.name.begins_with("Gazer") or area.name.begins_with("EnemyShip") or area.name.begins_with("Asteroid")):
		var explosion_radius = 250.0
		if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("Enemies"):
			var enemies = get_parent().get_parent().get_node("Enemies").get_children()
			for enemy in enemies:
				if enemy.has_method("take_damage") and enemy.global_position.distance_to(global_position) < explosion_radius:
					enemy.take_damage(damage)
					
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_impact"):
			var tc = Color.WHITE
			if area.name.begins_with("Gazer"): tc = Color.PURPLE
			elif area.name.begins_with("Asteroid"): tc = Color.GRAY
			elif area.name.begins_with("EnemyShip"): tc = Color.BLUE
			gameplay.play_impact(global_position, tc, Color.WHITE)
		queue_free()
