@tool
extends EditorPlugin

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
	
	
	add_dock(dock)

func _exit_tree() -> void:
	remove_dock(dock)
	dockRoot = null
	dock.queue_free()


func _apply_changes() -> void:
	dockRoot.get_node("%HtmlField").text = _get_walls_html()
	
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
