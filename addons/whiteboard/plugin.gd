@tool
extends EditorPlugin

const WhiteboardScene = preload("res://addons/whiteboard/Whiteboard.tscn")

var whiteboard_scene

func _enter_tree() -> void:
	whiteboard_scene = WhiteboardScene.instantiate()
	EditorInterface.get_editor_main_screen().add_child(whiteboard_scene)
	_make_visible(false)

func _exit_tree() -> void:
	pass

func _make_visible(visible: bool) -> void:
	if whiteboard_scene:
		whiteboard_scene.visible = visible

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "Whiteboard"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
