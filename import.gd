@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	print("begin")
	var htmlInput = AcceptDialog.new()
	var dialog = AcceptDialog.new()
	dialog.title = "Input HTML"
	
	# Create a text field for the user to type into
	var textInput = CodeEdit.new()
	textInput.gutters_draw_line_numbers = true
	textInput.placeholder_text = "mrrow"
	textInput.custom_minimum_size = Vector2(640, 640)
	
	# Structure the layout
	var container = VBoxContainer.new()
	container.add_child(Label.new()) # Spacing / Prompt description text
	container.get_child(0).text = "Input HTML inside the allWalls div."
	container.add_child(textInput)
	
	dialog.add_child(container)
	
	
	dialog.confirmed.connect(importHtml.bind(textInput, dialog))
	
	dialog.canceled.connect(func(): dialog.queue_free)
	
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

func importHtml(textInput, dialog):
		var input = textInput.text
		if input.is_empty():
			print("Input was empty!")
		else:
			print("User typed: ", input)
			# Do your operations with user_input here
			
		dialog.queue_free()
