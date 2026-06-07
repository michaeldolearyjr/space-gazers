extends Area2D

var hp: int = 10000
var state: String = "enter"
var attack_timer: float = 0.0
var orb_timer: float = 0.0
var attack_burst: int = 0
var level: int = 1

func _ready() -> void:
	collision_layer = 2
	collision_mask = 17 # Player(1) + Bullets(16)
	body_entered.connect(_on_body_entered)
	
	# Try to find Global to set level HP scaling
	var global = get_node_or_null("/root/Global")
	if global:
		level = global.level
		hp = 10000 + ((level / 3 - 1) * 5000) # Scales every boss level
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex = preload("res://assets/images/enemy_ship_2.png")
	sprite.texture = tex
	var frame_width = tex.get_width()
	var sprite_scale = 250.0 / frame_width # Make width about 250
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	add_child(sprite)
	
	var shape = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(250.0, 150.0) 
	shape.shape = rect
	add_child(shape)

func _process(delta: float) -> void:
	if state == "die": return
	
	if state == "enter":
		global_position.y += 100 * delta
		if global_position.y >= 200:
			state = "attack"
			attack_timer = 2.0
			orb_timer = 5.0
	
	elif state == "attack":
		attack_timer -= delta
		orb_timer -= delta
		
		# Move side to side slowly
		var t = Time.get_ticks_msec() / 1000.0
		var vp = get_viewport_rect().size
		global_position.x = (vp.x / 2.0) + sin(t) * (vp.x / 3.0)
		
		if orb_timer <= 0:
			orb_timer = randf_range(6.0, 10.0)
			_fire_orb()
		
		if attack_timer <= 0:
			attack_burst += 1
			_fire_lasers()
			if attack_burst >= 5:
				attack_burst = 0
				attack_timer = randf_range(2.0, 4.0)
			else:
				attack_timer = 0.2

	queue_redraw()

func _fire_lasers():
	var gameplay = get_tree().current_scene
	if gameplay and gameplay.has_method("spawn_enemy_laser"):
		# Fire 3 lasers
		for i in range(-1, 2):
			var spawn_pos = global_position + Vector2(i * 40, 50)
			gameplay.spawn_enemy_laser(spawn_pos)

func _fire_orb():
	var gameplay = get_tree().current_scene
	if gameplay and gameplay.has_method("spawn_swirling_orb"):
		gameplay.spawn_swirling_orb(global_position + Vector2(0, 50))

func take_damage(amount: int):
	if state == "die": return
	hp -= amount
	if hp <= 0:
		state = "die"
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", true)
		
		var global = get_node_or_null("/root/Global")
		if global:
			global.add_score(1000000)
			
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_explosion"):
			gameplay.play_explosion(global_position, Color.RED)
			# Do a few more explosions for effect
			for i in range(5):
				var offset = Vector2(randf_range(-80, 80), randf_range(-50, 50))
				gameplay.play_explosion(global_position + offset, Color.ORANGE)
				
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(50)

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.size
			draw_rect(Rect2(-r.x/2, -r.y/2, r.x, r.y), Color(1, 0, 0, 0.5))
