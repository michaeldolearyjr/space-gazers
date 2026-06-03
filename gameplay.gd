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

func _ready() -> void:
	# Remove templates from tree so they don't process and queue_free() themselves
	$Bullets.remove_child(laser_template)
	$Bullets.remove_child(missile_template)
	$EnemyBullets.remove_child(red_laser_template)
	$Enemies.remove_child(gazer_template)
	$Enemies.remove_child(asteroid_template)
	$Enemies.remove_child(enemy_ship_template)
	$Powerups.remove_child(powerup_template)
	
	# Start background music if present
	if has_node("MusicPlayer") and $MusicPlayer.stream != null:
		$MusicPlayer.play()


func _process(delta: float) -> void:
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
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = 0.5 # check twice a second
		
		# Probability checks based on level (simplified)
		var rand = randf()
		
		if rand < 0.2:
			var g = gazer_template.duplicate()
			g.show()
			var viewport = get_viewport_rect()
			g.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Enemies.add_child(g)
			
		if rand < 0.05:
			var s = enemy_ship_template.duplicate()
			s.show()
			var viewport = get_viewport_rect()
			s.global_position = Vector2(randf_range(0, viewport.size.x), -50)
			$Enemies.add_child(s)
			
		if rand < 0.1:
			var a = asteroid_template.duplicate()
			a.show()
			var viewport = get_viewport_rect()
			a.global_position = Vector2(randf_range(0, viewport.size.x), -100)
			$Enemies.add_child(a)
			
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
