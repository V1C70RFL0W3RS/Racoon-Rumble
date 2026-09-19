# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `guia_documentacion_tecnica.md`,
`Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y `duck_game_biblia.md` si Claude
los pide o para tenerlos de referencia.

## Estado: Fase 1 (Fundaciones del proyecto) — COMPLETA

Se armó la estructura completa del proyecto desde cero (carpetas, convención de nombres),
un `obj_player` funcional con input abstraído para multijugador local, colisión contra
tilemap, una máquina de estados básica, y se conectaron los primeros sprites reales del
mapache y de las armas. El proyecto corre de punta a punta: desde `rm_boot` hasta 4
jugadores parados/moviéndose sobre un piso real en `rm_sandbox`.

## Estructura nueva agregada sobre la Fase 0 (proyecto vacío)

```
Objects
├── Core          → obj_game_manager
├── Players       → obj_player
├── Weapons       → (vacío, reservado para Fase 2)
├── Items         → (vacío, reservado)
├── Level         → obj_spawn_point
├── Effects       → (vacío, reservado)
├── UI            → (vacío, reservado)
└── Debug         → (vacío, reservado)

Sprites
├── Players       → spr_player_idle, spr_player_run, spr_player_jump
│                   (+ spr_player_run_gun, spr_player_run_gun_2, sin usar todavía)
├── Weapons       → spr_weapon_gun_1, spr_weapon_gun_2
└── Level/Tilesets → spr_tileset_ground

Tile Sets → tls_ground

Rooms
├── System  → rm_boot
├── Test    → rm_sandbox (hija de rm_level_template vía Room Inheritance)
└── (rm_level_template vive en Rooms, usada como padre para niveles futuros)

