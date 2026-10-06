@tool
extends EditorPlugin

const WALL_TAG_NAME :String = "wall-"
const SECTION_TAG_NAME :String = "section"
const WRLD_RECT_SCENE = preload("res://prefabs/wrld_rect.tscn")
const WALL_SCENE = preload("res://prefabs/wall.tscn")
const DOCK_SCENE = preload("res://addons/siteEditor/site_editor_dock.tscn")
const TARGET_SCENE = "res://scenes/SITE.tscn"

const NW :String = "%NW"
const NE :String = "%NE"
const SW :String = "%SW"
const SE :String = "%SE"
enum Sections { NW, NE, SW, SE, NULL }

var dock :Control
var dock_root :Control

var label_fps :RichTextLabel
var field_html :CodeEdit
var btn_import :Button
var btn_export :Button
var check_auto :CheckBox
var btn_clear :Button
var wrap :CheckBox

enum AutoModes {
	OFF,
	UNSET,
	IMPORT,
	EXPORT
}
var auto_mode :AutoModes













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
	wrap = dock_get("%wrap")
	
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
	wrap.toggled.connect(_on_wrap_toggle)
	
	auto_mode = AutoModes.OFF
	
	add_dock(dock)
	_update_html_field()

func _exit_tree() -> void:
	remove_dock(dock)
	dock_root = null
	dock.queue_free()
	
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
			if(get_scene().scene_file_path == TARGET_SCENE):
				_update_html_field()
				
				
				
				
				
				
				
				
				

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
	
func _on_wrap_toggle(state: bool):
	field_html.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if state else TextEdit.LINE_WRAPPING_NONE

func _on_html_change():
	if(auto_mode == AutoModes.IMPORT):
		_html_to_scene(field_html.text, true)
	
func _update_html_field():
	field_html.text = _scene_to_html()





func dock_get(s): return dock_root.get_node(s)
func get_scene(): return EditorInterface.get_edited_scene_root()
	





func _obj_to_html(obj : WrldRect, anchor_top, anchor_left) -> String:
	const format = '<{tag_name}{id} style="{x_anchor}:{x}px; {y_anchor}:{y}px; width:{width}px; height:{height}px;">{inner}</{tag_name}>'
	
	var x = obj.get_begin().x if anchor_left else -obj.get_end().x 
	var y = obj.get_begin().y if anchor_top else -obj.get_end().y 
	return format.format({
		"tag_name": WALL_TAG_NAME if obj.collision else SECTION_TAG_NAME,
		"id": (' id="'+obj.id+'"') if obj.id != "" else "",
		"x_anchor": "left" if anchor_left else "right",
		"x": x,
		"y_anchor": "top" if anchor_top else "bottom",
		"y": y,
		"width": obj.size.x,
		"height": obj.size.y,
		"inner": "\n"+(obj.inner)+"\n" if obj.inner != "" else "",
		})

func _section_to_html(section_node :Control, anchor_top :bool, anchor_left :bool):
	var output = '<div id="'+section_node.name+'">\n'
	var children = section_node.get_children()
	for child :WrldRect in children:
		output += _obj_to_html(child, anchor_top, anchor_left).indent("    ")+"\n"
	output += '\n</div>\n\n'
	return output

func _scene_to_html() -> String:
	var output :String = (
		_section_to_html(get_scene().get_node(NW), false, false) +
		_section_to_html(get_scene().get_node(NE), false, true) +
		_section_to_html(get_scene().get_node(SW), true, false) +
		_section_to_html(get_scene().get_node(SE), true, true)
	)
	
	return output


















