extends Control

func _ready() -> void:
	var global = get_node_or_null("/root/Global")
	if global and has_node("HighScore"):
		$HighScore.text = "High Score: " + str(global.highscore)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://story_screen.tscn")
	elif event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://story_screen.tscn")
