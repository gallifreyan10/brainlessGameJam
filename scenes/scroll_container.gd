extends ScrollContainer

@export var scroll_speed: float = 20.0
@export var start_delay: float = 1.0

var delay_remaining: float = 0.0
var scroll_position: float = 0.0

func _ready() -> void:
	restart_scroll()
	
func restart_scroll() -> void:
	delay_remaining = start_delay
	scroll_position = 0.0
	scroll_vertical = 0
	
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
		
	if delay_remaining > 0.0:
		delay_remaining -= delta
		return
		
	scroll_position += scroll_speed * delta
	scroll_vertical = roundi(scroll_position)
