extends AudioStreamPlayer

class_name MusicManager

# Ссылка на текущий экземпляр (для удобства доступа)
static var instance: MusicManager

# Словарь с треками (опционально, для удобства)
var tracks: Dictionary = {
	"main_menu": "res://Music/main_menu.ogg",
	"gameplay": "res://Music/gameplay.ogg",
	"victory": "res://Music/victory.ogg"
}

# Текущая громкость по умолчанию
var current_volume: float = -10.0

func _ready():
	instance = self
	# Важные настройки
	bus = "Music"  # Используем отдельный аудиоканал
	
	# Загружаем сохранённую громкость, если есть
	load_volume()
	
	# Делаем MusicManager глобальным (не удаляется при смене сцен)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("MusicManager загружен")

# Функция для смены трека
func change_track(track_path: String, fade_duration: float = 0.5):
	# Если это уже тот же трек и он играет - ничего не делаем
	if stream != null and stream.resource_path == track_path and playing:
		return
	
	# Плавная смена трека
	if fade_duration > 0 and playing:
		# Плавно убавляем старый трек
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -80.0, fade_duration / 2)
		await tween.finished
		stop()
		volume_db = current_volume  # Возвращаем сохранённую громкость
	
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
			volume_db = -80.0  # Начинаем с тишины
			play()
			var tween = create_tween()
			tween.tween_property(self, "volume_db", current_volume, fade_duration / 2)
		else:
			volume_db = current_volume
			play()

# Функция для смены трека по названию
func play_track(track_name: String, fade_duration: float = 0.5):
	if tracks.has(track_name):
		change_track(tracks[track_name], fade_duration)
	else:
		push_error("Трек с именем '%s' не найден" % track_name)
		# Попробуем загрузить напрямую по пути
		change_track(track_name, fade_duration)

# Простая функция для запуска трека (без смены, если уже играет)
func play_music(track_name: String = ""):
	if track_name != "" and tracks.has(track_name):
		play_track(track_name, 0.5)
	elif not playing:
		play()

# Плавная остановка
func fade_out(duration: float = 1.0):
	if playing:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -80.0, duration)
		await tween.finished
		stop()
		volume_db = current_volume  # Сбрасываем громкость

# Быстрая остановка
func stop_music():
	stop()

# Настройка громкости
func set_volume(db: float):
	current_volume = db
	volume_db = db
	save_volume()

# Получение текущей громкости
func get_volume() -> float:
	return current_volume

# Сохранение громкости в ConfigFile
func save_volume():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", current_volume)
	config.save("user://audio_settings.cfg")

# Загрузка громкости из ConfigFile
func load_volume():
	var config = ConfigFile.new()
	var error = config.load("user://audio_settings.cfg")
	
	if error == OK:  # Если файл существует
		current_volume = config.get_value("audio", "music_volume", -10.0)
	else:  # Если файла нет - используем значение по умолчанию
		current_volume = -10.0
		save_volume()  # Создаём файл с настройками по умолчанию
	
	volume_db = current_volume

# Включение/выключение музыки
func set_music_enabled(enabled: bool):
	if enabled:
		volume_db = current_volume
		if not playing and stream != null:
			play()
	else:
		volume_db = -80.0  # Полностью выключаем

# Для ручной настройки loop (если нужно)
func set_stream_loop(should_loop: bool):
	if stream is AudioStreamOggVorbis:
		stream.loop = should_loop
	elif stream is AudioStreamWAV:
		if should_loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
