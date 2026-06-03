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

var spawn_timer: float = 0.0

var level_timer: float = 0.0
var level_duration: float = 30.0 # 30 seconds per level
var enemies_spawned_this_level: int = 0
var max_enemies_per_level: int = 15

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
	
	# Start background music if present
	if has_node("MusicPlayer"):
		var stream = load("res://assets/audio/spaceTrack.ogg")
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		$MusicPlayer.stream = stream
		$MusicPlayer.play()
		
	# Setup Healthbar
	if has_node("UI/Healthbar"):
		var hb = $UI/Healthbar
		hb.texture_under = load("res://assets/images/healthbar.png")
		hb.texture_progress = load("res://assets/images/healthbar.png")
		hb.tint_under = Color(0.2, 0.2, 0.2)
		hb.tint_progress = Color.GREEN
		hb.position = Vector2(20, 20)
		hb.scale = Vector2(3, 3)

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
		stars.amount = 20 * (i + 1)
		stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		var vp_size = get_viewport_rect().size
		stars.emission_rect_extents = Vector2(vp_size.x / 2.0, 0)
		stars.direction = Vector2(0, 1)
		stars.spread = 0.0
		stars.gravity = Vector2(0, 0)
		var speed = 100.0 + (i * 200.0)
		stars.initial_velocity_min = speed * 0.8
		stars.initial_velocity_max = speed * 1.2
		stars.scale_amount_min = (i + 1) * 1.0
		stars.scale_amount_max = (i + 1) * 2.0
		stars.lifetime = (vp_size.y + 200) / speed
		stars.preprocess = stars.lifetime
		stars.position = Vector2(vp_size.x / 2.0, -50)
		stars.z_index = -99 + i
		
		# Randomize star glow using a gradient with HDR values
		var grad = Gradient.new()
		grad.add_point(0.0, Color(0.4, 0.4, 0.4)) # Dim, no glow
		grad.add_point(0.8, Color(0.8, 0.8, 0.8)) # Normal, no glow
		grad.add_point(1.0, Color(1.5, 1.5, 1.2)) # Bright, glows!
		stars.color_initial_ramp = grad
		
		add_child(stars)

func _setup_pause_menu():
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 100
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.size = get_viewport_rect().size
	pause_menu.add_child(dim)
	
	var label = Label.new()
	label.text = "PAUSED\nPress ESC or P to Resume"
	label.position = Vector2(get_viewport_rect().size.x / 2.0 - 200, get_viewport_rect().size.y / 2.0 - 50)
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu.add_child(label)
	
	add_child(pause_menu)
	pause_menu.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		var tree = get_tree()
		tree.paused = !tree.paused
		pause_menu.visible = tree.paused

func play_explosion(pos: Vector2, target_color: Color = Color.ORANGE):
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = load("res://assets/audio/explosion.ogg")
	sfx.global_position = pos
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
	
	var grad = Gradient.new()
	grad.add_point(0.0, target_color)
	grad.add_point(1.0, laser_color)
	particles.color_initial_ramp = grad
	
	particles.global_position = pos
	add_child(particles)
	
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
func _process(delta: float) -> void:
	var global = get_node_or_null("/root/Global")
	if global:
		level_timer += delta
		if level_timer >= level_duration:
			level_timer = 0.0
			global.level += 1
			enemies_spawned_this_level = 0
			max_enemies_per_level += 10 # Increase cap each level
			get_tree().change_scene_to_file("res://story_screen.tscn")

	_update_ui()
	_handle_spawning(delta)

func _update_ui():
	var global = get_node_or_null("/root/Global")
	if global:
		score_label.text = "Score: " + str(global.score)
		level_label.text = "Level: " + str(global.level)
	if is_instance_valid(player):
		healthbar.value = (float(player.health) / 196.0) * 100.0
		missile_label.text = "Missiles: " + str(player.missiles_ammo)
		bomb_label.text = "Bombs: " + str(player.bombs_ammo)

func _handle_spawning(delta: float):
	if enemies_spawned_this_level >= max_enemies_per_level:
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		var global = get_node_or_null("/root/Global")
		var current_level = global.level if global else 1
		
		spawn_timer = max(0.1, 0.5 - (current_level * 0.02)) # Spawns get faster
		var speed_multiplier = 1.0 + (current_level * 0.15) # Speed increases
		
		# Probability checks based on level (simplified)
		var rand = randf()
		
		if rand < 0.2:
			var g = gazer_template.duplicate()
			g.show()
			var viewport = get_viewport_rect()
			g.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Enemies.add_child(g)
			g.speedy *= speed_multiplier
			g.speedx *= speed_multiplier
			enemies_spawned_this_level += 1
			
		if rand < 0.05:
			var s = enemy_ship_template.duplicate()
			s.show()
			var viewport = get_viewport_rect()
			s.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Enemies.add_child(s)
			s.speedy *= speed_multiplier
			s.speedx *= speed_multiplier
			enemies_spawned_this_level += 1
			
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
