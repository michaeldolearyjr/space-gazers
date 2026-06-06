extends Control

func _ready() -> void:
	var global = get_node_or_null("/root/Global")
	if global and global.level > 1:
		$TextLabel.text = "Level " + str(global.level) + "\n\nIncoming enemy fleet detected!"
	
	$TextLabel.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property($TextLabel, "visible_ratio", 1.0, $TextLabel.text.length() * 0.05)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://gameplay.tscn")
	elif event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://gameplay.tscn")
