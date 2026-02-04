extends Control 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var master_sounds_slider: HSlider = $MarginContainer/VBoxContainer/MasterSoundsHBox/MasterSoundsHSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/MusicHBox/MusicHSlider
@onready var ui_slider: HSlider = $MarginContainer/VBoxContainer/UISoundsHBox/UISoundHSlider
@onready var reset_button: Button = $MarginContainer/VBoxContainer/ButtinsHBox/ResetButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtinsHBox/BackButton

const SETTINGS_SCENE_PATH = "res://Scenes/MainMenu/MainMenu.tscn"

# Кэш предыдущих значений для определения изменений
var previous_music_value: float = 0.0
var previous_ui_value: float = 0.0

func _ready():
	# Инициализация мастер слайдера громкости
	if master_sounds_slider:
		# Настраиваем диапазон слайдера (-40 до 0 dB)
		master_sounds_slider.min_value = -40
		master_sounds_slider.max_value = 0
		master_sounds_slider.step = 1
		
		# Загружаем мастер-громкость из глобальных переменных
		load_master_volume()
		
		# Подключаем сигнал изменения
		master_sounds_slider.value_changed.connect(_on_master_slider_changed)
	else:
		print("⚠️ master_sounds_slider не найден! Проверь путь к ноду.")
	
	# Инициализация слайдера музыки
	if music_slider:
		# Настраиваем диапазон слайдера (0-100 для процентов)
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
		
		# Загружаем громкость из глобальных переменных
		load_music_volume()
		previous_music_value = music_slider.value
		
		# Подключаем сигнал изменения
		music_slider.value_changed.connect(_on_music_slider_changed)
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
		previous_ui_value = ui_slider.value
		
		# Подключаем сигнал изменения
		ui_slider.value_changed.connect(_on_ui_slider_changed)
		ui_slider.drag_ended.connect(_on_ui_slider_drag_ended)
	else:
		print("⚠️ ui_slider не найден! Проверь путь к ноду.")

	if back_button:
		back_button.pressed.connect(_on_settings_button_pressed)
	else:
		print("⚠️ back_button не найден! Проверь путь к ноду.")
		
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	else:
		print("⚠️ back_button не найден! Проверь путь к ноду.")
		
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
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size_changed.connect(_on_window_resized)

func _on_window_resized():
	print("Размер окна изменен: ", get_tree().root.size)
	
func _on_settings_button_pressed() -> void:
	if MusicManager.instance:
		MusicManager.instance.play_button_click()
	
	# Сохраняем состояние перед переходом
	_apply_music_state_based_on_volume()
	_apply_ui_state_based_on_volume()
	
	# Обновляем глобальные переменные
	if MusicManager.instance:
		MusicManager.instance.sync_with_globals()
	
	transition_to(SETTINGS_SCENE_PATH)

# ===== МАКСИМАЛЬНАЯ ГРОМКОСТЬ =====

# Обработка изменения мастер слайдера
func _on_master_slider_changed(value: float):
	# Устанавливаем максимальную громкость через MusicManager
	if MusicManager.instance:
		MusicManager.instance.set_max_volume_db(value)
		print("Максимальная громкость изменена: ", value, " dB")
		
		# Обновляем состояние музыки и UI звуков на основе текущих значений
		_update_all_audio_states()
	else:
		print("⚠️ MusicManager не доступен, не удалось изменить громкость")

# Загрузка максимальной громкости из глобальных переменных
func load_master_volume():
	if master_sounds_slider:
		# Проверяем, есть ли доступ к MusicManager
		if MusicManager.instance:
			# Получаем текущую максимальную громкость
			var current_max_volume = MusicManager.instance.get_max_volume_db()
			master_sounds_slider.value = current_max_volume
			print("Загружена максимальная громкость: ", current_max_volume, " dB")
		else:
			# Значение по умолчанию если менеджер не доступен
			master_sounds_slider.value = 0.0  # 0 dB по умолчанию
			print("⚠️ MusicManager не доступен, установлена громкость по умолчанию")

# ===== МУЗЫКА =====

# Обработка изменения слайдера музыки
func _on_music_slider_changed(value: float):
	# Преобразуем проценты в децибелы
	# 0% = -40 dB (минимальная относительная громкость), 100% = 0 dB (максимальная относительная)
	var volume_db = remap(value, 0.0, 100.0, -40.0, 0.0)
	
	# Устанавливаем относительную громкость музыки
	if MusicManager.instance:
		MusicManager.instance.set_music_volume(volume_db)
		print("Относительная громкость музыки изменена: ", value, "% (", volume_db, " dB)")
		
		# Применяем состояние музыки на основе новой громкости
		_apply_music_state_based_on_volume()
		
		previous_music_value = value
		
		# Дополнительная проверка: если музыка была выключена, но теперь громкость > 0, включаем её
		if value > 0 and not MusicManager.instance.GlobalAudio.is_music_enabled:
			MusicManager.instance.GlobalAudio.is_music_enabled = true
			print("Музыка принудительно включена (слайдер > 0%)")
	else:
		print("⚠️ MusicManager не доступен, не удалось изменить громкость")

