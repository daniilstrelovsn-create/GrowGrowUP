extends AudioStreamPlayer

class_name MusicManager

# Ссылка на текущий экземпляр (для удобства доступа)
static var instance: MusicManager

# Глобальные переменные для хранения настроек аудио
var GlobalAudio = {
	"max_volume_db": 0.0,      # Максимальная громкость (0 dB = максимум, -40 dB = тишина)
	"music_volume": -10.0,     # Относительная громкость музыки
	"ui_volume": -15.0,        # Относительная громкость UI звуков
	"is_music_enabled": true,
	"is_ui_enabled": true
}

# Словарь с музыкальными треками
var music_tracks: Dictionary = {
	"main_menu": "res://Music/main_menu.ogg",
	"main_game": "res://Music/main_game.ogg"
}

# Словарь с UI звуками
var ui_sounds: Dictionary = {
	"button_click": "res://Music/button_click.ogg"
}

# Текущие громкости (ссылки на глобальные переменные)
var max_volume_db: float:
	get: return GlobalAudio.max_volume_db
	set(value): 
		GlobalAudio.max_volume_db = clamp(value, -40.0, 0.0)
		_apply_max_volume_to_all()

var music_volume: float:
	get: return GlobalAudio.music_volume
	set(value): 
		GlobalAudio.music_volume = value
		_apply_music_volume()

var ui_volume: float:
	get: return GlobalAudio.ui_volume
	set(value): 
		GlobalAudio.ui_volume = value
		# UI volume применяется при следующем воспроизведении звука

# Флаги включения (ссылки на глобальные переменные)
var is_music_enabled: bool:
	get: return GlobalAudio.is_music_enabled
	set(value): 
		GlobalAudio.is_music_enabled = value
		_apply_music_enabled()
		# Сохраняем состояние в глобальные переменные
		GlobalAudio.is_music_enabled = value

var is_ui_enabled: bool:
	get: return GlobalAudio.is_ui_enabled
	set(value): 
		GlobalAudio.is_ui_enabled = value
		# Сохраняем состояние в глобальные переменные
		GlobalAudio.is_ui_enabled = value

# Пул аудиоплееров для UI звуков (чтобы можно было играть несколько одновременно)
var ui_players: Array[AudioStreamPlayer] = []

# Максимальное количество одновременных UI плееров
var max_ui_players: int = 10

func _ready():
	instance = self
	bus = "Music"  # Используем отдельный аудиоканал для музыки
	
	# Инициализируем пул UI плееров
	_init_ui_pool()
	
	# Загружаем сохранённые настройки
	_load_audio_settings_from_globals()
	
	# Делаем MusicManager глобальным
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("AudioManager загружен")
	print("Музыка включена: ", is_music_enabled)
	print("UI звуки включены: ", is_ui_enabled)
	print("Текущая громкость музыки: ", get_actual_music_volume())
	print("Текущая громкость UI: ", get_actual_ui_volume())

# Инициализация пула UI плееров
func _init_ui_pool():
	for i in range(max_ui_players):
		var player = AudioStreamPlayer.new()
		player.bus = "UI"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		ui_players.append(player)

# Получение свободного UI плеера
func _get_free_ui_player() -> AudioStreamPlayer:
	for player in ui_players:
		if not player.playing:
			return player
	
	# Если все заняты, создаём новый (расширяем пул при необходимости)
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "UI"
	new_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(new_player)
	ui_players.append(new_player)
	return new_player

# ===== МАКСИМАЛЬНАЯ ГРОМКОСТЬ =====

# Установка максимальной громкости в dB (от -40 до 0)
func set_max_volume_db(db: float):
	max_volume_db = db
	print("Максимальная громкость установлена: ", db, " dB")

# Получение максимальной громкости
func get_max_volume_db() -> float:
	return max_volume_db

# Применение максимальной громкости ко всем звукам
func _apply_max_volume_to_all():
	# Применяем к музыке
	_apply_music_enabled()
	
	# Применяем ко всем активным UI плеерам
	_update_all_ui_players_volume()

# Обновление громкости всех активных UI плееров
func _update_all_ui_players_volume():
	for player in ui_players:
		if player.playing:
			player.volume_db = get_actual_ui_volume()

# Рассчет фактической громкости на основе максимальной
func _calculate_actual_volume(relative_db: float) -> float:
	# Если выключено - полная тишина
	if relative_db <= -40.0:
		return -40.0
	
	# Вычисляем фактическую громкость: max_volume_db + relative_db
	# Пример: max_volume_db = -10, relative_db = -10 → фактическая = -20 dB
	var actual_db = max_volume_db + relative_db
	
	# Ограничиваем минимальной громкостью
	return max(actual_db, -40.0)

