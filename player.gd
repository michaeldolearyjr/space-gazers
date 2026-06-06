extends CharacterBody2D

const SPEED = 600.0
const FRICTION = 4.0

var health: int = 196
var missiles_ammo: int = 0
var bombs_ammo: int = 0
var rapid_fire_ammo: int = 0
var bullet_timer: float = 0.0
var hit_timer: float = 0.0
var is_dying: bool = false

@onready var sprite = $Sprite2D

func _ready() -> void:
	scale = Vector2(3.5, 3.5)
	collision_layer = 1
	collision_mask = 14
	
	if has_node("Sprite2D"):
		var tex = $Sprite2D.texture
		if tex:
			var frame_width = tex.get_width() / float($Sprite2D.hframes)
			# Scale the Sprite2D down so it visually matches the original 16px width
			var sprite_scale = 16.0 / frame_width
			$Sprite2D.scale = Vector2(sprite_scale, sprite_scale)
	
	if has_node("CollisionShape2D"):
		var circle = CircleShape2D.new()
		circle.radius = 8.0
		$CollisionShape2D.shape = circle
		
	
	var vp = get_viewport_rect().size
	global_position = Vector2(vp.x / 2.0, vp.y / 2.0 + 150.0)
	
	var exhaust = CPUParticles2D.new()
	exhaust.amount = 10
	exhaust.lifetime = 0.4
	exhaust.lifetime_randomness = 0.5
	exhaust.randomness = 1.0 # Random emission intervals
	exhaust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	exhaust.emission_rect_extents = Vector2(6, 2)
	exhaust.direction = Vector2(0, 1)
	exhaust.spread = 15.0
	exhaust.gravity = Vector2(0, 0)
	exhaust.initial_velocity_min = 60.0
	exhaust.initial_velocity_max = 120.0
	exhaust.scale_amount_min = 2.0
	exhaust.scale_amount_max = 5.0
	
	var init_grad = Gradient.new()
	init_grad.set_color(0, Color.RED)
	init_grad.set_color(1, Color.ORANGE)
	exhaust.color_initial_ramp = init_grad
	
	exhaust.position = Vector2(0, 6)
	exhaust.z_index = -1
	add_child(exhaust)

func _physics_process(delta: float) -> void:
	if is_dying: return
	
	if hit_timer > 0:
		hit_timer -= delta

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
			if Input.is_key_pressed(KEY_SHIFT) and rapid_fire_ammo > 0:
				shoot_laser()
				rapid_fire_ammo -= 1
				bullet_timer = 0.1
			else:
				shoot_laser()
				bullet_timer = 0.3
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
	if is_dying: return
	health -= amount
	hit_timer = 0.5
	if health <= 0:
		is_dying = true
		call_deferred("_die")

func heal(amount: int):
	if is_dying: return
	health += amount
	if health > 196:
		health = 196
		
func _die():
	if has_node("Sprite2D"):
		$Sprite2D.hide()
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	if get_parent().has_method("play_explosion"):
		get_parent().play_explosion(global_position, Color.WHITE)
		get_parent().play_explosion(global_position, Color.AQUA) # Vaporize effect
		
	Engine.time_scale = 0.1
	
	var gameplay = get_parent()
	if gameplay and gameplay.has_node("UI/FadeOverlay"):
		var fade = gameplay.get_node("UI/FadeOverlay")
		
		# Wait 8 seconds in slow motion before starting the fade
		await get_tree().create_timer(8.0, true, false, true).timeout
		
		fade.show()
		var tween = create_tween()
		# Scale speed up so it animates in real time despite slow mo
		tween.set_speed_scale(1.0 / 0.1)
		fade.color = Color(0, 0, 0, 0)
		tween.tween_property(fade, "color", Color(0, 0, 0, 1), 5.0)
		
		await get_tree().create_timer(5.0, true, false, true).timeout
	else:
		await get_tree().create_timer(13.0, true, false, true).timeout
		
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://game_over.tscn")