# Загрузка громкости музыки из глобальных переменных
func load_music_volume():
	if music_slider:
		# Проверяем, есть ли доступ к MusicManager
		if MusicManager.instance:
			# Получаем текущую относительную громкость музыки
			var current_volume_db = MusicManager.instance.music_volume
			
			# Преобразуем децибелы в проценты для слайдера
			# -40 dB = 0%, 0 dB = 100%
			var slider_value = remap(current_volume_db, -40.0, 0.0, 0.0, 100.0)
			music_slider.value = slider_value
			previous_music_value = slider_value
			
			print("Загружена относительная громкость музыки: ", current_volume_db, " dB (", slider_value, "%)")
			
			# Применяем состояние на основе загруженных значений
			_apply_music_state_based_on_volume()
		else:
			# Значение по умолчанию если менеджер не доступен
			music_slider.value = 75  # 75% = -10 dB по умолчанию
			previous_music_value = 75
			print("⚠️ MusicManager не доступен, установлена громкость по умолчанию")

# Применение состояния музыки на основе громкости
func _apply_music_state_based_on_volume():
	if not MusicManager.instance:
		return
	
	var current_slider_value = music_slider.value
	var master_volume = MusicManager.instance.get_max_volume_db()
	
	# Если слайдер музыки на 0% ИЛИ мастер громкость на -40 dB
	if current_slider_value <= 0 or master_volume <= -40:
		# Останавливаем музыку если она играет
		if MusicManager.instance.playing:
			MusicManager.instance.stop()
			print("Музыка остановлена (громкость 0% или мастер громкость -40 dB)")
		
		# Устанавливаем флаг выключения
		MusicManager.instance.GlobalAudio.is_music_enabled = false
	else:
		# Если громкость больше 0 и мастер громкость больше -40, включаем музыку
		if current_slider_value > 0 and master_volume > -40:
			# Устанавливаем флаг включения
			MusicManager.instance.GlobalAudio.is_music_enabled = true
			print("Музыка включена (громкость > 0% и мастер громкость > -40 dB)")
			
			# Запускаем музыку если она не играет и поток загружен
			if not MusicManager.instance.playing and MusicManager.instance.stream != null:
				MusicManager.instance.play()
				print("Музыка запущена")
			elif not MusicManager.instance.playing:
				print("Поток музыки не загружен, музыка не может быть запущена")

# ===== UI ЗВУКИ =====

# Обработка изменения слайдера UI звуков
func _on_ui_slider_changed(value: float):
	# Преобразуем проценты в децибелы
	# 0% = -40 dB (минимальная относительная громкость), 100% = 0 dB (максимальная относительная)
	var volume_db = remap(value, 0.0, 100.0, -40.0, 0.0)
	
	# Устанавливаем относительную громкость UI звуков
	if MusicManager.instance:
		MusicManager.instance.set_ui_volume(volume_db)
		print("Относительная громкость UI звуков изменена: ", value, "% (", volume_db, " dB)")
		
		# Применяем состояние UI звуков на основе новой громкости
		_apply_ui_state_based_on_volume()
		
		previous_ui_value = value
		
		# Дополнительная проверка: если UI звуки были выключены, но теперь громкость > 0, включаем их
		if value > 0 and not MusicManager.instance.GlobalAudio.is_ui_enabled:
			MusicManager.instance.GlobalAudio.is_ui_enabled = true
			print("UI звуки принудительно включены (слайдер > 0%)")
	else:
		print("⚠️ MusicManager не доступен, не удалось изменить громкость UI")

# Обработка ОТПУСКАНИЯ слайдера UI звуков
func _on_ui_slider_drag_ended(value_changed: bool):
	if value_changed and MusicManager.instance:
		_update_all_audio_states()
		# Проигрываем тестовый звук для демонстрации только если UI звуки включены и громкость > 0
		if MusicManager.instance.is_ui_enabled and ui_slider.value > 0:
			MusicManager.instance.play_button_click()
			print("Тестовый звук воспроизведен после изменения слайдера UI")

