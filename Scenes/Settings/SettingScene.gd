extends Control 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/HBoxContainer/HSlider
@onready var back_button: Button = $MarginContainer/VBoxContainer/HBoxContainer5/BackButton

const SETTINGS_SCENE_PATH = "res://Scenes/MainMenu/MainMenu.tscn"

func _ready():
	# Анимация
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	color_rect.visible = false

	back_button.pressed.connect(_on_settings_button_pressed)

	# Инициализация слайдера музыки
	if music_slider:
		# Настраиваем диапазон слайдера (0-100 для процентов)
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
		
		# Загружаем сохранённую громкость
		load_music_volume()
		
		# Подключаем сигнал изменения
		music_slider.value_changed.connect(_on_music_slider_changed)
	else:
		print("⚠️ music_slider не найден! Проверь путь к ноду.")

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
	
# Загрузка громкости музыки
func load_music_volume():
	var config = ConfigFile.new()
	
	if config.load("user://audio_settings.cfg") == OK:
		# Получаем сохранённую громкость в децибелах
		var saved_volume_db = config.get_value("audio", "music_volume", -10.0)
		
		# Преобразуем децибелы в проценты для слайдера
		# -40 dB = 0%, 0 dB = 100%
		var slider_value = remap(saved_volume_db, -40.0, 0.0, 0.0, 100.0)
		music_slider.value = slider_value
		
		# Устанавливаем громкость в MusicManager
		if MusicManager.instance:
			MusicManager.instance.set_volume(saved_volume_db)
	else:
		# Настройки по умолчанию
		music_slider.value = 50  # 50% громкости (-20 dB)
		if MusicManager.instance:
			MusicManager.instance.set_volume(-20.0)

# Обработка изменения слайдера
func _on_music_slider_changed(value: float):
	# Преобразуем проценты в децибелы
	# 0% = -40 dB (тишина), 100% = 0 dB (максимум)
	var volume_db = remap(value, 0.0, 100.0, -40.0, 0.0)
	
	# Устанавливаем громкость через MusicManager
	if MusicManager.instance:
		MusicManager.instance.set_volume(volume_db)
		print("Громкость музыки: ", value, "% (", volume_db, " dB)")
	else:
		print("⚠️ MusicManager не найден!")

# Сохранение громкости музыки
func save_music_volume():
	if MusicManager.instance:
		var current_volume_db = MusicManager.instance.get_volume()
		
		var config = ConfigFile.new()
		config.set_value("audio", "music_volume", current_volume_db)
		config.save("user://audio_settings.cfg")
		
		print("Настройки музыки сохранены: ", current_volume_db, " dB")
