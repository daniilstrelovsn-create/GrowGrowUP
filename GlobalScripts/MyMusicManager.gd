extends AudioStreamPlayer

class_name MusicManager

# Ссылка на текущий экземпляр (для удобства доступа)
static var instance: MusicManager

# Глобальные переменные для хранения настроек аудио
var GlobalAudio = {
	"music_volume": -10.0,
	"sfx_volume": -5.0,
	"ui_volume": -5.0,
	"is_music_enabled": true,
	"is_sfx_enabled": true,
	"is_ui_enabled": true
}

# Словарь с музыкальными треками
var music_tracks: Dictionary = {
	"main_menu": "res://Music/main_menu.ogg",
	"gameplay": "res://Music/gameplay.ogg",
	"victory": "res://Music/victory.ogg"
}

# Словарь с звуковыми эффектами (можно пополнять по мере разработки)
var sfx_tracks: Dictionary = {
	"button_click": "res://Music/button_click.ogg"
}

# Текущие громкости (ссылки на глобальные переменные)
var music_volume: float:
	get: return GlobalAudio.music_volume
	set(value): GlobalAudio.music_volume = value

var sfx_volume: float:
	get: return GlobalAudio.sfx_volume
	set(value): GlobalAudio.sfx_volume = value

var ui_volume: float:
	get: return GlobalAudio.ui_volume
	set(value): GlobalAudio.ui_volume = value

# Флаги включения (ссылки на глобальные переменные)
var is_music_enabled: bool:
	get: return GlobalAudio.is_music_enabled
	set(value): GlobalAudio.is_music_enabled = value

var is_sfx_enabled: bool:
	get: return GlobalAudio.is_sfx_enabled
	set(value): GlobalAudio.is_sfx_enabled = value

var is_ui_enabled: bool:
	get: return GlobalAudio.is_ui_enabled
	set(value): GlobalAudio.is_ui_enabled = value

# Пул аудиоплееров для звуковых эффектов (чтобы можно было играть несколько одновременно)
var sfx_players: Array[AudioStreamPlayer] = []

# Максимальное количество одновременных SFX плееров
var max_sfx_players: int = 10

func _ready():
	instance = self
	bus = "Music"  # Используем отдельный аудиоканал для музыки
	
	# Инициализируем пул SFX плееров
	_init_sfx_pool()
	
	# Загружаем сохранённые настройки (если нужно сохранять между сессиями)
	_load_audio_settings_from_globals()
	
	# Делаем MusicManager глобальным
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("AudioManager загружен")
	print("Текущая громкость музыки: ", music_volume)

# Инициализация пула SFX плееров
func _init_sfx_pool():
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		sfx_players.append(player)

# Получение свободного SFX плеера
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	# Если все заняты, создаём новый (расширяем пул при необходимости)
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "SFX"
	new_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(new_player)
	sfx_players.append(new_player)
	return new_player

# ===== МУЗЫКА =====

func change_track(track_path: String, fade_duration: float = 0.5):
	if not is_music_enabled:
		return
	
	# Если это уже тот же трек и он играет - ничего не делаем
	if stream != null and stream.resource_path == track_path and playing:
		return
	
	# Плавная смена трека
	if fade_duration > 0 and playing:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -80.0, fade_duration / 2)
		await tween.finished
		stop()
		volume_db = music_volume
	
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
			volume_db = -80.0
			play()
			var tween = create_tween()
			tween.tween_property(self, "volume_db", music_volume, fade_duration / 2)
		else:
			volume_db = music_volume
			play()

func play_track(track_name: String, fade_duration: float = 0.5):
	if music_tracks.has(track_name):
		change_track(music_tracks[track_name], fade_duration)
	else:
		push_error("Трек с именем '%s' не найден" % track_name)
		change_track(track_name, fade_duration)

func play_music(track_name: String = ""):
	if not is_music_enabled:
		return
		
	if track_name != "" and music_tracks.has(track_name):
		play_track(track_name, 0.5)
	elif not playing:
		play()

func fade_out(duration: float = 1.0):
	if playing:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -80.0, duration)
		await tween.finished
		stop()
		volume_db = music_volume

func stop_music():
	stop()

# ===== ЗВУКОВЫЕ ЭФФЕКТЫ =====

# Воспроизведение звукового эффекта
func play_sfx(sfx_name: String, volume_modifier: float = 0.0, pitch_scale: float = 1.0):
	if not is_sfx_enabled or not sfx_tracks.has(sfx_name):
		return
	
	var player = _get_free_sfx_player()
	var sfx_stream = load(sfx_tracks[sfx_name])
	
	if sfx_stream:
		player.stream = sfx_stream
		player.volume_db = sfx_volume + volume_modifier
		player.pitch_scale = pitch_scale
		player.play()

