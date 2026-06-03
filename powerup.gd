extends Area2D

var type: String = "health"
var speedy: float = 0

func _ready() -> void:
	speedy = randf_range(5.0, 12.0) * 10.0
	body_entered.connect(_on_body_entered)
	
	# Randomize type if not set externally
	if type == "health":
		var types = ["health", "rapid", "missile", "bomb"]
		type = types[randi() % types.size()]

func _process(delta: float) -> void:
	global_position.y += speedy * delta
	
	var viewport_rect = get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		if type == "health":
			body.health = min(body.health + 20, 196) # Adjust heal amount as needed
		elif type == "rapid":
			body.rapid_fire_timer = 10.0 # 10 seconds of rapid fire
		elif type == "missile":
			body.missiles_ammo += 3
		elif type == "bomb":
			body.bombs_ammo += 1
		queue_free()
