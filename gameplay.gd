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

var boss_template = preload("res://boss.tscn")
var boss_orb_template = preload("res://boss_orb.tscn")
var is_boss_phase: bool = false
var boss_phase_state: int = 0
var boss_wave_timer: float = 0.0

var is_ending_cutscene: bool = false
var ending_state: int = 0
var ending_timer: float = 0.0
var alien_planet_sprite: Sprite2D = null

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
	text_label.text = "The earth was destroyed by the gazers, and I have nothing left to lose...\n\nSo I fly my lone spaceship deep into gazer space and I'll take out as many of those alien bastards as I can!"
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vp = get_viewport_rect().size
	text_label.position = Vector2(vp.x / 2.0 - 400, vp.y / 2.0 - 200)
	text_label.size = Vector2(800, 400)
	text_label.visible_ratio = 0.0
	story_ui.add_child(text_label)
	
	var tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, text_label.text.length() * 0.05)
	
	var press_key_label = Label.new()
	if font:
		press_key_label.add_theme_font_override("font", font)
	press_key_label.add_theme_font_size_override("font_size", 18)
	press_key_label.text = "Press Any Key to Continue"
	press_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_key_label.position = Vector2(vp.x / 2.0 - 200, vp.y - 100)
	press_key_label.size = Vector2(400, 30)
	story_ui.add_child(press_key_label)
	
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
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

	if ending_state == 5:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			get_tree().change_scene_to_file("res://main_menu.tscn")
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		var tree = get_tree()
		tree.paused = !tree.paused
		pause_menu.visible = tree.paused
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		var global = get_node_or_null("/root/Global")
		if global:
			global.debug_hitboxes = !global.debug_hitboxes
			
	# Debug key to advance to the next level instantly
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		if is_transitioning:
			# Skip the transition immediately
			transition_timer = 0.0
		else:
			level_timer = 0.0
			for enemy in $Enemies.get_children():
				if enemy != gazer_template and enemy != asteroid_template and enemy != enemy_ship_template:
					enemy.queue_free()
			
			var global = get_node_or_null("/root/Global")
			if global:
				if is_boss_phase:
					is_boss_phase = false
					boss_phase_state = 0
					global.level += 1
					_start_level_transition(global.level)
				else:
					if global.level % 3 == 0:
						is_boss_phase = true
						boss_phase_state = 1
						boss_wave_timer = 4.0
					else:
						global.level += 1
						_start_level_transition(global.level)

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
		
	if is_ending_cutscene:
		_handle_ending_cutscene(delta)
		_update_ui()
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
	if global and not is_boss_phase:
		level_timer += delta
		if level_timer >= level_duration:
			var enemies_left = 0
			for enemy in $Enemies.get_children():
				if enemy != gazer_template and enemy != asteroid_template and enemy != enemy_ship_template and not enemy.is_queued_for_deletion():
					if enemy.name.find("Asteroid") == -1:
						enemies_left += 1
			if enemies_left == 0:
				level_timer = 0.0
				if global.level % 3 == 0:
					is_boss_phase = true
					boss_phase_state = 1
					boss_wave_timer = 4.0 # Duration of powerup wave
				else:
					global.level += 1
					_start_level_transition(global.level)

	if is_boss_phase:
		_handle_boss_phase(delta)
		_update_ui()
		return

	_update_ui()
	_handle_spawning(delta)