# Воспроизведение UI звука
func play_ui_sound(sfx_name: String, volume_modifier: float = 0.0, pitch_scale: float = 1.0):
	if not is_ui_enabled or not sfx_tracks.has(sfx_name):
		return
	
	var player = _get_free_sfx_player()
	var sfx_stream = load(sfx_tracks[sfx_name])
	
	if sfx_stream:
		player.stream = sfx_stream
		player.volume_db = ui_volume + volume_modifier
		player.pitch_scale = pitch_scale
		player.play()

# Воспроизведение UI звука по прямому пути
func play_ui_sound_path(sfx_path: String, volume_modifier: float = 0.0, pitch_scale: float = 1.0):
	if not is_ui_enabled:
		return
	
	var player = _get_free_sfx_player()
	var sfx_stream = load(sfx_path)
	
	if sfx_stream:
		player.stream = sfx_stream
		player.volume_db = ui_volume + volume_modifier
		player.pitch_scale = pitch_scale
		player.play()

# Быстрое воспроизведение UI звуков (удобные методы)
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

# Добавление нового звука в коллекцию
func add_sfx(sfx_name: String, sfx_path: String):
	sfx_tracks[sfx_name] = sfx_path

# Остановка всех звуковых эффектов
func stop_all_sfx():
	for player in sfx_players:
		player.stop()

# ===== НАСТРОЙКИ ГРОМКОСТИ =====

# Музыка
func set_music_volume(db: float):
	music_volume = db
	volume_db = db if is_music_enabled else -80.0
	print("Громкость музыки установлена: ", db)

func get_music_volume() -> float:
	return music_volume

func set_music_enabled(enabled: bool):
	is_music_enabled = enabled
	if enabled:
		volume_db = music_volume
		if not playing and stream != null:
			play()
	else:
		volume_db = -80.0
	print("Музыка включена: ", enabled)

# Звуковые эффекты (общие)
func set_sfx_volume(db: float):
	sfx_volume = db
	print("Громкость SFX установлена: ", db)

func get_sfx_volume() -> float:
	return sfx_volume

func set_sfx_enabled(enabled: bool):
	is_sfx_enabled = enabled
	print("SFX включены: ", enabled)

# UI звуки
func set_ui_volume(db: float):
	ui_volume = db
	print("Громкость UI установлена: ", db)

func get_ui_volume() -> float:
	return ui_volume

func set_ui_enabled(enabled: bool):
	is_ui_enabled = enabled
	print("UI звуки включены: ", enabled)

# Общие настройки громкости (для совместимости со старым кодом)
func set_volume(db: float):
	set_music_volume(db)

func get_volume() -> float:
	return get_music_volume()

# ===== РАБОТА С ГЛОБАЛЬНЫМИ ПЕРЕМЕННЫМИ =====

# Функция для загрузки настроек из глобальных переменных
func _load_audio_settings_from_globals():
	# Здесь мы просто обновляем локальные ссылки
	# Фактические значения уже хранятся в глобальных переменных
	volume_db = music_volume if is_music_enabled else -80.0
	print("Настройки аудио загружены из глобальных переменных")

# Синхронизация настроек с глобальными переменными (если нужно)
func sync_with_globals():
	# Обновляем аудио плеер в соответствии с текущими глобальными значениями
	volume_db = music_volume if is_music_enabled else -80.0
	print("Аудио менеджер синхронизирован с глобальными переменными")

# ===== ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ =====

# Сброс всех настроек к значениям по умолчанию
func reset_audio_settings():
	GlobalAudio.music_volume = -10.0
	GlobalAudio.sfx_volume = -5.0
	GlobalAudio.ui_volume = -5.0
	GlobalAudio.is_music_enabled = true
	GlobalAudio.is_sfx_enabled = true
	GlobalAudio.is_ui_enabled = true
	
	volume_db = music_volume
	print("Аудио настройки сброшены к значениям по умолчанию")

# Получение состояния всех настроек
func get_audio_settings() -> Dictionary:
	return {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ui_volume": ui_volume,
		"is_music_enabled": is_music_enabled,
		"is_sfx_enabled": is_sfx_enabled,
		"is_ui_enabled": is_ui_enabled
	}

# Для ручной настройки loop
func set_stream_loop(should_loop: bool):
	if stream is AudioStreamOggVorbis:
		stream.loop = should_loop
	elif stream is AudioStreamWAV:
		if should_loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
