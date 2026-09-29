@tool
extends EditorScript
class_name WorldExportWalls

func _run():
	var walls = EditorInterface.get_edited_scene_root().get_node("WALLS").get_children()
	var output = ""
	
	for wall in walls:
		# <div class="wall" style="left: 2000px; top: 0px; width:512px; height:1900px;"></div>
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
			
	var dialog := AcceptDialog.new()
	dialog.title = "Here you go"
	dialog.ok_button_text = "thx"
	
	var code_edit := CodeEdit.new()
	code_edit.editable = false
	code_edit.text = output
	code_edit.custom_minimum_size = Vector2(640, 640)
	code_edit.gutters_draw_line_numbers = true
	dialog.add_child(code_edit)
	
	#dialog.confirmed.connect(func(): _process_input(code_edit.text))
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()
	
	DisplayServer.clipboard_set(output)
