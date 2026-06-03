extends Area2D

var hp: int = 15
var speedx: float = 0
var speedy: float = 0
var bullet_timer: float = 0.0
var score_value: int = 0

func _ready() -> void:
	speedx = randf_range(-6.0, 6.0) * 10.0
	speedy = randf_range(2.0, 16.0) * 10.0
	bullet_timer = randf_range(0.5, 3.0)
	
	# If AnimationPlayer exists, we can play its default animation here
	if has_node("AnimationPlayer"):
		var anim = $AnimationPlayer
		if anim.has_animation("default"):
			anim.play("default")

func _process(delta: float) -> void:
	global_position.x += speedx * delta
	global_position.y += speedy * delta
	
	# Bounce off sides
	var viewport_rect = get_viewport_rect()
	if global_position.x < 0 or global_position.x > viewport_rect.size.x:
		speedx = -speedx
		
	# Delete if off bottom
	if global_position.y > viewport_rect.size.y + 100:
		if get_node_or_null("/root/Global"):
			# Penalty for letting it pass
			get_node("/root/Global").add_score(-int(speedy))
		queue_free()

	_handle_shooting(delta)

func _handle_shooting(delta: float):
	bullet_timer -= delta
	if bullet_timer <= 0:
		shoot()
		bullet_timer = randf_range(1.0, 5.0)

func shoot():
	if get_parent().get_parent().has_method("spawn_enemy_laser"):
		get_parent().get_parent().spawn_enemy_laser(global_position)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		if get_node_or_null("/root/Global"):
			get_node("/root/Global").add_score(1500) # Base score
		# Spawn particles or explosion here in gameplay.gd
		queue_free()
