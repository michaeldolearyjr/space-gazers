extends Node2D

@onready var player = $Player

@onready var laser_template = $Bullets/Laser
@onready var missile_template = $Bullets/Missile
@onready var red_laser_template = $EnemyBullets/RedLaser
@onready var gazer_template = $Enemies/Gazer
@onready var asteroid_template = $Enemies/Asteroid
@onready var enemy_ship_template = $Enemies/EnemyShip
@onready var powerup_template = $Powerups/Powerup

@onready var score_label = $UI/ScoreLabel
@onready var healthbar = $UI/Healthbar
@onready var level_label = $UI/LevelLabel
@onready var missile_label = $UI/MissileAmmoLabel
@onready var bomb_label = $UI/BombAmmoLabel
var rapid_fire_label: Label

var spawn_timer: float = 0.0

var level_timer: float = 0.0
var level_duration: float = 30.0 # 30 seconds per level
var enemy_ships_spawned_this_level: int = 0
var score: int = 0
var highscore: int = 0
var level: int = 1
var debug_hitboxes: bool = false
var max_enemy_ships_per_level: int = 1
var max_enemies_per_level: int = 15

var is_transitioning: bool = false
var transition_timer: float = 0.0
var is_in_hyperspace: bool = false
var story_ui: Control = null
var star_systems: Array[CPUParticles2D] = []

var pause_menu: CanvasLayer = null

