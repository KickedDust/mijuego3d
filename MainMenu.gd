extends Control
class_name MainMenu

## Gestiona las interacciones del menú principal y el menú de pausa.
@export var pause_mode := false

const SAVE_MANAGER_PATH := "/root/SaveManager"

var _game: Game = null
var _save_manager: Node = null

@onready var _continue_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContinueButton
@onready var _save_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var _new_game_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/NewGameButton

func _ready() -> void:
    _save_manager = get_node_or_null(SAVE_MANAGER_PATH)
    if _save_manager == null:
        push_error("[MainMenu] No se encontró el autoload SaveManager en %s." % SAVE_MANAGER_PATH)
    if pause_mode:
        process_mode = Node.PROCESS_MODE_WHEN_PAUSED
        _game = get_tree().get_first_node_in_group("game_controller") as Game
    elif _save_manager != null and _save_manager.has_signal("save_state_changed"):
        _save_manager.save_state_changed.connect(_on_save_state_changed)
    _update_buttons()
    focus_default()

func set_game(game: Game) -> void:
    pause_mode = true
    _game = game
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    _update_buttons()

func focus_default() -> void:
    if not is_visible_in_tree():
        return
    if pause_mode or not _continue_button.disabled:
        _continue_button.grab_focus()
    else:
        _new_game_button.grab_focus()

func _update_buttons() -> void:
    if pause_mode:
        var can_interact := _game != null
        _continue_button.disabled = not can_interact
        _save_button.disabled = not can_interact
    else:
        var has_save := _save_manager_has_method("has_save") and _save_manager.has_save()
        _continue_button.disabled = not has_save
        _save_button.disabled = true

func _on_continue_button_pressed() -> void:
    if pause_mode:
        if _game:
            _game.resume_game()
    elif _save_manager_has_method("has_save") and _save_manager.has_save():
        _save_manager.request_load()
        get_tree().change_scene_to_file("res://game.tscn")
    else:
        print("[MainMenu] No hay ninguna partida guardada para continuar.")

func _on_save_button_pressed() -> void:
    if pause_mode and _game:
        var saved := _game.save_game()
        if saved:
            print("[MainMenu] Partida guardada correctamente.")
    else:
        print("[MainMenu] Guardar solo está disponible durante la partida.")

func _on_new_game_button_pressed() -> void:
    if pause_mode:
        if _game:
            _game.start_new_game()
    else:
        if _save_manager_has_method("request_new_game"):
            _save_manager.request_new_game()
        else:
            push_warning("[MainMenu] No se pudo solicitar un nuevo juego porque falta SaveManager.")
        get_tree().change_scene_to_file("res://game.tscn")

func _on_exit_button_pressed() -> void:
    if pause_mode:
        if _game:
            _game.exit_to_main_menu()
    else:
        get_tree().quit()

func _on_save_state_changed() -> void:
    if not pause_mode:
        _update_buttons()
        focus_default()

func _save_manager_has_method(method_name: StringName) -> bool:
    return _save_manager != null and _save_manager.has_method(method_name)
