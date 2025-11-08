extends Control
class_name MainMenu

## Gestiona las interacciones del menú principal y el menú de pausa.
@export var pause_mode := false

var _game: Game = null

@onready var _continue_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContinueButton
@onready var _save_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var _new_game_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/NewGameButton

func _ready() -> void:
    if pause_mode:
        process_mode = Node.PROCESS_MODE_WHEN_PAUSED
        _game = get_tree().get_first_node_in_group("game_controller") as Game
    else:
        SaveManager.save_state_changed.connect(_on_save_state_changed)
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
        var has_save := SaveManager.has_save()
        _continue_button.disabled = not has_save
        _save_button.disabled = true

func _on_continue_button_pressed() -> void:
    if pause_mode:
        if _game:
            _game.resume_game()
    elif SaveManager.has_save():
        SaveManager.request_load()
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
        SaveManager.request_new_game()
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