func _ready() -> void:
	# Remove templates from tree so they don't process and queue_free() themselves
	$Bullets.remove_child(laser_template)
	$Bullets.remove_child(missile_template)
	$EnemyBullets.remove_child(red_laser_template)
	$Enemies.remove_child(gazer_template)
	$Enemies.remove_child(asteroid_template)
	$Enemies.remove_child(enemy_ship_template)
	$Powerups.remove_child(powerup_template)
	
	_setup_starfield()
	_setup_pause_menu()
	
	var global = get_node_or_null("/root/Global")
	if global:
		if global.level == 1 and global.score == 0:
			_setup_hyperspace()
		max_enemies_per_level = 15 + (global.level * 10)
		max_enemy_ships_per_level = global.level * 1
	
	# Start background music if present
	if has_node("MusicPlayer"):
		var stream = load("res://assets/audio/spaceTrack.ogg")
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		$MusicPlayer.stream = stream
		$MusicPlayer.volume_db = -10.0
		$MusicPlayer.play()
		
	# Setup Healthbar
	if has_node("UI/Healthbar"):
		var hb = $UI/Healthbar
		var img = Image.create(200, 20, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var tex = ImageTexture.create_from_image(img)
		hb.texture_under = tex
		hb.texture_progress = tex
		hb.tint_under = Color.RED
		hb.tint_progress = Color.GREEN
		hb.position = Vector2(20, 20)
		hb.scale = Vector2(1, 1)
		
	var vp = get_viewport_rect().size
	if has_node("UI/ScoreLabel"):
		score_label.position = Vector2(vp.x - 200, 20)
	if has_node("UI/LevelLabel"):
		level_label.position = Vector2(vp.x - 200, 50)
	if has_node("UI/MissileAmmoLabel"):
		missile_label.position = Vector2(20, 60)
	if has_node("UI/BombAmmoLabel"):
		bomb_label.position = Vector2(20, 90)
		
	# Create rapid fire label
	rapid_fire_label = Label.new()
	rapid_fire_label.position = Vector2(20, 120)
	var font = load("res://assets/RetroGaming.ttf")
	if font:
		rapid_fire_label.add_theme_font_override("font", font)
		rapid_fire_label.add_theme_font_size_override("font_size", 24)
	$UI.add_child(rapid_fire_label)
		
	if has_node("UI/FadeOverlay"):
		$UI/FadeOverlay.hide()

func _setup_starfield():
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = get_viewport_rect().size
	bg.z_index = -100
	add_child(bg)
	
	var env = WorldEnvironment.new()
	var env_res = Environment.new()
	env_res.background_mode = Environment.BG_CANVAS
	env_res.glow_enabled = true
	env_res.glow_intensity = 0.6
	env_res.glow_strength = 0.8
	env_res.glow_bloom = 0.1
	env_res.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env_res.glow_hdr_threshold = 1.0
	env.environment = env_res
	add_child(env)

	for i in range(3):
		var stars = CPUParticles2D.new()
		stars.amount = 200 * (i + 1)
		stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		var vp_size = get_viewport_rect().size
		stars.emission_rect_extents = Vector2(vp_size.x / 2.0, 0)
		stars.direction = Vector2(0, 1)
		stars.spread = 0.0
		stars.gravity = Vector2(0, 0)
		var speed = 100.0 + (i * 200.0)
		stars.initial_velocity_min = speed * 0.8
		stars.initial_velocity_max = speed * 1.2
		stars.scale_amount_min = (i + 1) * 0.5
		stars.scale_amount_max = (i + 1) * 1.0
		stars.lifetime = (vp_size.y + 200) / speed
		stars.preprocess = stars.lifetime
		stars.position = Vector2(vp_size.x / 2.0, -50)
		stars.z_index = -99 + i
		
		# Randomize star glow using a gradient with HDR values
		var grad = Gradient.new()
		grad.add_point(0.0, Color(0.1, 0.1, 0.1)) # Very dim
		grad.add_point(0.5, Color(0.4, 0.4, 0.4)) # Dim
		grad.add_point(0.9, Color(0.7, 0.7, 0.7)) # Normal
		grad.add_point(1.0, Color(1.2, 1.2, 1.0)) # Bright, glows!
		stars.color_initial_ramp = grad
		
		add_child(stars)
		star_systems.append(stars)

func _setup_hyperspace():
	is_in_hyperspace = true
	
	if is_instance_valid(player):
		player.set_physics_process(false)
	
	story_ui = Control.new()
	story_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(story_ui)
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	story_ui.add_child(dim)
	
	var text_label = Label.new()
	var font = load("res://assets/RetroGaming.ttf")
	if font:
		text_label.add_theme_font_override("font", font)
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.text = "The earth was destroyed by the gazers, you have nothing left to lose...\n\nFly your lone spaceship into deep space to take out as many of those alien bastards as you can.\n\nGood luck."
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vp = get_viewport_rect().size
	text_label.position = Vector2(vp.x / 2.0 - 400, vp.y / 2.0 - 200)
	text_label.size = Vector2(800, 400)
	story_ui.add_child(text_label)
	
	var press_key_label = Label.new()
	if font:
		press_key_label.add_theme_font_override("font", font)
	press_key_label.add_theme_font_size_override("font_size", 18)
	press_key_label.text = "Press Any Key to Continue"
	press_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_key_label.position = Vector2(vp.x / 2.0 - 200, vp.y - 100)
	press_key_label.size = Vector2(400, 30)
	story_ui.add_child(press_key_label)
	
	var img = Image.create(1, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var strip_tex = ImageTexture.create_from_image(img)
	
	for stars in star_systems:
		stars.texture = strip_tex
		stars.scale.y = 40.0
		
		var grad = Gradient.new()
		var colors = [Color.CYAN, Color.MAGENTA, Color.YELLOW, Color.GREEN, Color.RED, Color.BLUE]
		grad.add_point(0.0, colors[randi() % colors.size()] * 1.5)
		grad.add_point(0.5, colors[randi() % colors.size()] * 1.5)
		grad.add_point(1.0, Color.WHITE * 2.0)
		stars.color_initial_ramp = grad

func _drop_out_of_hyperspace():
	is_in_hyperspace = false
	var global = get_node_or_null("/root/Global")
	_start_level_transition(global.level if global else 1)
	if is_instance_valid(player):
		player.set_physics_process(true)
		
	if is_instance_valid(story_ui):
		story_ui.queue_free()
		
	var tween = create_tween()
	tween.set_parallel(true)
	
	for i in range(star_systems.size()):
		var stars = star_systems[i]
		
		tween.tween_property(stars, "scale", Vector2(1, 1), 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		var grad = Gradient.new()
		grad.add_point(0.0, Color(0.1, 0.1, 0.1))
		grad.add_point(0.5, Color(0.4, 0.4, 0.4))
		grad.add_point(0.9, Color(0.7, 0.7, 0.7))
		grad.add_point(1.0, Color(1.2, 1.2, 1.0))
		stars.color_initial_ramp = grad

	await tween.finished
	for stars in star_systems:
		stars.texture = null

func _setup_pause_menu():
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 100
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.size = get_viewport_rect().size
	pause_menu.add_child(dim)
	
	var label = Label.new()
	label.text = "PAUSED\nPress P to Resume\nPress ESC again to return to main menu"
	label.position = Vector2(get_viewport_rect().size.x / 2.0 - 450, get_viewport_rect().size.y / 2.0 - 100)
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu.add_child(label)
	
	var handler = Node.new()
	handler.set_script(load("res://pause_handler.gd"))
	handler.set("gameplay_node", self)
	pause_menu.add_child(handler)
	
	add_child(pause_menu)
	pause_menu.hide()

func _input(event: InputEvent) -> void:
	if is_in_hyperspace:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_drop_out_of_hyperspace()
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		var tree = get_tree()
		tree.paused = !tree.paused
		pause_menu.visible = tree.paused
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		var global = get_node_or_null("/root/Global")
		if global:
			global.debug_hitboxes = !global.debug_hitboxes

func play_explosion(pos: Vector2, target_color: Color = Color.ORANGE):
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = load("res://assets/audio/explosion.ogg")
	sfx.global_position = pos
	sfx.volume_db = -10.0
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, 0)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 300.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	
	var grad = Gradient.new()
	grad.add_point(0.0, target_color)
	grad.add_point(1.0, Color.RED)
	particles.color_initial_ramp = grad
	
	particles.global_position = pos
	
	var light = PointLight2D.new()
	light.texture = load("res://assets/images/light.png")
	light.color = Color.ORANGE
	light.energy = 2.0
	light.texture_scale = 0.5
	particles.add_child(light)
	
	add_child(particles)
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.autostart = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)

func play_impact(pos: Vector2, target_color: Color, laser_color: Color):
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.explosiveness = 0.8
	particles.direction = Vector2(0, -1)
	particles.spread = 90.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.gravity = Vector2(0, 0)
	
	var grad = Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	grad.add_point(0.0, target_color)
	grad.add_point(0.5, laser_color)
	particles.color_initial_ramp = grad
	
	particles.global_position = pos
	add_child(particles)
	
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
func _process(delta: float) -> void:
	if is_in_hyperspace:
		return

	if is_transitioning:
		transition_timer -= delta
		if transition_timer <= 0.0:
			is_transitioning = false
			if has_node("UI/TransitionLabel"):
				$UI/TransitionLabel.hide()
			enemy_ships_spawned_this_level = 0
			var global = get_node_or_null("/root/Global")
			if global:
				max_enemies_per_level = 15 + (global.level * 10)
				max_enemy_ships_per_level = global.level * 1
		_update_ui()
		return

	var global = get_node_or_null("/root/Global")
	if global:
		level_timer += delta
		if level_timer >= level_duration:
			var enemies_left = 0
			for enemy in $Enemies.get_children():
				if enemy != gazer_template and enemy != asteroid_template and enemy != enemy_ship_template and not enemy.is_queued_for_deletion():
					enemies_left += 1
			if enemies_left == 0:
				level_timer = 0.0
				global.level += 1
				_start_level_transition(global.level)

	_update_ui()
	_handle_spawning(delta)

func _start_level_transition(next_level: int):
	is_transitioning = true
	transition_timer = 3.0
	if not has_node("UI/TransitionLabel"):
		var label = Label.new()
		label.name = "TransitionLabel"
		label.add_theme_font_size_override("font_size", 48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var vp = get_viewport_rect().size
		label.position = Vector2(vp.x / 2.0 - 300, vp.y / 2.0 - 100)
		label.size = Vector2(600, 200)
		$UI.add_child(label)
	var lbl = $UI/TransitionLabel
	lbl.text = "Level " + str(next_level) + "\n\nIncoming enemy fleet detected!"
	lbl.show()

func _update_ui():
	var global = get_node_or_null("/root/Global")
	if global:
		score_label.text = "Score: " + str(global.score)
		level_label.text = "Level: " + str(global.level)
	if is_instance_valid(player):
		healthbar.value = (float(player.health) / 196.0) * 100.0
		missile_label.text = "Missiles: " + str(player.missiles_ammo)
		bomb_label.text = "Bombs: " + str(player.bombs_ammo)
		if is_instance_valid(rapid_fire_label):
			rapid_fire_label.text = "Rapid Fire: " + str(player.rapid_fire_ammo)

func _handle_spawning(delta: float):
	if level_timer >= level_duration:
		return

	if $Enemies.get_child_count() > max_enemies_per_level:
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		var global = get_node_or_null("/root/Global")
		var current_level = global.level if global else 1
		
		spawn_timer = max(0.05, 0.5 - (current_level * 0.08)) # Spawns get much faster
		var speed_multiplier = 1.0 + (current_level * 0.4) # Speed increases aggressively
		
		# Probability checks based on level
		var rand = randf()
		
		var gazer_prob = min(0.8, 0.2 + (current_level * 0.1))
		if rand < gazer_prob:
			var g = gazer_template.duplicate()
			g.show()
			var viewport = get_viewport_rect()
			g.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Enemies.add_child(g)
			g.speedy *= speed_multiplier
			g.speedx *= speed_multiplier
			
		if rand < 0.05 and enemy_ships_spawned_this_level < max_enemy_ships_per_level:
			var s = enemy_ship_template.duplicate()
			s.show()
			var viewport = get_viewport_rect()
			s.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Enemies.add_child(s)
			s.speedy *= speed_multiplier
			s.speedx *= speed_multiplier
			enemy_ships_spawned_this_level += 1
			
		if rand < 0.1:
			var a = asteroid_template.duplicate()
			a.show()
			var viewport = get_viewport_rect()
			a.global_position = Vector2(randf_range(0, viewport.size.x), -100)
			$Enemies.add_child(a)
			a.speedy *= speed_multiplier
			
		if rand < 0.02:
			var p = powerup_template.duplicate()
			p.show()
			var types = ["health", "rapid", "missile", "bomb"]
			p.type = types[randi() % types.size()]
			var viewport = get_viewport_rect()
			p.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Powerups.add_child(p)

func spawn_player_laser(pos: Vector2, target: Vector2):
	var laser = laser_template.duplicate()
	laser.show()
	laser.global_position = pos
	var dir = (target - pos).normalized()
	if dir == Vector2.ZERO: dir = Vector2(0, -1)
	laser.velocity = dir * 800.0
	$Bullets.add_child(laser)
	if laser.has_node("LaserSound"):
		laser.get_node("LaserSound").play()

func spawn_player_missile(pos: Vector2, target: Vector2):
	var missile = missile_template.duplicate()
	missile.show()
	missile.global_position = pos
	var dir = (target - pos).normalized()
	if dir == Vector2.ZERO: dir = Vector2(0, -1)
	missile.velocity = dir * 600.0
	$Bullets.add_child(missile)

func trigger_bomb(pos: Vector2):
	# Kill all enemies on screen
	for enemy in $Enemies.get_children():
		if enemy != gazer_template and enemy != enemy_ship_template and enemy != asteroid_template:
			if enemy.has_method("take_damage"):
				enemy.take_damage(1000)
				
	for bullet in $EnemyBullets.get_children():
		if bullet != red_laser_template:
			bullet.queue_free()

func spawn_enemy_laser(pos: Vector2):
	var laser = red_laser_template.duplicate()
	laser.show()
	laser.global_position = pos
	var dir = Vector2(0, 1) # default down
	if is_instance_valid(player):
		dir = (player.global_position - pos).normalized()
	laser.velocity = dir * 400.0
	$EnemyBullets.add_child(laser)

func spawn_gazer_laser(pos: Vector2):
	var laser = red_laser_template.duplicate()
	laser.show()
	laser.global_position = pos
	laser.modulate = Color.PURPLE
	laser.laser_color = Color.PURPLE
	if laser.has_node("Sprite2D"):
		laser.get_node("Sprite2D").modulate = Color.PURPLE
	var dir = Vector2(0, 1) # default down
	if is_instance_valid(player):
		dir = (player.global_position - pos).normalized()
	laser.velocity = dir * 400.0
	$EnemyBullets.add_child(laser)
