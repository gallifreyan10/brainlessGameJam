extends RefCounted
class_name UIStyleHelper

static func apply_hologram_button_style(button: Button) -> void:
	if button == null:
		return
	var normal_texture := load("res://art/ui/hologramInterface/Button 1/Button Normal.png")
	var hover_texture := load("res://art/ui/hologramInterface/Button 1/Button Hover.png")
	var disabled_texture := load("res://art/ui/hologramInterface/Button 1/Button Disable.png")
	var pressed_texture := load("res://art/ui/hologramInterface/Button 1/Button Active.png")
	
	button.add_theme_stylebox_override("normal", make_button_stylebox(normal_texture))
	button.add_theme_stylebox_override("hover", make_button_stylebox(hover_texture))
	button.add_theme_stylebox_override("pressed", make_button_stylebox(pressed_texture))
	button.add_theme_stylebox_override("disabled", make_button_stylebox(disabled_texture))

static func make_button_stylebox(texture: Texture2D) -> StyleBoxTexture:
	var stylebox := StyleBoxTexture.new()
	stylebox.texture = texture
	
	stylebox.texture_margin_left = 8
	stylebox.texture_margin_right = 8
	stylebox.texture_margin_top = 8
	stylebox.texture_margin_bottom = 8
	
	stylebox.content_margin_bottom = 8
	stylebox.content_margin_top = 8
	stylebox.content_margin_left = 8
	stylebox.content_margin_right = 8
	
	return stylebox
	
