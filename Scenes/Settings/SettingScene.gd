extends Control 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/HBoxContainer/HSlider
@onready var ui_slider: HSlider = $MarginContainer/VBoxContainer/HBoxContainer2/HSlider  # Изменили sfx на ui
@onready var back_button: Button = $MarginContainer/VBoxContainer/HBoxContainer5/BackButton

const SETTINGS_SCENE_PATH = "res://Scenes/MainMenu/MainMenu.tscn"

func _ready():
	# Инициализация слайдера музыки
	if music_slider:
		# Настраиваем диапазон слайдера (0-100 для процентов)
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
		
		# Загружаем громкость из глобальных переменных
		load_music_volume()
		
		# Подключаем сигнал изменения
		music_slider.value_changed.connect(_on_music_slider_changed)
		ui_slider.drag_ended.connect(_on_ui_slider_drag_ended)

	else:
		print("⚠️ music_slider не найден! Проверь путь к ноду.")
	
	# Инициализация слайдера UI звуков
	if ui_slider:
		# Настраиваем диапазон слайдера (0-100 для процентов)
		ui_slider.min_value = 0
		ui_slider.max_value = 100
		ui_slider.step = 1
		
		# Загружаем громкость UI из глобальных переменных
		load_ui_volume()
		
		# Подключаем сигнал изменения
		ui_slider.value_changed.connect(_on_ui_slider_changed)
	else:
		print("⚠️ ui_slider не найден! Проверь путь к ноду.")	

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
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size_changed.connect(_on_window_resized)

func _on_window_resized():
	print("Размер окна изменен: ", get_tree().root.size)
	
func _on_settings_button_pressed() -> void:
	MusicManager.instance.play_button_click()  # Используем instance напрямую
	transition_to(SETTINGS_SCENE_PATH)
	
# Обработка изменения слайдера музыки
func _on_music_slider_changed(value: float):
	# Преобразуем проценты в децибелы
	# 0% = -40 dB (тишина), 100% = 0 dB (максимум)
	var volume_db = remap(value, 0.0, 100.0, -40.0, 0.0)
	
	# Устанавливаем громкость через MusicManager
	if MusicManager.instance:
		MusicManager.instance.set_music_volume(volume_db)
		print("Громкость музыки изменена: ", value, "% (", volume_db, " dB)")
	else:
		print("⚠️ MusicManager не доступен, не удалось изменить громкость")

# Обработка изменения слайдера UI звуков
func _on_ui_slider_changed(value: float):
	# Преобразуем проценты в децибелы
	# 0% = -40 dB (тишина), 100% = 0 dB (максимум)
	var volume_db = remap(value, 0.0, 100.0, -40.0, 0.0)
	
	# Устанавливаем громкость UI через MusicManager
	if MusicManager.instance:
		MusicManager.instance.set_ui_volume(volume_db)
		
		print("Громкость UI звуков изменена: ", value, "% (", volume_db, " dB)")
	else:
		print("⚠️ MusicManager не доступен, не удалось изменить громкость UI")

# Обработка ОТПУСКАНИЯ слайдера UI звуков (новый метод)
func _on_ui_slider_drag_ended(value_changed: bool):
	if value_changed and MusicManager.instance:
		# Проигрываем тестовый звук для демонстрации (только если UI звуки включены)
		if MusicManager.instance.is_ui_enabled:
			MusicManager.instance.play_button_click()
			print("Тестовый звук воспроизведен после изменения слайдера UI")
			
# Сброс настроек звука
func _on_reset_button_pressed():
	# Сбрасываем настройки по умолчанию
	if MusicManager.instance:
		MusicManager.instance.reset_audio_settings()
		
		# Обновляем слайдеры
		load_music_volume()
		load_ui_volume()
		
		print("Настройки звука сброшены к значениям по умолчанию")
	else:
		print("⚠️ MusicManager не доступен, не удалось сбросить настройки")

func transition_to(scene_path: String):
	color_rect.visible = true
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
	get_tree().change_scene_to_file(scene_path)
# ===== МУЗЫКА =====

# Загрузка громкости музыки из глобальных переменных
func load_music_volume():
	if music_slider:
		# Проверяем, есть ли доступ к MusicManager
		if MusicManager.instance:
			# Получаем текущую громкость музыки
			var current_volume_db = MusicManager.instance.music_volume
			
			# Преобразуем децибелы в проценты для слайдера
			# -40 dB = 0%, 0 dB = 100%
			var slider_value = remap(current_volume_db, -40.0, 0.0, 0.0, 100.0)
			music_slider.value = slider_value
			
			print("Загружена громкость музыки: ", current_volume_db, " dB (", slider_value, "%)")
		else:
			# Значение по умолчанию если менеджер не доступен
			music_slider.value = 50  # 50% по умолчанию
			print("⚠️ MusicManager не доступен, установлена громкость по умолчанию")


# ===== UI ЗВУКИ =====

# Загрузка громкости UI звуков из глобальных переменных
func load_ui_volume():
	if ui_slider:
		# Проверяем, есть ли доступ к MusicManager
		if MusicManager.instance:
			# Получаем текущую громкость UI звуков
			var current_volume_db = MusicManager.instance.ui_volume
			
			# Преобразуем децибелы в проценты для слайдера
			# -40 dB = 0%, 0 dB = 100%
			var slider_value = remap(current_volume_db, -40.0, 0.0, 0.0, 100.0)
			ui_slider.value = slider_value
			
			print("Загружена громкость UI звуков: ", current_volume_db, " dB (", slider_value, "%)")
		else:
			# Значение по умолчанию если менеджер не доступен
			ui_slider.value = 50  # 50% по умолчанию
			print("⚠️ MusicManager не доступен, установлена громкость UI по умолчанию")

# Получение текущих настроек звука
func get_current_audio_settings():
	if MusicManager.instance:
		return {
			"music_volume": MusicManager.instance.music_volume,
			"sfx_volume": MusicManager.instance.sfx_volume,
			"ui_volume": MusicManager.instance.ui_volume,
			"music_enabled": MusicManager.instance.is_music_enabled,
			"sfx_enabled": MusicManager.instance.is_sfx_enabled,
			"ui_enabled": MusicManager.instance.is_ui_enabled
		}
	else:
		return {
			"music_volume": -10.0,
			"sfx_volume": -5.0,
			"ui_volume": -5.0,
			"music_enabled": true,
			"sfx_enabled": true,
			"ui_enabled": true
		}

# При уходе со сцены
func _exit_tree():
	print("Текущие настройки звука сохранены в глобальных переменных:")
	print(get_current_audio_settings())

# ===== ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ (если нужны) =====

# Установка громкости UI звуков
func set_ui_volume(value: float):
	# Преобразуем проценты в децибелы
	var volume_db = remap(value, 0.0, 100.0, -40.0, 0.0)
	
	if MusicManager.instance:
		MusicManager.instance.set_ui_volume(volume_db)
		print("Громкость UI звуков изменена: ", value, "% (", volume_db, " dB)")

# Включение/выключение музыки
func set_music_enabled(enabled: bool):
	if MusicManager.instance:
		MusicManager.instance.set_music_enabled(enabled)
		print("Музыка включена: ", enabled)

# Включение/выключение SFX
func set_sfx_enabled(enabled: bool):
	if MusicManager.instance:
		MusicManager.instance.set_sfx_enabled(enabled)
		print("SFX включены: ", enabled)
