# Informe del proyecto MiJuego3D

## Explicación del código más relevante

### Escena principal (`game.tscn`)
- El nodo `Game` instancia el escenario base, agrupa monedas y enemigos, y coloca al jugador con transformaciones predeterminadas para el recorrido. Esto centraliza la configuración del nivel desde un único recurso de escena. 
- Las monedas se agrupan bajo el nodo `Coins`, lo que facilita su administración masiva y el uso de posiciones predefinidas para el recolector. De forma similar, el nodo `Enemies` reúne a los robots hostiles y reutiliza la misma escena instanciada varias veces.

### Control del jugador (`player/player.gd`)
- La clase `Player` extiende `CharacterBody3D` y gestiona movimientos, saltos, disparos y animaciones con parámetros configurables como velocidades máximas, aceleraciones y mezcla de animaciones. 
- El método `_physics_process()` normaliza la entrada respecto a la cámara, actualiza la velocidad en los ejes horizontal y vertical, aplica gravedad y controla la rotación del modelo mediante `adjust_facing()` para mantener la orientación alineada con el desplazamiento. 
- El script sincroniza las animaciones con la velocidad (`run`, `speed`, `state`) y controla el disparo de balas instanciando `Bullet` con velocidad inicial y sonido.

### Cámara de seguimiento (`player/follow_camera.gd`)
- La cámara se desacopla del padre con `set_as_top_level(true)` y cada cuadro calcula una posición objetivo basada en la distancia, altura y líneas de visión respecto al jugador. 
- Implementa un sistema de auto-giro mediante tres raycasts (`centro`, `izquierda`, `derecha`) para recolocar la cámara cuando detecta obstáculos, evitando intersecciones con el escenario y manteniendo al jugador visible.

### Comportamiento del enemigo (`enemy/enemy.gd`)
- Cada enemigo es un `RigidBody3D` que acelera hacia adelante cuando el rayo frontal detecta suelo y no detecta pared. Si pierde el suelo, inicia un giro gradual controlado por `ROT_SPEED` hasta encontrar de nuevo un camino libre. 
- El método `_integrate_forces()` evalúa colisiones por contacto: al recibir el impacto de una `Bullet` habilitada, desactiva sus bloqueos angulares, reproduce animaciones y sonidos de explosión y finalmente se elimina mediante `_die()`.

### Monedas (`coin/coin.gd`) y proyectiles (`player/bullet/bullet.gd`)
- Las monedas son `Area3D` que, al detectar el cuerpo del jugador, reproducen la animación `take`, incrementan la cuenta de monedas y marcan `taken` para evitar múltiples activaciones. 
- Las balas son `RigidBody3D` sencillos con una marca `enabled` que permite a los enemigos invalidarlas tras un impacto exitoso.

## Problemas encontrados y soluciones aplicadas

1. **Control de caídas del jugador:** se necesitaba evitar que el personaje quedara fuera del nivel tras caer. El método `_physics_process()` detecta si la posición vertical es menor que `-12` o si el usuario presiona `reset_position`, restableciendo la posición inicial y la velocidad a cero.
2. **Prevención de doble conteo de monedas:** las colisiones múltiples con la misma moneda podrían incrementar el contador de forma indebida. La solución fue incorporar la marca booleana `taken` en el `Area3D` de cada moneda para asegurarse de que solo se incremente la primera vez.
3. **Reacción a disparos enemigos:** los robots necesitaban retroalimentación y destrucción al recibir proyectiles. Se implementó una validación de contactos en `_integrate_forces()` que revisa si el objeto es una `Bullet` activa, reproduce animaciones y sonidos de impacto, libera los bloqueos angulares y marca la bala como no válida.
4. **Visibilidad constante del jugador:** la cámara debía evitar obstáculos que taparan al personaje. El script de la cámara lanza tres raycasts y ajusta la posición o rota automáticamente cuando detecta colisiones laterales o frontales.

## Conclusiones

El proyecto se organiza en escenas reutilizables y scripts que resuelven los principales retos de un juego de plataformas 3D: control responsivo del personaje, retroalimentación audiovisual, coleccionables robustos y una cámara inteligente. Las soluciones descritas aseguran que la experiencia de juego se mantenga fluida y libre de errores comunes.
