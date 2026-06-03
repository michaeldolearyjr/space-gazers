extends CharacterBody2D

const SPEED = 600.0
const FRICTION = 4.0

var health: int = 196
var missiles_ammo: int = 0
var bombs_ammo: int = 0
var rapid_fire_timer: float = 0.0
var bullet_timer: float = 0.0
var hit_timer: float = 0.0

@onready var sprite = $Sprite2D

func _ready() -> void:
	scale = Vector2(3.5, 3.5)
	collision_layer = 1
	collision_mask = 14
	
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 8.0
		$CollisionShape2D.shape = circle
		
	
	var vp = get_viewport_rect().size
	global_position = Vector2(vp.x / 2.0, vp.y / 2.0 + 150.0)
	
	var exhaust = CPUParticles2D.new()
	exhaust.amount = 30
	exhaust.lifetime = 0.5
	exhaust.direction = Vector2(0, 1)
	exhaust.spread = 20.0
	exhaust.gravity = Vector2(0, 0)
	exhaust.initial_velocity_min = 50.0
	exhaust.initial_velocity_max = 100.0
	exhaust.scale_amount_min = 2.0
	exhaust.scale_amount_max = 5.0
	exhaust.color = Color.AQUA
	exhaust.position = Vector2(0, 20)
	exhaust.z_index = -1
	add_child(exhaust)

func _physics_process(delta: float) -> void:
	if hit_timer > 0:
		hit_timer -= delta
	
	if rapid_fire_timer > 0:
		rapid_fire_timer -= delta

	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	# WASD support in Godot by default is mapped to ui_left/right/up/down 
	# but usually users also map W A S D manually. Let's assume ui_ actions are mapped.
	if Input.is_physical_key_pressed(KEY_W): input_vector.y = -1
	elif Input.is_physical_key_pressed(KEY_S): input_vector.y = 1
	if Input.is_physical_key_pressed(KEY_A): input_vector.x = -1
	elif Input.is_physical_key_pressed(KEY_D): input_vector.x = 1

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * SPEED, SPEED * delta * 5.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * FRICTION)

	# Update sprite based on movement (frame mapping from pygame)
	if sprite:
		if velocity.x > 100:
			sprite.frame_coords.y = 1
		elif velocity.x < -100:
			sprite.frame_coords.y = 2
		else:
			sprite.frame_coords.y = 0
			
		if hit_timer > 0:
			sprite.frame_coords.y = 3
			
		sprite.frame_coords.x = (int(Time.get_ticks_msec() / 100) % 3)

	move_and_slide()

	# Keep within screen bounds
	var viewport_rect = get_viewport_rect()
	global_position.x = clamp(global_position.x, 0, viewport_rect.size.x)
	global_position.y = clamp(global_position.y, 0, viewport_rect.size.y)

	queue_redraw()
	_handle_shooting(delta)

func _handle_shooting(delta: float):
	if bullet_timer > 0:
		bullet_timer -= delta

	if bullet_timer <= 0:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			shoot_laser()
			bullet_timer = 0.3 if rapid_fire_timer <= 0 else 0.15
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not Input.is_key_pressed(KEY_SHIFT):
			if missiles_ammo > 0:
				shoot_missile()
				missiles_ammo -= 1
				bullet_timer = 0.3
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and Input.is_key_pressed(KEY_SHIFT):
			if bombs_ammo > 0:
				shoot_bomb()
				bombs_ammo -= 1
				bullet_timer = 0.5

func shoot_laser():
	if get_parent().has_method("spawn_player_laser"):
		get_parent().spawn_player_laser(global_position, get_global_mouse_position())

func shoot_missile():
	if get_parent().has_method("spawn_player_missile"):
		get_parent().spawn_player_missile(global_position, get_global_mouse_position())

func shoot_bomb():
	if get_parent().has_method("trigger_bomb"):
		get_parent().trigger_bomb(global_position)

func _draw() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.debug_hitboxes:
		if has_node("CollisionShape2D") and $CollisionShape2D.shape:
			var r = $CollisionShape2D.shape.radius
			draw_circle(Vector2.ZERO, r, Color(0, 1, 0, 0.5))

func take_damage(amount: int):
	health -= amount
	hit_timer = 0.5
	if health <= 0:
		call_deferred("_die")

func _die():
	get_tree().change_scene_to_file("res://game_over.tscn")
