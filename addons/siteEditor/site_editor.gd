@tool
extends EditorPlugin

const WALL_CLASS_NAME :String = "wall"
const WALL_SCENE = preload("res://wall.tscn")
const DOCK_SCENE = preload("res://addons/siteEditor/site_editor_dock.tscn")

var dock :Control
var dockRoot :SiteEditorDock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	dockRoot = DOCK_SCENE.instantiate()
	
	dock = EditorDock.new()
	dock.title = "Layout Tool"
	dock.default_slot = DOCK_SLOT_LEFT_UL
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	dock.add_child(dockRoot)
	
	dockRoot.get_node("%imp").pressed.connect(func(): _apply_walls_html(dockRoot.get_node("%html").text))
	dockRoot.get_node("%exp").pressed.connect(_update_html_field)
	dockRoot.get_node("%clear").pressed.connect(_clear_walls)
	
	
	add_dock(dock)
	_update_html_field()

func _exit_tree() -> void:
	remove_dock(dock)
	dockRoot = null
	dock.queue_free()


func _apply_changes() -> void:
	if dockRoot.get_node("%UpdateOnSave").button_pressed: _update_html_field()

func _update_html_field():
	dockRoot.get_node("%html").text = _get_walls_html()

func _get_walls_html() -> String:
	var walls = EditorInterface.get_edited_scene_root().get_node("WALLS").get_children()
	var output = ""
	
	for wall in walls:
		# model: <div class="wall" style="left: 2000px; top: 0px; width:512px; height:1900px;"></div>
		var top = wall.position.y
		var left = wall.position.x
		var width = wall.size.x
		var height = wall.size.y
		var id = wall.id
		
		output += ('<div class="wall" ' + 
			('' if id == '' else 'id="'+id+'" ') + 'style="' + 
			'top:'+str(top)+'px; ' + 
			'left:'+str(left)+'px; ' + 
			'width:'+str(width)+'px; ' + 
			'height:'+str(height)+'px;"></div>\n')
	
	return output

func _apply_walls_html(text :String, replace :bool = false):
	print("INPUT: \n\n", text, "\n")
	var parser := XMLParser.new()
	
	if parser.open_buffer(text.to_utf8_buffer()) != OK:
		print("Failed to open HTML buffer")
		return
	
	var reading_in_wall = false
	var this_wall_data : WallData
	
	# Loop through the tokens sequentially until reaching the End Of File
	while parser.read() != ERR_FILE_EOF:
		var node_type = parser.get_node_type()
		
		match node_type:
			XMLParser.NODE_ELEMENT:
				var tag_name = parser.get_node_name()
				if parser.get_named_attribute_value_safe("class") != WALL_CLASS_NAME : continue
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
						var value_unit :String = keyvalue[1].lstrip("0123456789").to_lower()
						
						print(value_unit)
						if value_unit != "px":
							printerr("WARNING! unit is not px")
						
						match key:
							"left": this_wall_data.left = value_num
							"top": this_wall_data.top = value_num
							"width": this_wall_data.width = value_num
							"height": this_wall_data.height = value_num
					
			XMLParser.NODE_ELEMENT_END:
				var tag_name = parser.get_node_name()
				if tag_name != "div": continue
				if reading_in_wall: 
					#print("wall end tag")
					_place_wall(this_wall_data)
					reading_in_wall = false
					
func _place_wall(data: WallData):
	var scene_root = EditorInterface.get_edited_scene_root()
	var wall_name = "WALL - " + data.id + " ("+str(data.left)+", "+str(data.top)+") to ("+str(data.left+data.width)+", "+str(data.top+data.height)+")"
	if scene_root.get_node("WALLS").has_node(wall_name):
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
