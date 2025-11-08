extends Control

## Gestiona las interacciones del menú principal.
class_name MainMenu

func _on_new_game_button_pressed() -> void:
    """Inicia una nueva partida cargando la escena principal del juego."""
    get_tree().change_scene_to_file("res://game.tscn")

func _on_load_game_button_pressed() -> void:
    """Punto de entrada para la lógica de carga de partidas guardadas."""
    print("[MainMenu] Cargar partida aún no está implementado.")

func _on_options_button_pressed() -> void:
    """Punto de entrada para mostrar un menú de opciones."""
    print("[MainMenu] Opciones aún no está implementado.")

func _on_exit_button_pressed() -> void:
    """Cierra el juego."""
    get_tree().quit()