func _html_to_scene(text :String, replace :bool = false):
	print("INPUT: \n\n", text, "\n")
	var parser := XMLParser.new()
	
	var bytes = text.to_utf8_buffer()
	
	if parser.open_buffer(bytes) != OK:
		print("Failed to open HTML buffer")
		return
	
	var current_parent: Control = get_scene()
	
	var reading_in_wrld_rect = false
	var this_wrld_rect_data : WrldRectDat
	var this_wrld_rect_inner_start : int
	var this_wrld_rect_inner_end : int
	
	var prev_node_opened_wrld_rect = false
	
	if replace: _clear_walls()
	while parser.read() != ERR_FILE_EOF: 
		if prev_node_opened_wrld_rect:
			this_wrld_rect_inner_start = parser.get_node_offset()
			prev_node_opened_wrld_rect = false
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var tag_name = parser.get_node_name()
				var tag_id = parser.get_named_attribute_value_safe("id")
				var tag_style = parser.get_named_attribute_value_safe("style")
				match tag_name:
					"div": match tag_id:
						"NW":current_parent = get_scene().get_node(NW)
						"NE":current_parent = get_scene().get_node(NE)
						"SW":current_parent = get_scene().get_node(SW)
						"SE":current_parent = get_scene().get_node(SE)
					WALL_TAG_NAME, SECTION_TAG_NAME: reading_in_wrld_rect = true
				if !reading_in_wrld_rect: continue
				prev_node_opened_wrld_rect = true
				this_wrld_rect_inner_start = parser.get_node_offset()
				this_wrld_rect_data = WrldRectDat.new()
				this_wrld_rect_data.id = tag_id
				this_wrld_rect_data.collision = tag_name == "wall-"
				for style in tag_style.replacen(" ","").split(";", false):
					var keyvalue = style.split(":")
					var key :String = keyvalue[0]
					var value_num :float = keyvalue[1].to_lower().rstrip("abcdefghijklmnopqrstuvwxyz").to_float()
					var value_unit :String = keyvalue[1].lstrip("0123456789.").to_lower()
					
					if value_unit != "px": printerr("WARNING! unit is not px")

					match key:
						"left": 
							this_wrld_rect_data.x = value_num
							this_wrld_rect_data.anchor_left = true
						"right": 
							this_wrld_rect_data.x = value_num
							this_wrld_rect_data.anchor_left = false
						"top": 
							this_wrld_rect_data.y = value_num
							this_wrld_rect_data.anchor_top = true
						"bottom": 
							this_wrld_rect_data.y = value_num
							this_wrld_rect_data.anchor_top = false
						"width": this_wrld_rect_data.width = value_num
						"height": this_wrld_rect_data.height = value_num
					
			XMLParser.NODE_ELEMENT_END:
				var tag_name = parser.get_node_name()
				if !reading_in_wrld_rect: continue
				this_wrld_rect_inner_end = parser.get_node_offset()
				this_wrld_rect_data.inner = bytes.slice(this_wrld_rect_inner_start, this_wrld_rect_inner_end).get_string_from_utf8()
				_place_wrld_rect(current_parent, this_wrld_rect_data, replace)
				reading_in_wrld_rect = false
					
func _place_wrld_rect(parent :Control, data :WrldRectDat, replace :bool):
	var wrld_rect_name = ("("+str(data.x)+", "+str(data.y)+")") if data.id == "" else data.id
	var this_wrld_rect :WrldRect = WRLD_RECT_SCENE.instantiate()
	
	match [data.anchor_top, data.anchor_left]:
		[false, false]: this_wrld_rect.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
		[false, true]: this_wrld_rect.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE)
		[true, false]: this_wrld_rect.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
		[true, true]: this_wrld_rect.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	
	if data.anchor_left:
		this_wrld_rect.set_anchor_and_offset(SIDE_LEFT, 0, data.x)
		this_wrld_rect.set_anchor_and_offset(SIDE_RIGHT, 0, data.x + data.width)
	else:
		this_wrld_rect.set_anchor_and_offset(SIDE_LEFT, 1, -data.x-data.width)
		this_wrld_rect.set_anchor_and_offset(SIDE_RIGHT, 1, -data.x)
	
	if data.anchor_top:
		this_wrld_rect.set_anchor_and_offset(SIDE_TOP, 0, data.y)
		this_wrld_rect.set_anchor_and_offset(SIDE_BOTTOM, 0, data.y + data.height)
	else:
		this_wrld_rect.set_anchor_and_offset(SIDE_TOP, 1, -data.y-data.height)
		this_wrld_rect.set_anchor_and_offset(SIDE_BOTTOM, 1, -data.y)
	
	this_wrld_rect.name = wrld_rect_name
	
	this_wrld_rect.id = data.id
	this_wrld_rect.collision = data.collision
	this_wrld_rect.inner = data.inner.lstrip("\n").rstrip("\n ")
	
	(this_wrld_rect as ColorRect).color = Color(0,0,0,0.75) if data.collision else Color(1,1,1,0.75)
	
	parent.add_child(this_wrld_rect)
	this_wrld_rect.owner = get_scene()

func _clear_walls():
	for wall in get_scene().get_node(NW).get_children():
		wall.queue_free()
	for wall in get_scene().get_node(NE).get_children():
		wall.queue_free()
	for wall in get_scene().get_node(SW).get_children():
		wall.queue_free()
	for wall in get_scene().get_node(SE).get_children():
		wall.queue_free()
