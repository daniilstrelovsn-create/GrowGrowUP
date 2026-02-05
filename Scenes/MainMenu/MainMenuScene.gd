extends Control 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var start_button: BaseButton = $MarginContainer/VBoxContainer/StartButton
@onready var settings_button: BaseButton = $MarginContainer/VBoxContainer/SettingsButton
#@onready var exit_button: BaseButton = $MarginContainer/VBoxContainer/ExitButton

const SETTINGS_SCENE_PATH = "res://Scenes/Settings/SettingScene.tscn"
const BATTLE_SCENE_PATH = "res://Scenes/BattleScene/BattleScene.tscn"

func _ready():
	MyMusicManager.play_track("main_menu", 1.0)
	# Анимация
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	color_rect.visible = false
	
	settings_button.pressed.connect(_on_settings_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	#exit_button.pressed.connect(_on_exit_button_pressed)

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
	
func _on_settings_button_pressed() -> void:
	MusicManager.instance.play_button_click()
	transition_to(SETTINGS_SCENE_PATH)
	
func _on_start_button_pressed() -> void:
	MusicManager.instance.play_button_click()
	transition_to(BATTLE_SCENE_PATH)
	
func transition_to(scene_path: String):
	color_rect.visible = true
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
	get_tree().change_scene_to_file(scene_path)
