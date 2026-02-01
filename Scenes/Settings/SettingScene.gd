extends Control 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
#@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
#@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/HBoxContainer5/BackButton

const SETTINGS_SCENE_PATH = "res://Scenes/MainMenu/MainMenu.tscn"

func _ready():
	# Анимация
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	color_rect.visible = false

	back_button.pressed.connect(_on_settings_button_pressed)

	# НЕ ТРОГАТЬ ЭТО SCALE
	var window = get_tree().root
	if OS.has_feature("web"):
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = Vector2i(1280, 720)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED  # или другие варианты
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size_changed.connect(_on_window_resized)

func _on_window_resized():
	print("Размер окна изменен: ", get_tree().root.size)
	
func transition_to(scene_path: String):
	color_rect.visible = true
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
	get_tree().change_scene_to_file(scene_path)

func _on_settings_button_pressed() -> void:
	transition_to(SETTINGS_SCENE_PATH)
