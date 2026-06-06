extends Node

var gameplay_node: Node

func _input(event: InputEvent) -> void:
	var tree = get_tree()
	if not tree.paused:
		return
		
	if event.is_action_pressed("ui_cancel"):
		tree.paused = false
		tree.change_scene_to_file("res://main_menu.tscn")
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_P:
		tree.paused = false
		if is_instance_valid(gameplay_node) and gameplay_node.pause_menu:
			gameplay_node.pause_menu.visible = false
		get_viewport().set_input_as_handled()
