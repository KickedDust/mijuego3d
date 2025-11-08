extends Node3D
class_name Game

const GAME_SCENE_PATH := "res://game.tscn"
const MENU_SCENE_PATH := "res://MainMenu.tscn"

@onready var player: Player = $Player
@onready var coins_root: Node = $Coins
@onready var pause_menu: MainMenu = $UI/PauseMenu

func _ready() -> void:
    add_to_group("game_controller")
    if pause_menu:
        pause_menu.pause_mode = true
        pause_menu.set_game(self)
        pause_menu.visible = false
        pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    if SaveManager.consume_pending_load():
        _load_saved_game()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if get_tree().paused:
            resume_game()
        else:
            pause_game()
            get_viewport().set_input_as_handled()

func pause_game() -> void:
    if get_tree().paused:
        return
    get_tree().paused = true
    if pause_menu:
        pause_menu.show()
        pause_menu.focus_default()

func resume_game() -> void:
    if not get_tree().paused:
        return
    get_tree().paused = false
    if pause_menu:
        pause_menu.hide()

func save_game() -> bool:
    var data := _build_save_data()
    return SaveManager.save_game_state(data)

func start_new_game() -> void:
    get_tree().paused = false
    SaveManager.request_new_game()
    get_tree().change_scene_to_file(GAME_SCENE_PATH)

func exit_to_main_menu() -> void:
    get_tree().paused = false
    SaveManager.request_new_game()
    get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _build_save_data() -> Dictionary:
    var player_data := {
        "transform": player.global_transform,
        "coins": player.coins,
    }
    var coins_taken: Array = []
    if coins_root:
        for coin in coins_root.get_children():
            if coin.has_method("is_taken") and coin.is_taken():
                coins_taken.append(coin.name)
    return {
        "player": player_data,
        "coins_taken": coins_taken,
    }

func _load_saved_game() -> void:
    var data := SaveManager.load_game_state()
    if data.is_empty():
        return
    if data.has("player"):
        var player_data := data["player"]
        if player_data.has("transform"):
            player.global_transform = player_data["transform"]
            player.velocity = Vector3.ZERO
            player.initial_position = player.global_position
        if player_data.has("coins"):
            player.coins = int(player_data["coins"])
    var coins_taken := data.get("coins_taken", [])
    if coins_root:
        for coin in coins_root.get_children():
            var taken := coins_taken.has(coin.name)
            if coin.has_method("apply_saved_state"):
                coin.apply_saved_state(taken)

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        remove_from_group("game_controller")
