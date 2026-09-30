@tool
extends EditorPlugin

const WALL_TAG_NAME :String = "wall-"
const WALL_SCENE = preload("res://prefabs/wall.tscn")
const DOCK_SCENE = preload("res://addons/siteEditor/site_editor_dock.tscn")
const TARGET_SCENE = "res://scenes/SITE.tscn"

var dock :Control
var dock_root :Control

var label_fps :RichTextLabel
var field_html :CodeEdit
var btn_import :Button
var btn_export :Button
var check_auto :CheckBox
var btn_clear :Button


enum AutoModes {
	OFF,
	UNSET,
	IMPORT,
	EXPORT
}
var auto_mode :AutoModes

func _enable_plugin() -> void:
	# Add autoloads here.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func dock_get(s): return dock_root.get_node(s)

func _enter_tree() -> void:
	set_process(true)
	# Initialization of the plugin goes here.
	dock_root = DOCK_SCENE.instantiate()
	
	dock = EditorDock.new()
	dock.title = "Layout Tool"
	dock.default_slot = DOCK_SLOT_LEFT_UL
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	dock.add_child(dock_root)
	
	label_fps = dock_get("%fps")
	field_html = dock_get("%html")
	btn_import = dock_get("%imp")
	btn_export = dock_get("%exp")
	check_auto = dock_get("%auto")
	btn_clear = dock_get("%clear")
	
	btn_import.pressed.connect(_on_import_press)
	btn_export.pressed.connect(_on_export_press)
	btn_clear.pressed.connect(_on_clear_press)
	check_auto.button_up.connect(func(): 
		if check_auto.button_pressed:
			auto_mode = AutoModes.UNSET
		else:
			auto_mode = AutoModes.OFF
		)
	field_html.text_changed.connect(_on_html_change)
	
	
	auto_mode = AutoModes.OFF
	
	add_dock(dock)
	_update_html_field()


func _exit_tree() -> void:
	remove_dock(dock)
	dock_root = null
	dock.queue_free()

func _on_import_press():
	match auto_mode:
		AutoModes.OFF: _html_to_scene(field_html.text)
		AutoModes.UNSET: auto_mode = AutoModes.IMPORT
		AutoModes.EXPORT: auto_mode = AutoModes.IMPORT
func _on_export_press():
	match auto_mode:
		AutoModes.OFF: _update_html_field()
		AutoModes.UNSET: auto_mode = AutoModes.EXPORT
		AutoModes.IMPORT: auto_mode = AutoModes.EXPORT
func _on_clear_press():
	_clear_walls()
func _on_html_change():
	if(auto_mode == AutoModes.IMPORT):
		_html_to_scene(field_html.text, true)
	
func _update_html_field():
	field_html.text = _scene_to_html()

func _scene_to_html() -> String:
	var walls = EditorInterface.get_edited_scene_root().get_node("WALLS").get_children()
	var output = ""
	
	for wall in walls:
		# model: <div class="wall" style="left: 2000px; top: 0px; width:512px; height:1900px;"></div>
		var top = wall.position.y
		var left = wall.position.x
		var width = wall.size.x
		var height = wall.size.y
		var id = wall.id
		
		output += ('<'+WALL_TAG_NAME + 
			(' ' if id == '' else ' id="'+id+'" ') + 'style="' + 
			'top:'+str(top)+'px; ' + 
			'left:'+str(left)+'px; ' + 
			'width:'+str(width)+'px; ' + 
			'height:'+str(height)+'px;"></wall->\n')
	
	return output

func _process(delta) -> void:
	label_fps.text = "fps: "+str(Engine.get_frames_per_second())
	
	btn_export.get_node("clr").color = Color(0,0,0,0)
	btn_import.get_node("clr").color = Color(0,0,0,0)
	
	match auto_mode:
		AutoModes.OFF:
			pass
		AutoModes.UNSET:
			pass
		AutoModes.IMPORT:
			btn_import.get_node("clr").color = Color(0, 1, 0, 0.1)
		AutoModes.EXPORT:
			btn_export.get_node("clr").color = Color(0, 1, 0, 0.1)
			if(EditorInterface.get_edited_scene_root().scene_file_path == TARGET_SCENE):
				_update_html_field()

func _html_to_scene(text :String, replace :bool = false):
	print("INPUT: \n\n", text, "\n")
	var parser := XMLParser.new()
	
	if parser.open_buffer(text.to_utf8_buffer()) != OK:
		print("Failed to open HTML buffer")
		return
	
	var reading_in_wall = false
	var this_wall_data : WallData
	
	if replace: _clear_walls()
	
	# Loop through the tokens sequentially until reaching the End Of File
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var tag_name = parser.get_node_name()
				if tag_name != WALL_TAG_NAME : continue
				#print("wall")
				reading_in_wall = true
				this_wall_data = WallData.new()
				if parser.has_attribute("id"):
					this_wall_data.id = parser.get_named_attribute_value_safe("id")
				if parser.has_attribute("style"):
					for style in parser.get_named_attribute_value("style").replacen(" ","").split(";", false):
						var keyvalue = style.split(":")
						#print(keyvalue[0], " is ", keyvalue[1])
						var key :String = keyvalue[0]
						var value_num :float = keyvalue[1].to_lower().rstrip("abcdefghijklmnopqrstuvwxyz").to_float()
						var value_unit :String = keyvalue[1].lstrip("0123456789.").to_lower()
						
						#print(value_unit)
						if value_unit != "px": printerr("WARNING! unit is not px")
						
						match key:
							"left": this_wall_data.left = value_num
							"top": this_wall_data.top = value_num
							"width": this_wall_data.width = value_num
							"height": this_wall_data.height = value_num
					
			XMLParser.NODE_ELEMENT_END:
				var tag_name = parser.get_node_name()
				if tag_name != WALL_TAG_NAME || !reading_in_wall: continue
				#print("wall end tag")
				_place_wall(this_wall_data, replace)
				reading_in_wall = false
					
func _place_wall(data :WallData, replace :bool):
	var scene_root = EditorInterface.get_edited_scene_root()
	var wall_name = "WALL - " + data.id + " ("+str(data.left)+", "+str(data.top)+") to ("+str(data.left+data.width)+", "+str(data.top+data.height)+")"
	if scene_root.get_node("WALLS").has_node(wall_name) && !replace:
		print("wall already exists")
		return
	
	#print("placing wall")
	
	var this_wall :WallObj = WALL_SCENE.instantiate()
	this_wall.position = Vector2(data.left, data.top)
	this_wall.size = Vector2(data.width, data.height)
	this_wall.name = "WALL - " + data.id + " ("+str(data.left)+", "+str(data.top)+") to ("+str(data.left+data.width)+", "+str(data.top+data.height)+")"
	if data.id != "": this_wall.id = data.id
	
	scene_root.get_node("WALLS").add_child(this_wall)
	this_wall.owner = scene_root

func _clear_walls():
	for wall in EditorInterface.get_edited_scene_root().get_node("WALLS").get_children():
		wall.queue_free()