# Получение фактической громкости музыки
func get_actual_music_volume() -> float:
	if not is_music_enabled:
		return -40.0
	return _calculate_actual_volume(music_volume)

# Получение фактической громкости UI звуков
func get_actual_ui_volume() -> float:
	if not is_ui_enabled:
		return -40.0
	return _calculate_actual_volume(ui_volume)

# ===== МУЗЫКА =====

# Применение настроек музыки
func _apply_music_volume():
	if is_music_enabled:
		volume_db = get_actual_music_volume()
	else:
		volume_db = -40.0

func _apply_music_enabled():
	if is_music_enabled:
		volume_db = get_actual_music_volume()
		# Не запускаем автоматически музыку при включении
		# Пусть это делает логика игры
	else:
		volume_db = -40.0
		# Останавливаем музыку если она играет
		if playing:
			stop()

func change_track(track_path: String, fade_duration: float = 0.5):
	if not is_music_enabled:
		print("Попытка сменить трек, но музыка выключена")
		return
	
	# Если это уже тот же трек и он играет - ничего не делаем
	if stream != null and stream.resource_path == track_path and playing:
		return
	
	# Плавная смена трека
	if fade_duration > 0 and playing:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -40.0, fade_duration / 2)
		await tween.finished
		stop()
		volume_db = get_actual_music_volume()
	
	# Загружаем и запускаем новый трек
	var new_stream = load(track_path)
	if new_stream:
		# Для OGG файлов устанавливаем loop_mode
		if new_stream is AudioStreamOggVorbis:
			new_stream.loop = true
		# Для WAV файлов тоже можно установить loop
		elif new_stream is AudioStreamWAV:
			new_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		
		stream = new_stream
		
		if fade_duration > 0:
			volume_db = -40.0
			play()
			var tween = create_tween()
			tween.tween_property(self, "volume_db", get_actual_music_volume(), fade_duration / 2)
		else:
			volume_db = get_actual_music_volume()
			play()

func play_track(track_name: String, fade_duration: float = 0.5):
	if music_tracks.has(track_name):
		change_track(music_tracks[track_name], fade_duration)
	else:
		push_error("Трек с именем '%s' не найден" % track_name)
		change_track(track_name, fade_duration)

func play_music(track_name: String = ""):
	if not is_music_enabled:
		print("Попытка запустить музыку, но музыка выключена")
		return
		
	if track_name != "" and music_tracks.has(track_name):
		play_track(track_name, 0.5)
	elif not playing and stream != null:
		play()

func fade_out(duration: float = 1.0):
	if playing:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -40.0, duration)
		await tween.finished
		stop()
		volume_db = get_actual_music_volume()

func stop_music():
	stop()

# ===== UI ЗВУКИ =====

# Применение настроек UI звуков
func _apply_ui_volume():
	# Обновляем громкость всех активных UI плееров
	_update_all_ui_players_volume()

# Воспроизведение UI звука по имени из словаря
func play_ui_sound(ui_name: String, volume_modifier: float = 0.0, pitch_scale: float = 1.0):
	if not is_ui_enabled:
		print("Попытка воспроизвести UI звук, но UI звуки выключены: ", ui_name)
		return
	
	if not ui_sounds.has(ui_name):
		print("UI звук не найден: ", ui_name)
		return
	
	var player = _get_free_ui_player()
	var ui_stream = load(ui_sounds[ui_name])
	
	if ui_stream:
		player.stream = ui_stream
		# Применяем максимальную громкость к UI звукам
		player.volume_db = get_actual_ui_volume() + volume_modifier
		player.pitch_scale = pitch_scale
		player.play()
		print("UI звук '", ui_name, "' воспроизведен с громкостью: ", player.volume_db, " dB")

# Воспроизведение UI звука по прямому пути
func play_ui_sound_path(ui_path: String, volume_modifier: float = 0.0, pitch_scale: float = 1.0):
	if not is_ui_enabled:
		return
	
	var player = _get_free_ui_player()
	var ui_stream = load(ui_path)
	
	if ui_stream:
		player.stream = ui_stream
		# Применяем максимальную громкость к UI звукам
		player.volume_db = get_actual_ui_volume() + volume_modifier
		player.pitch_scale = pitch_scale
		player.play()

# Быстрое воспроизведение UI звуков
func play_button_click():
	play_ui_sound("button_click")

func play_button_hover():
	play_ui_sound("button_hover")

func play_button_select():
	play_ui_sound("select")

func play_button_back():
	play_ui_sound("back")