# Загрузка громкости UI звуков из глобальных переменных
func load_ui_volume():
	if ui_slider:
		# Проверяем, есть ли доступ к MusicManager
		if MusicManager.instance:
			# Получаем текущую относительную громкость UI звуков
			var current_volume_db = MusicManager.instance.ui_volume
			
			# Преобразуем децибелы в проценты для слайдера
			# -40 dB = 0%, 0 dB = 100%
			var slider_value = remap(current_volume_db, -40.0, 0.0, 0.0, 100.0)
			ui_slider.value = slider_value
			previous_ui_value = slider_value
			
			print("Загружена относительная громкость UI звуков: ", current_volume_db, " dB (", slider_value, "%)")
			
			# Применяем состояние на основе загруженных значений
			_apply_ui_state_based_on_volume()
		else:
			# Значение по умолчанию если менеджер не доступен
			ui_slider.value = 87.5  # 87.5% = -5 dB по умолчанию
			previous_ui_value = 87.5
			print("⚠️ MusicManager не доступен, установлена громкость UI по умолчанию")

# Применение состояния UI звуков на основе громкости
func _apply_ui_state_based_on_volume():
	if not MusicManager.instance:
		return
	
	var current_slider_value = ui_slider.value
	var master_volume = MusicManager.instance.get_max_volume_db()
	
	# Если слайдер UI на 0% ИЛИ мастер громкость на -40 dB
	if current_slider_value <= 0 or master_volume <= -40:
		# Устанавливаем флаг выключения
		MusicManager.instance.GlobalAudio.is_ui_enabled = false
		print("UI звуки выключены (громкость 0% или мастер громкость -40 dB)")
	else:
		# Если громкость больше 0 и мастер громкость больше -40, включаем UI звуки
		if current_slider_value > 0 and master_volume > -40:
			# Устанавливаем флаг включения
			MusicManager.instance.GlobalAudio.is_ui_enabled = true
			print("UI звуки включены (громкость > 0% и мастер громкость > -40 dB)")

# ===== ОБНОВЛЕНИЕ ВСЕХ АУДИО СОСТОЯНИЙ =====

func _update_all_audio_states():
	_apply_music_state_based_on_volume()
	_apply_ui_state_based_on_volume()

# ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====

# Сброс настроек звука (если у тебя есть кнопка Reset)
func _on_reset_button_pressed():	
	# Сбрасываем настройки по умолчанию
	if MusicManager.instance:
		MusicManager.instance.reset_audio_settings()
		
		# Обновляем слайдеры
		load_master_volume()
		load_music_volume()
		load_ui_volume()
		
		# Применяем состояния
		_update_all_audio_states()
		
		print("Настройки звука сброшены к значениям по умолчанию")
	else:
		print("⚠️ MusicManager не доступен, не удалось сбросить настройки")
	
	if MusicManager.instance:
		MusicManager.instance.play_button_click()

# Получение текущих настроек звука
func get_current_audio_settings():
	if MusicManager.instance:
		var settings = MusicManager.instance.get_audio_settings()
		return {
			"max_volume_db": settings.max_volume_db,
			"music_volume": settings.music_volume,
			"ui_volume": settings.ui_volume,
			"music_enabled": settings.is_music_enabled,
			"ui_enabled": settings.is_ui_enabled,
			"actual_music_volume": settings.actual_music_volume,
			"actual_ui_volume": settings.actual_ui_volume
		}
	else:
		return {
			"max_volume_db": 0.0,
			"music_volume": -10.0,
			"ui_volume": -15.0,
			"music_enabled": true,
			"ui_enabled": true,
			"actual_music_volume": -10.0,
			"actual_ui_volume": -15.0
		}

# При уходе со сцены
func _exit_tree():
	print("Текущие настройки звука сохранены в глобальных переменных:")
	print(get_current_audio_settings())

# ===== СМЕНА СЦЕНЫ =====

func transition_to(scene_path: String):
	color_rect.visible = true
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
	get_tree().change_scene_to_file(scene_path)

# ===== ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ =====

# Обновление всех слайдеров
func refresh_all_sliders():
	load_master_volume()
	load_music_volume()
	load_ui_volume()
	print("Все слайдеры обновлены")

# Тестирование уровней громкости
func test_volume_levels():
	if MusicManager.instance:
		MusicManager.instance.test_volume_levels()
	else:
		print("⚠️ MusicManager не доступен для тестирования")

# Отображение информации о фактической громкости
func show_actual_volumes():
	if MusicManager.instance:
		print("\n=== ФАКТИЧЕСКАЯ ГРОМКОСТЬ ===")
		print("Максимальная громкость: ", MusicManager.instance.max_volume_db, " dB")
		print("Относительная громкость музыки: ", MusicManager.instance.music_volume, " dB")
		print("Фактическая громкость музыки: ", MusicManager.instance.get_actual_music_volume(), " dB")
		print("Относительная громкость UI: ", MusicManager.instance.ui_volume, " dB")
		print("Фактическая громкость UI: ", MusicManager.instance.get_actual_ui_volume(), " dB")
		print("Музыка включена: ", MusicManager.instance.is_music_enabled)
		print("UI звуки включены: ", MusicManager.instance.is_ui_enabled)
		print("============================\n")
