extends Node

var gameplay_node: Node

func _input(event: InputEvent) -> void:
	var tree = get_tree()
	if not tree.paused:
		return
		
	if event.is_action_pressed("ui_cancel"):
		if get_viewport():
			get_viewport().set_input_as_handled()
		tree.paused = false
		tree.change_scene_to_file("res://src/ui/main_menu.tscn")
	elif event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if get_viewport():
			get_viewport().set_input_as_handled()
		tree.paused = false
		if is_instance_valid(gameplay_node) and gameplay_node.pause_menu:
			gameplay_node.pause_menu.visible = false
