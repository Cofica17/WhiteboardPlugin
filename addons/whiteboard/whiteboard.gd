@tool
extends Control

@onready var lines = $Lines
@onready var settings = $HBoxContainer/Settings
@onready var boards_option_btn = $HBoxContainer/Settings/OptionButton
@onready var draw_color_picker = $HBoxContainer/Settings/ColorPicker
@onready var ui_btn = $HBoxContainer/Button

const SAVE_PATH = "res://addons/whiteboard/save_boards.json"

var board_drawings = {
	1 : []
}
var points = PackedVector2Array()
var drawing = false
var erasing = false
var cur_line:Line2D
var draw_width = 3
var eraser_width = 15
var num_of_boards = 1
var cur_board:int = 1
var draw_color = Color.BLACK
var erase_color = Color.WHITE

func _ready() -> void:
	if not load_data():
		boards_option_btn.clear()
		boards_option_btn.add_item("Board " + str(num_of_boards))

func _process(delta: float) -> void:
	queue_redraw()
	
	if Input.is_key_pressed(KEY_J):
		load_data()

func _gui_input(event: InputEvent) -> void:
	if not Rect2(global_position, size).has_point(get_global_mouse_position()):
		if not points.is_empty():
			save_points()
		erasing = false
		drawing = false
		return
	
	if event is InputEventMouseButton and event.button_index == 4:
		if erasing:
			eraser_width -= 1
			eraser_width = max(eraser_width, 0)
			save_points()
			points = PackedVector2Array()
			cur_line = add_new_line_2d(eraser_width, erase_color)
		else:
			draw_width -= 1
			draw_width = max(draw_width, 0)
	elif event is InputEventMouseButton and event.button_index == 5:
		if erasing:
			eraser_width += 1
			save_points()
			points = PackedVector2Array()
			cur_line = add_new_line_2d(eraser_width, erase_color)
		else:
			draw_width += 1
	
	if event is InputEventMouseButton and event.button_index == 2 and event.is_pressed():
		cur_line = add_new_line_2d(eraser_width, erase_color)
		erasing = true
		points = PackedVector2Array()
	elif event is InputEventMouseButton and event.button_index == 2 and not event.is_pressed():
		save_points()
		erasing = false
	
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		drawing = true
		draw_color_picker.hide()
		cur_line = add_new_line_2d(draw_width, draw_color)
		points = PackedVector2Array()
	elif event is InputEventMouseButton and event.button_index == 1 and not event.is_pressed():
		save_points()
		drawing = false
	
	if event is InputEventMouseMotion and (drawing or erasing):
		points.append(get_local_mouse_position())
		cur_line.points = points

func _draw() -> void:
	var width = eraser_width/2.0 if erasing else draw_width
	var mouse_pos = get_local_mouse_position()
	draw_circle(mouse_pos, width, Color.BLACK, false, 1.0)

func _on_button_pressed() -> void:
	settings.visible = !settings.visible
	ui_btn.flip_h = !ui_btn.flip_h

func _on_add_new_board_btn_pressed() -> void:
	num_of_boards += 1
	boards_option_btn.add_item("Board " + str(num_of_boards))
	board_drawings[num_of_boards] = []
	change_cur_board(num_of_boards-1)

func change_cur_board(new_board):
	boards_option_btn.select(new_board)
	boards_option_btn.emit_signal("item_selected", new_board)

func _on_option_button_item_selected(index: int) -> void:
	cur_board = index + 1
	change_to_cur_board()

func change_to_cur_board():
	clear_lines()
	load_lines()

func save_points():
	var data = {
		"draw_width" : draw_width,
		"eraser_width" : eraser_width,
		"drawing" : drawing,
		"points" : points,
		"draw_color" : draw_color
	}
	board_drawings[cur_board].append(data)

func load_lines():
	for data in board_drawings[cur_board]:
		var width = data.draw_width if data.drawing else data.eraser_width
		var color =  data.draw_color if data.drawing else erase_color
		var line = add_new_line_2d(width, color)
		line.points = data.points

func add_new_line_2d(width, color):
	var line = Line2D.new()
	line.antialiased = true
	line.default_color = color
	line.width = width
	lines.add_child(line)
	return line

func clear_lines():
	for c in lines.get_children():
		c.queue_free()

func _on_choose_pencil_color_btn_pressed() -> void:
	draw_color_picker.visible = !draw_color_picker.visible

func _on_color_picker_color_changed(color: Color) -> void:
	draw_color = color

func _on_clear_board_pressed() -> void:
	clear_lines()
	board_drawings[cur_board].clear()

func _exit_tree() -> void:
	save_data()

func load_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	
	var data = file.get_var()
	if data == null or data.is_empty():
		return false
	
	cur_board = data.cur_board
	num_of_boards = data.num_of_boards
	board_drawings = data.board_drawings
	draw_width = data.draw_width
	eraser_width = data.eraser_width
	draw_color = Color(data.draw_color)
	erase_color = Color(data.erase_color)
	
	boards_option_btn.clear()
	
	for i in num_of_boards:
		boards_option_btn.add_item("Board " + str(i+1))
	
	change_cur_board(cur_board-1)
	
	return true

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(get_all_data(), true)
	file.close()

func get_all_data():
	return {
		"cur_board" : cur_board,
		"num_of_boards" : num_of_boards,
		"board_drawings" : board_drawings,
		"draw_width" : draw_width,
		"eraser_width" : eraser_width,
		"draw_color" : draw_color.to_html(),
		"erase_color" : erase_color.to_html()
	}
