@tool
extends EditorScript

const WALL_CLASS_NAME :String = "wall"
const WALL_SCENE = preload("res://wall.tscn")

func _run():
	var dialog := ConfirmationDialog.new()
	dialog.title = "Input HTML"
	
	var code_edit := CodeEdit.new()
	code_edit.placeholder_text = "Paste the HTML which is inside the allWalls div."
	code_edit.custom_minimum_size = Vector2(640, 640)
	code_edit.gutters_draw_line_numbers = true
	dialog.add_child(code_edit)
	
	dialog.confirmed.connect(func(): _process_input(code_edit.text))
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

# 6. Handle the captured text input
func _process_input(text: String):
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
				print("wall")
				reading_in_wall = true
				this_wall_data = WallData.new()
				if parser.has_attribute("id"):
					this_wall_data.id = parser.get_named_attribute_value_safe("id")
				if parser.has_attribute("style"):
					for style in parser.get_named_attribute_value("style").replacen(" ","").split(";", false):
						var keyvalue = style.split(":")
						print(keyvalue[0], " is ", keyvalue[1])
						
						var key :String = keyvalue[0]
						var value_num :float = keyvalue[1].to_lower().rstrip("abcdefghijklmnopqrstuvwxyz").to_float()
						var value_unit :String = keyvalue[1].lstrip("0123456789").to_lower()
						
						if value_unit != "px":
							printerr("WARNING! unit is not px")
						
						match key:
							"left": this_wall_data.left = value_num
							"top": this_wall_data.top = value_num
							"width": this_wall_data.width = value_num
							"height": this_wall_data.height = value_num
					
			XMLParser.NODE_TEXT:
				var text_content = parser.get_node_data().strip_edges()
				if not text_content.is_empty() && reading_in_wall:
					print("Found Text: ", text_content)
					
			XMLParser.NODE_ELEMENT_END:
				var tag_name = parser.get_node_name()
				if tag_name != "div": continue
				if reading_in_wall: 
					print("wall end tag")
					
					_place_wall(this_wall_data)
					
					reading_in_wall = false

func _place_wall(data: WallData):
	var scene_root = EditorInterface.get_edited_scene_root()
	
	print("placing wall")
	
	var this_wall :WallObj = WALL_SCENE.instantiate()
	this_wall.position = Vector2(data.left, data.top)
	this_wall.size = Vector2(data.width, data.height)
	this_wall.name = "WALL - " + data.id + " ("+str(data.left)+", "+str(data.top)+")"
	if data.id != "": this_wall.id = data.id
	
	scene_root.get_node("WALLS").add_child(this_wall)
	this_wall.owner = scene_root
