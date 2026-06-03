extends Control

func _ready() -> void:
	var global = get_node_or_null("/root/Global")
	if global:
		$Score.text = "Score: " + str(global.score) + "\nHigh Score: " + str(global.highscore)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_node("/root/Global").score = 0
		get_node("/root/Global").level = 1
		get_tree().change_scene_to_file("res://main_menu.tscn")
	elif event is InputEventMouseButton and event.pressed:
		get_node("/root/Global").score = 0
		get_node("/root/Global").level = 1
		get_tree().change_scene_to_file("res://main_menu.tscn")
