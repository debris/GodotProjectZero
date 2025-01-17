extends MarginContainer

@onready var h_box_container: HBoxContainer = %HBoxContainer

@export var scale_button_scene: PackedScene

var min_scale: int = 1
var max_scale: int = 0

###############
## overrides ##
###############


func _ready() -> void:
	_initialize()
	_connect_signals()


#############
## helpers ##
#############


func _initialize() -> void:
	var scale_: int = SaveFile.get_settings_population_scale()
	_clear_items()
	_add_scale_button(1, scale_)
	max_scale = max(1, ArrayUtils.max_element(SaveFile.workers.values() + [0]) / 10)
	var button_scale: int = min_scale
	while button_scale <= max_scale and h_box_container.get_child_count() < 11:
		button_scale *= 10
		_add_scale_button(button_scale, scale_)


func _add_scale_button(button_scale: int, active_scale: int) -> ScaleButton:
	var scale_button: ScaleButton = scale_button_scene.instantiate() as ScaleButton
	NodeUtils.add_child(scale_button, h_box_container)

	var button: Button = scale_button.button
	_connect_signal(button, button_scale)
	button.text = NumberUtils.format_number_scientific(button_scale, 0)
	if button_scale == active_scale:
		button.disabled = true
	else:
		button.disabled = false

	return scale_button


func _clear_items() -> void:
	NodeUtils.clear_children(h_box_container)


#############
## handler ##
#############


func _handle_on_worker_updated(total: int) -> void:
	if total > max_scale:
		var count: int = h_box_container.get_child_count()
		var exponent: int = max(0, count - 1)
		if total > PowUtils.pow_(10, exponent):
			_initialize()
		max_scale = total


func _handle_on_scale_button_up(button: Button, scale_: int) -> void:
	button.disabled = true
	SignalBus.toggle_scale_pressed.emit(scale_)
	button.release_focus()
	for scale_button: ScaleButton in h_box_container.get_children():
		var other_button: Button = scale_button.button
		if other_button.text != button.text:
			other_button.disabled = false


func _handle_on_scale_button_hover(scale_: int) -> void:
	var title: String = "[%s]" % NumberUtils.format_number(scale_)
	var info: String = Locale.get_scale_settings_info(scale_)
	SignalBus.info_hover.emit(title, info)


#############
## signals ##
#############


func _connect_signals() -> void:
	SignalBus.worker_updated.connect(_on_worker_updated)


func _connect_signal(button: Button, scale_: int) -> void:
	button.button_up.connect(_on_scale_button_up.bind(button, scale_))
	button.button_down.connect(_on_scale_button_down.bind(button))
	button.mouse_entered.connect(_on_scale_button_hover.bind(scale_))


func _on_worker_updated(_id: String, total: int, _amount: int) -> void:
	_handle_on_worker_updated(total)


func _on_scale_button_up(button: Button, scale_: int) -> void:
	_handle_on_scale_button_up(button, scale_)


func _on_scale_button_down(button: Button) -> void:
	button.release_focus()


func _on_scale_button_hover(scale_: int) -> void:
	_handle_on_scale_button_hover(scale_)