func play_button_confirm():
	play_ui_sound("confirm")

func play_notification():
	play_ui_sound("notification")

func play_achievement():
	play_ui_sound("achievement")

func play_pause():
	play_ui_sound("pause")

func play_unpause():
	play_ui_sound("unpause")

# Добавление нового UI звука в коллекцию
func add_ui_sound(ui_name: String, ui_path: String):
	ui_sounds[ui_name] = ui_path

# Остановка всех UI звуков
func stop_all_ui_sounds():
	for player in ui_players:
		player.stop()

# ===== НАСТРОЙКИ ГРОМКОСТИ =====

# Максимальная громкость (главный регулятор)
func set_max_volume(db: float):
	set_max_volume_db(db)

func get_max_volume() -> float:
	return get_max_volume_db()

# Музыка
func set_music_volume(db: float):
	music_volume = db
	print("Относительная громкость музыки установлена: ", db, " dB")

func get_music_volume() -> float:
	return music_volume

func set_music_enabled(enabled: bool):
	is_music_enabled = enabled
	print("Музыка включена: ", enabled)
	# Сохраняем в глобальные переменные
	GlobalAudio.is_music_enabled = enabled

# UI звуки
func set_ui_volume(db: float):
	ui_volume = db
	print("Относительная громкость UI звуков установлена: ", db, " dB")
	_apply_ui_volume()  # Обновляем громкость активных UI звуков

func get_ui_volume() -> float:
	return ui_volume

func set_ui_enabled(enabled: bool):
	is_ui_enabled = enabled
	print("UI звуки включены: ", enabled)
	# Сохраняем в глобальные переменные
	GlobalAudio.is_ui_enabled = enabled

# Совместимость со старым кодом
func set_volume(db: float):
	set_music_volume(db)

func get_volume() -> float:
	return get_music_volume()

# ===== РАБОТА С ГЛОБАЛЬНЫМИ ПЕРЕМЕННЫМИ =====

func _load_audio_settings_from_globals():
	# Применяем все настройки
	_apply_music_enabled()  # Применяем состояние музыки
	print("Настройки аудио загружены из глобальных переменных")
	print("Музыка включена: ", is_music_enabled)
	print("UI звуки включены: ", is_ui_enabled)

func sync_with_globals():
	_apply_max_volume_to_all()
	print("Аудио менеджер синхронизирован с глобальными переменными")

# ===== ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ =====

# Сброс всех настроек к значениям по умолчанию
func reset_audio_settings():
	GlobalAudio.max_volume_db = 0.0
	GlobalAudio.music_volume = -10.0
	GlobalAudio.ui_volume = -15.0
	GlobalAudio.is_music_enabled = true
	GlobalAudio.is_ui_enabled = true
	
	_apply_max_volume_to_all()
	print("Аудио настройки сброшены к значениям по умолчанию")

# Получение состояния всех настроек
func get_audio_settings() -> Dictionary:
	return {
		"max_volume_db": max_volume_db,
		"music_volume": music_volume,
		"ui_volume": ui_volume,
		"is_music_enabled": is_music_enabled,
		"is_ui_enabled": is_ui_enabled,
		"actual_music_volume": get_actual_music_volume(),
		"actual_ui_volume": get_actual_ui_volume()
	}

# Настройка зацикливания
func set_stream_loop(should_loop: bool):
	if stream is AudioStreamOggVorbis:
		stream.loop = should_loop
	elif stream is AudioStreamWAV:
		if should_loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

# Тестирование уровней громкости
func test_volume_levels():
	print("\n=== ТЕСТ ГРОМКОСТИ ===")
	print("Максимальная громкость: ", max_volume_db, " dB")
	print("Относительная громкость музыки: ", music_volume, " dB")
	print("Фактическая громкость музыки: ", get_actual_music_volume(), " dB")
	print("Относительная громкость UI: ", ui_volume, " dB")
	print("Фактическая громкость UI: ", get_actual_ui_volume(), " dB")
	print("Музыка включена: ", is_music_enabled)
	print("UI звуки включены: ", is_ui_enabled)
	print("========================\n")

# Воспроизведение тестового звука для проверки
func play_test_sound():
	if ui_sounds.has("button_click"):
		play_ui_sound("button_click")
		print("Тестовый звук воспроизведен для проверки громкости")

# Проверка, можно ли воспроизводить музыку
func can_play_music() -> bool:
	return is_music_enabled and max_volume_db > -40 and music_volume > -40

# Проверка, можно ли воспроизводить UI звуки
func can_play_ui() -> bool:
	return is_ui_enabled and max_volume_db > -40 and ui_volume > -40
