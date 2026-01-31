extends Control  # или Node2D, Node

func _ready():
	# Получаем окно через SceneTree
	var window = get_tree().root
	
	# Для веб-версии
	if OS.has_feature("web"):
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = Vector2i(1280, 720)
	
	# Настройка stretch (правильные константы)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED  # или другие варианты
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	# Обработка изменения размера
	window.size_changed.connect(_on_window_resized)

func _on_window_resized():
	print("Размер окна изменен: ", get_tree().root.size)
