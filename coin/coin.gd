extends Area3D


var taken := false

@onready var _circle := $Circle
@onready var _glow_sprite := $GlowSprite
@onready var _animation := $Animation
@onready var _particles := $CPUParticles3D


func _on_coin_body_enter(body):
        if not taken and body is Player:
                set_taken_state(true, true)
                # We've already checked whether the colliding body is a Player, which has a `coins` property.
                # As a result, we can safely increment its `coins` property.
                body.coins += 1


func set_taken_state(state: bool, play_animation := false) -> void:
        taken = state
        if taken:
                if play_animation:
                        _animation.play(&"take")
                else:
                        _animation.stop()
                        _circle.visible = false
                        _glow_sprite.visible = false
                        _glow_sprite.set("transparency", 1.0)
                        _particles.emitting = false
        else:
                _animation.play(&"spin")
                _circle.visible = true
                _glow_sprite.visible = true
                _glow_sprite.set("transparency", 0.0)
                _particles.emitting = false


func is_taken() -> bool:
        return taken


func apply_saved_state(saved_taken: bool) -> void:
        set_taken_state(saved_taken, false)