Scripts
├── Core    → scr_config
├── Utils   → scr_math_utils
└── Player  → scr_player_input, scr_player_state_machine, scr_player_visuals
```

**Nota sobre `obj_room_controller`:** se diseñó en un primer momento como objeto aparte,
pero se descartó (ver sección de decisiones) — su lógica se absorbió en el Room Start de
`obj_game_manager`. El objeto quedó sin usar en el proyecto; evaluar en Fase 2 si se borra
o se reutiliza para lógica específica de un nivel puntual.

## Clases implementadas / modificadas y su responsabilidad

- **`obj_game_manager`** — Persistente, único en todo el juego. `Create`: hace
  `room_goto(rm_sandbox)` (placeholder hasta que exista `rm_main_menu`). `Room Start`:
  busca todas las instancias de `obj_spawn_point` en la room actual y crea `MAX_PLAYERS`
  instancias de `obj_player`, asignándoles `player_index` (0 a 3). Si la room no tiene
  spawn points (ej. un futuro menú), no hace nada — no rompe.
- **`obj_player`** — Un solo objeto para los 4 jugadores locales, diferenciado por
  `player_index`. Step: pide input vía `get_player_input(player_index)`, aplica
  aceleración/fricción/gravedad, resuelve colisión contra el tilemap (`layer_collision`)
  con `move_and_collide` separado en X e Y, y actualiza su estado vía
  `player_update_state()`. Draw: elige sprite según el estado actual
  (`player_get_sprite()`) y dibuja el arma sostenida por separado (placeholder de
  posición fija, sin brazo independiente todavía).
- **`obj_spawn_point`** — Marcador sin sprite visible; su única función es existir en una
  posición dentro de una room para que `obj_game_manager` sepa dónde crear jugadores.
- **`scr_player_input` (`get_player_input`)** — Traduce "input del jugador N" a
  teclado (si `player_index == 0`) o gamepad (`player_index - 1` para el resto), devuelto
  como un struct uniforme. Ningún otro script pregunta `keyboard_check`/`gamepad_*`
  directamente — todo pasa por acá.
- **`scr_player_state_machine` (`player_update_state`)** — Switch sobre `PLAYER_STATE`
  (IDLE/RUN/JUMP/FALL/SLIDE/HURT/DEAD). HURT y DEAD son stubs vacíos, pendientes de los
  sistemas de daño y rondas.
- **`scr_player_visuals` (`player_get_sprite`)** — Mapea estado → sprite. FALL y SLIDE
  usan sprites placeholder (jump e idle respectivamente) hasta tener arte propio.
- **`scr_math_utils` (`approach`)** — Interpola un valor hacia un target a pasos fijos.
  Ver bug #1 más abajo.
- **`scr_config`** — Macros globales (`GRAVITY`, `PLAYER_MOVE_SPEED`, `PLAYER_ACCEL`,
  `PLAYER_JUMP_FORCE`, `MAX_PLAYERS`) y el enum `PLAYER_STATE`.

## Bugs encontrados y resueltos durante esta fase

1. **Síntoma:** el jugador aterrizaba bien, pero se deslizaba solo hacia un lado sin
   soltar ni tocar ninguna tecla, hasta caerse del borde.
   **Causa real:** en `approach()`, la rama que reduce la velocidad usaba
   `max(val - step, step)` en vez de `max(val - step, target)`. Como la fricción siempre
   apunta a `target = 0`, la velocidad quedaba clavada en un residual igual a `step` y
   nunca llegaba a cero.
   **Fix:** cambiar `step` por `target` en esa línea.

2. **Síntoma:** `ERROR ... illegal array use ... if (col_h) hsp = 0;`
   **Causa real:** `move_and_collide` no devuelve un booleano ni un id simple — devuelve
   un **array** de instancias con las que chocó. Usar el array directo en un `if` no es
   válido en GML.
   **Fix:** reemplazar por `if (array_length(col_h) > 0)`.

3. **Síntoma:** `Variable obj_game_manager.rm_sandbox ... not set before reading it.`
   **Causa real:** el nombre del asset de la room no coincidía exactamente con el string
   usado en `room_goto(rm_sandbox)` (typo al nombrarla) — GameMaker, al no encontrar un
   asset con ese nombre exacto, lo interpretó como una variable de instancia nunca
   asignada.
   **Fix:** corregir el nombre de la room para que coincida letra por letra.

4. **Síntoma:** tras borrar y recrear `rm_sandbox` desde `rm_level_template`, el jugador
   dejó de aparecer, sin ningún error en consola. El Draw GUI de diagnóstico mostró
   `spawns vistos: -1` (el valor inicial, nunca sobreescrito).
   **Causa real:** el código de creación de jugadores estaba en un evento llamado
   **"Inicio del juego"** (traducción de **Game Start**), no en **Room Start**
   ("Inicio de sala"/"Room Start"). Game Start ocurre una sola vez, al arrancar el juego
   entero, *antes* de que `obj_game_manager` exista siquiera (se crea recién al cargar
   `rm_boot`) — por eso el evento nunca llegaba a dispararse para esa instancia.
   **Fix:** mover el código al evento correcto, `Other → Room Start`.
   **Nota para el futuro:** la traducción al español de los eventos de GameMaker puede
   confundir Game Start con Room Start — verificar el nombre en inglés si hay dudas.

## Decisiones de diseño explícitas tomadas en esta fase

- **Sin prefijos numéricos en carpetas del Asset Browser** (`00_`, `01_`...). Se usa en
  su lugar el filtro **Custom Order**, que permite reordenar carpetas a mano sin
  necesidad de tocar el nombre. El único lugar donde el orden real importa a nivel
  técnico es el **Room Order** del proyecto (`rm_boot` debe ser la primera).
- **Diseño data-driven para armas/items**: un solo `obj_weapon` genérico (a implementar
  en Fase 2) parametrizado por struct de configuración, en vez de un objeto por arma —
  evita repetir código de disparo/recarga por cada arma del catálogo.
- **`obj_game_manager` absorbe la responsabilidad de `obj_room_controller`**: al ser
  persistente y usar el evento Room Start (que se dispara en cada room, incluso para
  instancias persistentes), no hace falta colocar un controller a mano en cada nivel —
  solo hace falta que la room tenga `obj_spawn_point`, que de todas formas es parte del
  diseño del nivel.
- **Room Inheritance para estandarizar capas**: se creó `rm_level_template` con las 8
  capas estándar (`layer_ui`, `layer_effects`, `layer_players`, `layer_items`,
  `layer_level`, `layer_collision`, `layer_background_decor`, `layer_background`, de
  adelante hacia atrás). Todo nivel real nace como hijo de esa room, heredando el orden
  y nombres de capas automáticamente. `rm_sandbox` ya es hija de este template.
- **Colisión de terreno con Tile Layer + tilemap**, no instancias individuales por
  bloque — se confirmó que en GameMaker actual **no existe** una pestaña "Collision" por
  tile en el editor del Tile Set (a diferencia de otros motores): cualquier tile que no
  sea el índice 0 (vacío) es sólido automáticamente para `move_and_collide`.
- **El primer tile de todo Tile Set debe quedar vacío** (índice 0) — es una regla fija
  de GameMaker, independiente del tamaño de tile elegido.
- **Separación visual de cuerpo/arma (Fase A de un plan en 2 fases)**: por ahora el arma
  se dibuja aparte del sprite del cuerpo, en una posición de mano fija, en vez de usar
  sprites con el arma "horneada" en cada pose. Evita que cada arma nueva multiplique la
  cantidad de sprites de personaje necesarios. La Fase B (brazo independiente con ángulo
  de apuntado libre, como `duckArms.xnb` en DuckGame) queda pendiente para cuando exista
  ese arte.
- **Origin y máscara de colisión del jugador fijados a mano** (`Bottom Center`,
  rectángulo manual ~16x36 centrado) e iguales entre `idle/run/jump`, para que la
  hitbox no cambie de tamaño al cambiar de animación.
- **Origin del arma en el punto de agarre (grip)**, no en el centro del sprite —
  necesario para que rote naturalmente sobre la mano al apuntar. Máscara de colisión del
  arma dejada en `Automatic` (no colisiona por sí sola; el pickup se resuelve por
  distancia, no por máscara).
- **Alcance de esta fase respecto a multijugador en red**: se confirmó que el juego debe
  soportar local + LAN + online, pero se decidió terminar el juego local completo
  primero. El diseño de input ya desacopla el origen del input (teclado/gamepad) del
  resto del código, lo cual va a facilitar agregar "input remoto" más adelante sin
  rehacer esta capa.

## Pendiente identificado, no bloqueante

- Sprite propio para los estados `FALL` y `SLIDE` (hoy reusan `jump` e `idle`).
- Reducción real de hitbox en `SLIDE` (depende del sprite propio de arriba).
- Mecánica `FLAP` (reducir gravedad al mantener salto) — no implementada aún, es una
  línea de código cuando se decida agregarla.
- Fase B del sistema de brazo/arma: brazo independiente con rotación libre según ángulo
  de apuntado (hoy el arma se dibuja en posición fija).
- `obj_room_controller` sin uso en el proyecto — decidir si se borra o se reserva para
  lógica específica de nivel.
- `spr_player_run_gun` / `spr_player_run_gun_2` sin conectar todavía (pensados para
  cuando el jugador sostiene un arma mientras corre).
- Sistema de armas en sí (`obj_weapon`, pickup, disparo) — no empezado, es la Fase 2.
- Diseño de la capa de red (LAN primero, online como extensión) — pospuesto a propósito
  hasta cerrar el juego local completo.
- Falta agregar `.gitattributes` (`*.yy linguist-generated=true`) junto al `.gitignore`
  ya colocado, para que GitHub no confunda el proyecto con código YACC.

## Verificaciones hechas al cierre de la fase (todas OK)

- Los 4 jugadores se crean correctamente en los spawn points de `rm_sandbox` al arrancar
  desde `rm_boot`.
- Colisión sólida contra el tilemap de `layer_collision` (aterrizar, chocar contra
  paredes) sin atravesarlo.
- La fricción/aceleración del jugador frena correctamente hasta velocidad 0 (bug #1
  corregido y confirmado).
- Cambio de sprite según estado (`IDLE`/`RUN`/`JUMP`) visualmente correcto, sin saltos
  verticales al cambiar de pose (Origin consistente entre sprites).
- El arma dibujada por separado rota de forma natural sobre el punto de agarre.

## Configuración relevante en el editor

- **Room Order:** `rm_boot` primera. `rm_sandbox` es hija de `rm_level_template` (Room
  Inheritance).
- **`obj_game_manager`:** propiedad **Persistent** activada.
- **Nombres de capas (exactos, case-sensitive):** `layer_ui`, `layer_effects`,
  `layer_players`, `layer_items`, `layer_level`, `layer_collision`,
  `layer_background_decor`, `layer_background`.
- **Asset Browser:** filtro **Custom Order** activado (Filter → Custom Order) en vez de
  orden alfabético por defecto.
- **Sprites del jugador** (`spr_player_idle/run/jump`, 32x39): Origin manual
  `Bottom Center` (16, 39); Collision Mask manual, Rectangle, ajustada a la silueta de
  pie (no automática, no precisa por píxel).
- **Sprites de armas** (`spr_weapon_gun_1` 32x32, `spr_weapon_gun_2` 86x32): Origin
  manual sobre el punto de agarre (ajustado a ojo arrastrando en el editor); Collision
  Mask en `Automatic`.
- **`tls_ground`:** sin configuración de colisión por tile (no existe esa opción en
  GameMaker 2026) — cualquier tile pintado que no sea el índice 0 colisiona.
- **`.gitignore`:** el generado oficialmente por GameMaker (Plugin Preferences →
  Source Control → Add skeleton .git defaults), colocado en la raíz del repo junto al
  `.yyp`. Incluye la línea `Build` (carpeta de compilación de GMRT).

## Siguiente paso: Fase 2 — Sistema de Armas

Se arranca con el diseño data-driven ya acordado: `obj_weapon` genérico +
`obj_projectile` genérico + `obj_weapon_pickup`, con la definición de cada arma viviendo
en `scr_weapon_data` (struct/array de configuración: daño, cadencia, sprite, velocidad de
bala). Ya están listos y conectados los sprites de `spr_weapon_gun_1`/`spr_weapon_gun_2`
y el punto de dibujo en la mano del jugador (Fase A del sistema visual) para apoyarse en
ellos directamente. Queda pendiente decidir, al arrancar esa fase, el mecanismo de pickup
(por distancia, como en el ejemplo de tu documento de DuckGame) y cómo se integra con la
máquina de estados del jugador (por ejemplo, si sostener un arma cambia el sprite de
`RUN` a `spr_player_run_gun`).
