extends Area2D

var hp: int = 15
var speedx: float = 0
var speedy: float = 0
var bullet_timer: float = 0.0
var score_value: int = 0
var anim_timer: float = 0.0
var state: String = "move"

func _ready() -> void:
	scale = Vector2(2.0, 2.0)
	collision_layer = 2
	collision_mask = 17
	body_entered.connect(_on_body_entered)
	
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 8.0
		$CollisionShape2D.shape = circle
		
	var outer = Area2D.new()
	outer.name = "OuterHitbox"
	outer.collision_layer = 2
	outer.collision_mask = 0
	outer.set_script(preload("res://outer_hitbox.gd"))
	var outer_shape = CollisionShape2D.new()
	var outer_circle = CircleShape2D.new()
	outer_circle.radius = 20.0
	outer_shape.shape = outer_circle
	outer.add_child(outer_shape)
	add_child(outer)

	speedx = randf_range(-6.0, 6.0) * 10.0
	speedy = randf_range(2.0, 16.0) * 10.0
	bullet_timer = randf_range(5.0, 15.0)
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
		$AnimationPlayer.active = false
		
	# Removed AnimationPlayer default play so custom animation logic works

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer > 0.05: # Runs at 20 FPS instead of 10 FPS for smoother animation
		anim_timer = 0.0
		if has_node("Sprite2D"):
			var s = $Sprite2D
			if state == "move":
				if s.frame < 0 or s.frame > 6:
					s.frame = 0
				else:
					if s.frame == 6:
						s.frame = 0
					else:
						s.frame += 1
			elif state == "shoot":
				if s.frame < 7 or s.frame > 13:
					s.frame = 7
				else:
					if s.frame == 13:
						state = "move"
						s.frame = 0
					else:
						s.frame += 1
						if s.frame == 10:
							if get_parent().get_parent().has_method("spawn_gazer_laser"):
								get_parent().get_parent().spawn_gazer_laser(global_position)
			elif state == "die":
				if s.frame < 14 or s.frame > 20:
					s.frame = 14
				else:
					if s.frame == 20:
						queue_free()
					else:
						s.frame += 1
			
	if state != "die":
		global_position.x += speedx * delta
		global_position.y += speedy * delta
		
		# Bounce off sides
		var viewport_rect = get_viewport_rect()
		if global_position.x < 0 or global_position.x > viewport_rect.size.x:
			speedx = -speedx
			
		# Delete if off bottom
		if global_position.y > viewport_rect.size.y + 100:
			var gameplay = get_tree().current_scene
			var player = gameplay.get_node_or_null("Player")
			if player and not player.is_dying:
				if get_node_or_null("/root/Global"):
					get_node("/root/Global").add_score(-int(speedy * 100))
			queue_free()

		_handle_shooting(delta)

	queue_redraw()

func _handle_shooting(delta: float):
	if state == "shoot": return
	bullet_timer -= delta
	if bullet_timer <= 0:
		state = "shoot"
		if has_node("Sprite2D"):
			$Sprite2D.frame = 7
		bullet_timer = randf_range(8.0, 15.0)

func take_damage(amount: int):
	if state == "die": return
	hp -= amount
	if hp <= 0:
		state = "die"
		if has_node("Sprite2D"):
			$Sprite2D.frame = 14
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", true)
			
		if get_node_or_null("/root/Global"):
			get_node("/root/Global").add_score(150000) # Base score
			
		var gameplay = get_tree().current_scene
		if gameplay and gameplay.has_method("play_explosion"):
			gameplay.play_explosion(global_position, Color.PURPLE)

func _on_body_entered(body: Node2D):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(20)
		take_damage(1000)

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(1, 0, 0, 0.5))
		if has_node("OuterHitbox/CollisionShape2D") and $OuterHitbox/CollisionShape2D.shape:
			var r2 = $OuterHitbox/CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r2, Color(1, 1, 0, 0.3))