func _start_level_transition(next_level: int):
	is_transitioning = true
	if not has_node("UI/TransitionLabel"):
		var label = Label.new()
		label.name = "TransitionLabel"
		label.add_theme_font_size_override("font_size", 48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var vp = get_viewport_rect().size
		label.position = Vector2(vp.x / 2.0 - 500, vp.y / 2.0 - 100)
		label.size = Vector2(1000, 200)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		$UI.add_child(label)
		
	var stories = [
		"",
		"Earth is gone... My family... gone.\nI can't believe I'm still alive. I must keep going!",
		"They just keep coming... Every alien destroyed is a small measure of justice!",
		"Their mothership was massive, but it burned just like the rest of them. I think I know where they're coming from.",
		"The deeper I go, the more aggressive they get. My ship is holding together, but for how long?",
		"I can see their home system in the distance. The stars here are strange...",
		"Another mothership down. I'm so close to their planet... maybe I'll deliver a present to them!",
		"Almost there! The gazers won't stop me! I will make them pay for what they did!",
		"The alien homeworld... This is it! I have nothing left to lose!",
	]
	var story = "Incoming enemy fleet detected!"
	if next_level >= 2 and next_level <= 9:
		story = stories[next_level - 1]
		
	var lbl = $UI/TransitionLabel
	var full_text = "Level " + str(next_level) + "\n\n" + story
	lbl.text = full_text
	lbl.visible_ratio = 0.0
	lbl.show()
	
	var typing_time = full_text.length() * 0.05
	transition_timer = typing_time + 4.0 # Give comfortable reading time after typing
	
	var tween = create_tween()
	tween.tween_property(lbl, "visible_ratio", 1.0, typing_time)

func _handle_boss_phase(delta: float):
	boss_wave_timer -= delta
	if boss_phase_state == 1:
		# Powerup wave
		if boss_wave_timer <= 0:
			boss_phase_state = 2
			boss_wave_timer = 5.0 # wait 5 seconds before boss spawns
		else:
			# Spawn powerups/asteroids rapidly
			if randf() < 0.015: # Limit asteroids (~1 per second)
				var a = asteroid_template.duplicate()
				a.show()
				var vp = get_viewport_rect().size
				a.global_position = Vector2(randf_range(0, vp.x), -50)
				$Enemies.add_child(a)
			if randf() < 0.05: # Limit powerups (~3 per second)
				var p = powerup_template.duplicate()
				p.show()
				var vp = get_viewport_rect().size
				p.global_position = Vector2(randf_range(0, vp.x), -50)
				p.type = "missile" if randf() < 0.7 else (["health", "rapid"][randi() % 2])
				$Powerups.add_child(p)
	elif boss_phase_state == 2:
		if boss_wave_timer <= 0:
			boss_phase_state = 3
			var b = boss_template.instantiate()
			var vp = get_viewport_rect().size
			b.global_position = Vector2(vp.x / 2.0, -100)
			$Enemies.add_child(b)
	elif boss_phase_state == 3:
		var has_boss = false
		for enemy in $Enemies.get_children():
			if enemy.name.begins_with("Boss") and not enemy.is_queued_for_deletion():
				has_boss = true
				break
		if not has_boss:
			# Boss defeated!
			is_boss_phase = false
			var global = get_node_or_null("/root/Global")
			if global:
				if global.level >= 9:
					is_ending_cutscene = true
					ending_state = 0
					ending_timer = 2.0
					if is_instance_valid(player):
						player.set_physics_process(false)
						player.set_process_input(false)
						player.hit_timer = 0
						if player.has_node("Sprite2D"):
							player.get_node("Sprite2D").frame_coords.y = 0
					for b in $EnemyBullets.get_children(): b.queue_free()
					for b in $Bullets.get_children(): b.queue_free()
				else:
					global.level += 1
					_start_level_transition(global.level)

func _handle_ending_cutscene(delta: float):
	ending_timer -= delta
	if ending_state == 0:
		if ending_timer <= 0:
			ending_state = 1
			ending_timer = 5.0
			alien_planet_sprite = Sprite2D.new()
			var img = Image.new()
			var err = img.load("res://assets/images/alienplanet.png")
			if err == OK:
				alien_planet_sprite.texture = ImageTexture.create_from_image(img)
			else:
				# Fallback if image not loaded properly
				var fallback = PlaceholderTexture2D.new()
				fallback.size = Vector2(800, 800)
				alien_planet_sprite.texture = fallback
			
			var vp = get_viewport_rect().size
			var tex_w = alien_planet_sprite.texture.get_width()
			var target_scale = (vp.x / 2.0) / tex_w # Half the viewport width
			alien_planet_sprite.scale = Vector2(target_scale, target_scale)
			alien_planet_sprite.position = Vector2(vp.x / 2.0, -vp.y / 2.0)
			alien_planet_sprite.z_index = -50
			alien_planet_sprite.light_mask = 0
			add_child(alien_planet_sprite)
			
			var tween = create_tween()
			tween.tween_property(alien_planet_sprite, "position:y", vp.y / 2.0, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
	elif ending_state == 1:
		if ending_timer <= 0:
			ending_state = 2
			ending_timer = 3.0
			if is_instance_valid(player):
				var tween = create_tween().set_parallel(true)
				tween.tween_property(player, "position", alien_planet_sprite.position, 3.0)
				tween.tween_property(player, "scale", Vector2(0, 0), 3.0)
				
	elif ending_state == 2:
		if ending_timer <= 0:
			ending_state = 3
			ending_timer = 4.0
			var has_bomb = false
			if is_instance_valid(player) and player.bombs_ammo > 0:
				has_bomb = true
				
			if has_bomb:
				var global = get_node_or_null("/root/Global")
				if global:
					global.add_score(1000000000)
				if is_instance_valid(alien_planet_sprite):
					for i in range(15):
						var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
						play_explosion(alien_planet_sprite.position + offset, Color.CYAN)
						play_explosion(alien_planet_sprite.position + offset, Color.WHITE)
					alien_planet_sprite.hide()
			
			var dim = ColorRect.new()
			dim.color = Color(0, 0, 0, 0)
			dim.set_anchors_preset(Control.PRESET_FULL_RECT)
			dim.name = "EndDim"
			$UI.add_child(dim)
			var fade_tween = create_tween()
			fade_tween.tween_property(dim, "color:a", 1.0, 2.0)
			
	elif ending_state == 3:
		if ending_timer <= 0:
			ending_state = 4
			_show_ending_screen()

func _show_ending_screen():
	var has_bomb = false
	if is_instance_valid(player) and player.bombs_ammo > 0:
		has_bomb = true
		
	var story_ui = Control.new()
	story_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(story_ui)
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	story_ui.add_child(dim)
	
	var text_label = Label.new()
	var font = load("res://assets/RetroGaming.ttf")
	if font:
		text_label.add_theme_font_override("font", font)
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vp = get_viewport_rect().size
	text_label.position = Vector2(vp.x / 2.0 - 400, vp.y / 2.0 - 200)
	text_label.size = Vector2(800, 400)
	story_ui.add_child(text_label)
	
	if has_bomb:
		text_label.text = "CONGRATULATIONS!\n\nYou reached the alien homeworld and delivered the ultimate payload. The planet is destroyed, and Earth is avenged.\n\nYou have beaten the game!"
	else:
		text_label.text = "CONGRATULATIONS!\n\nYou survived the journey and reached the alien homeworld...\n\nYou have beaten the game!"
		
	text_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, text_label.text.length() * 0.05)
		
	var global = get_node_or_null("/root/Global")
	if global:
		var score_lbl = Label.new()
		if font:
			score_lbl.add_theme_font_override("font", font)
		score_lbl.add_theme_font_size_override("font_size", 32)
		score_lbl.text = "FINAL SCORE: " + str(global.score) + "\nHIGH SCORE: " + str(global.highscore)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_lbl.position = Vector2(vp.x / 2.0 - 300, vp.y / 2.0 + 100)
		score_lbl.size = Vector2(600, 100)
		story_ui.add_child(score_lbl)
		
	var press_key_label = Label.new()
	if font:
		press_key_label.add_theme_font_override("font", font)
	press_key_label.add_theme_font_size_override("font_size", 18)
	press_key_label.text = "Press Any Key to Return to Menu"
	press_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_key_label.position = Vector2(vp.x / 2.0 - 200, vp.y - 100)
	press_key_label.size = Vector2(400, 30)
	story_ui.add_child(press_key_label)
	
	ending_state = 5

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
			
		var asteroid_prob = 0.1 * (spawn_timer / 0.5)
		if rand < asteroid_prob:
			var a = asteroid_template.duplicate()
			a.show()
			var viewport = get_viewport_rect()
			a.global_position = Vector2(randf_range(0, viewport.size.x), -100)
			$Enemies.add_child(a)
			var asteroid_speed_multiplier = 1.0 + (current_level * 0.1)
			a.speedy *= asteroid_speed_multiplier
			
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
	var explosion = load("res://expanding_explosion.gd").new()
	var vp = get_viewport_rect().size
	explosion.max_radius = max(vp.x, vp.y) / 2.0
	explosion.duration = 1.5
	explosion.ring_color = Color.CYAN
	explosion.clears_bullets = true
	explosion.global_position = pos
	call_deferred("add_child", explosion)

func spawn_enemy_laser(pos: Vector2):
	var laser = red_laser_template.duplicate()
	laser.show()
	laser.global_position = pos
	var dir = Vector2(0, 1) # default down
	if is_instance_valid(player):
		dir = (player.global_position - pos).normalized()
	laser.velocity = dir * 400.0
	$EnemyBullets.add_child(laser)

func spawn_swirling_orb(pos: Vector2):
	var orb = boss_orb_template.instantiate()
	orb.global_position = pos
	var dir = Vector2(0, 1)
	if is_instance_valid(player):
		dir = (player.global_position - pos).normalized()
	orb.velocity = dir * 150.0
	$EnemyBullets.add_child(orb)

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
