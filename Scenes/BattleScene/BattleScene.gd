extends Control 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func _ready():
	MyMusicManager.play_track("main_game", 1.0)
	# Анимация
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	color_rect.visible = false
	

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
