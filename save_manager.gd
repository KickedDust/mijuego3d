extends Node

signal save_state_changed

const SAVE_PATH := "user://savegame.save"

var _pending_load := false

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func request_load() -> void:
    _pending_load = true

func consume_pending_load() -> bool:
    var should_load := _pending_load
    _pending_load = false
    return should_load

func request_new_game() -> void:
    _pending_load = false

func save_game_state(data: Dictionary) -> bool:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("[SaveManager] No se pudo abrir el archivo de guardado para escritura.")
        return false
    file.store_var(data, true)
    file.close()
    emit_signal("save_state_changed")
    return true

func load_game_state() -> Dictionary:
    if not has_save():
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("[SaveManager] No se pudo abrir el archivo de guardado para lectura.")
        return {}
    var data := file.get_var()
    file.close()
    return data

func clear_save() -> void:
    if has_save():
        var err := DirAccess.remove_absolute(SAVE_PATH)
        if err != OK:
            push_warning("[SaveManager] No se pudo eliminar el archivo de guardado.")
        emit_signal("save_state_changed")
