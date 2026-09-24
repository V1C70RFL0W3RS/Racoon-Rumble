# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase1_completa.md`,
`contexto_fase2_completa.md`, `ADR-001-flujo-de-partida.md`, `guia_documentacion_tecnica.md`,
`Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y `duck_game_biblia.md` si Claude
los pide o para tenerlos de referencia.

## Estado: Fase 3 (Flujo de partida, lobby y menú), Parte 1 — EN CURSO

Se construyó el flujo de partida completo definido en el ADR-001: unión de jugadores en
un menú (sin depender de MAX_PLAYERS fijo), lobby jugable, cuenta regresiva, ciclo de
rondas con bag shuffle de mapas, intermission con puntajes, detección de ganador y
desempate. El Paso 3 (spawners de armas) quedó **codeado pero sin probar** — se corta acá
antes de colocarlo en el editor. Estilo de trabajo: paso a paso, probando después de cada
cambio chico, con guards temporales documentados cuando una pieza depende de otra que
viene después.

## Estructura nueva agregada sobre la Fase 2

```
Objects
├── UI       → obj_menu_controller, obj_lobby_controller       (NUEVOS)
└── Level    → obj_weapon_spawner                    (NUEVO, Paso 3, sin probar)

Scripts
└── Core     → scr_lobby                                       (NUEVO)
    (scr_match, scr_config, scr_player_input: modificados)

Rooms
├── Menu         → rm_menu                   (NUEVO, sin padre)
├── Lobby        → rm_lobby                   (NUEVO, hija de rm_level_template)
├── Intermission → rm_intermission            (NUEVO, sin padre, sin uso todavía)
└── Maps         → rm_sandbox, rm_sandbox_2   (movidas desde Test)
```

## Clases implementadas / modificadas y su responsabilidad

- **`scr_lobby`** — `lobby_reset`, `lobby_device_joined`, `lobby_scan_join`: arma
  `global.match.players_joined` durante `rm_menu`. No sabe nada de UI ni de `scr_match`.
- **`obj_menu_controller`** — objeto de `rm_menu`. Llama `lobby_scan_join()` cada Step;
  con Enter pasa a `rm_lobby` si hay al menos 1 jugador unido. Draw GUI temporal muestra
  cuántos se unieron.
- **`obj_lobby_controller`** — objeto de `rm_lobby`. Con Enter llama
  `match_settings_init(...)` (valores `TEMPORAL` fijos) y `match_start()`. Draw GUI
  temporal muestra jugadores presentes.
- **`scr_match`** — reescrito en gran parte:
  - `enum MATCH_STATE`: `LOBBY, COUNTDOWN, PLAYING, ROUND_OVER, INTERMISSION,
    MATCH_OVER` — **sin `TIEBREAK`** (ver decisiones).
  - `match_settings_init(score_to_win, rounds_per_block, map_pool)`.
  - `match_all_participants()`, `match_current_participants()`, `match_begin_round()`
    — helpers nuevos.
  - `match_start()`: ya no reemplaza `global.match` entero, agrega campos (no pisa
    `players_joined`). Arranca en `COUNTDOWN`.
  - `match_bag_next_map()`: bag shuffle de mapas.
  - `match_update()`: `COUNTDOWN` (freeze timer), `PLAYING` (guard de puntaje en
    desempate), `ROUND_OVER` (bifurca por `is_tiebreak`), `INTERMISSION` (nuevo: decide
    ganador único, empate → desempate, o siguiente bloque), `MATCH_OVER` (fix: usa
    `array_length(players_joined)` en vez de `MAX_PLAYERS` fijo).
  - `match_draw_debug()`: TEMPORAL, agrega `COUNTDOWN`/`INTERMISSION`, mismo fix de loop.
- **`scr_player_input` (`get_player_input`)** — ya no deduce el dispositivo de
  `player_index`; consulta `global.match.players_joined[player_index]`. Rama
  `TEMPORAL` `"keyboard2"` (flechas + numpad) para testear 2 jugadores sin segundo
  control físico.
- **`obj_player`** — Step: `exit` temprano tanto en `DEAD` como en
  `global.match.state == MATCH_STATE.COUNTDOWN` (congelado en cuenta regresiva). Ambos
  `exit` movidos al principio del Step (bug #6 más abajo).
- **`obj_game_manager`**:
  - Create: ya no llama `match_start()`; arma `global.match = {}`, `lobby_reset()`, va
    a `rm_menu`.
  - Room Start: crea jugadores según `match_current_participants()`; spawn points
    barajados con `array_shuffle_ext` antes de asignar. Bloque `TEMPORAL` de armas de
    prueba **sacado** (reemplazado por el sistema de spawners del Paso 3).
  - Step / Draw GUI: `match_update()`/`match_draw_debug()` protegidos con
    `variable_struct_exists(global.match, "state")` (no existe en `rm_menu`/`rm_lobby`
    antes de `match_start()`).
- **`obj_weapon_spawner`** (NUEVO, `Objects/Level`, **sin instancias colocadas
  todavía**) — marca un punto de reaparición de armas. `weapon_id = -1` (default,
  aleatorio) o fijo vía Creation Code. Respawnea cuando el punto queda "libre" (arma
  agarrada o alejada de `WEAPON_SPAWNER_CHECK_RADIUS`), tras
  `WEAPON_SPAWNER_RESPAWN_FRAMES`. No destruye armas viejas — decide solo si genera
  una nueva ahí.

**Macros nuevas en `scr_config`:** `LOBBY_JOIN_KEY vk_space`,
`LOBBY_JOIN_KEY_TEST vk_shift` (TEMPORAL), `MATCH_COUNTDOWN_SECONDS 5`,
`MATCH_DEFAULT_SCORE_TO_WIN 10` (TEMPORAL, bajado a mano en pruebas),
`MATCH_DEFAULT_ROUNDS_PER_BLOCK 3` (TEMPORAL), `MATCH_INTERMISSION_FRAMES 300`,
`WEAPON_SPAWNER_RESPAWN_FRAMES 300`, `WEAPON_SPAWNER_CHECK_RADIUS 20`.

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** `Variable <unknown_object>.state ... not set before reading it` en
   `match_update`.
   **Causa real:** al sacar `match_start()` del Create de `obj_game_manager`,
   `global.match` quedó `{}` en `rm_menu`, pero el Step seguía llamando
   `match_update()`/`match_draw_debug()` sin condición.
   **Fix:** guard con `variable_struct_exists(global.match, "state")` antes de ambas.

2. **Síntoma:** pantalla negra en `rm_lobby`, sin errores en consola.
   **Causa real:** heredar capas de `rm_level_template` no hereda contenido — sin
   tiles ni `obj_spawn_point`, no había nada que crear ni dibujar.
   **Fix:** pintar piso y colocar spawn points en `rm_lobby`, igual que en un mapa.

3. **Síntoma:** `Variable Index [1] out of range [1] - -9.players_joined` en
   `get_player_input`.
   **Causa real:** el loop de creación de jugadores seguía usando `MAX_PLAYERS` (4)
   fijo, creando `player_index` que no existían en `players_joined`.
   **Fix:** límite del `for` = `array_length(global.match.players_joined)`.

4. **Síntoma:** `array_pop :: argument 0 is not an array` en `match_bag_next_map`.
   **Causa real:** `array_shuffle_ext()` baraja *in-place* y no devuelve nada; se
   reasignaba `_m.map_bag = array_shuffle_ext(...)`, dejando `map_bag` en `undefined`.
   **Fix:** clonar con `variable_clone` primero, `array_shuffle_ext` sobre la copia en
   línea aparte, sin reasignar.

5. **Síntoma:** mismo error que el bug 4, esta vez barajando spawn points (juego
   trabado tras el Enter del lobby).
   **Causa real:** misma reasignación incorrecta (`_spawn_points = array_shuffle_ext(...)`).
   **Fix:** igual que el bug 4.

6. **Síntoma:** el jugador se seguía moviendo/disparando durante la cuenta regresiva.
   **Causa real:** los `exit` de `DEAD`/`COUNTDOWN` estaban al final del Step, después
   de ya procesar input y física — no evitaban nada en ese frame.
   **Fix:** mover ambos `exit` al principio del Step.

7. **Síntoma:** no se veía el número de la cuenta regresiva en pantalla.
   **Causa real:** `match_draw_debug()` nunca recibió el bloque de dibujo de
   `COUNTDOWN` al copiar los cambios.
   **Fix:** agregar el `if` correspondiente.

## Decisiones de diseño explícitas tomadas en esta parte

- **`MATCH_STATE` sin `TIEBREAK`:** un desempate es procesalmente una ronda normal
  (mismo `COUNTDOWN`/`PLAYING`/`ROUND_OVER`). Se implementó con
  `global.match.is_tiebreak` (bifurca qué hace `ROUND_OVER` después) y
  `global.match.round_participants` (quién spawnea esa ronda). Evita duplicar cuenta
  regresiva + partida para un caso idéntico salvo por eso.
- **`match_start()` ya no reemplaza `global.match` entero:** ahora agrega/sobreescribe
  campos puntuales, para no pisar `players_joined` armado en el lobby.
- **Segundo dispositivo `"keyboard2"` (flechas + numpad):** `TEMPORAL` explícito para
  testear multijugador sin segundo control físico. No es una feature de hotseat
  pensada — herramienta de desarrollo.
- **Spawners con respawn automático, no de una sola vez:** como las armas nunca se
  destruyen (Fase 2), un spawner no puede preguntar "¿existe la instancia?" — tiene
  que preguntar si el arma sigue en su radio y sin sostener; si no, genera una nueva
  sin importar qué pasó con la vieja.
- **`weapon_id` del spawner por Creation Code, no por struct:** el Create define solo
  el default (`-1`, aleatorio); el Creation Code de la instancia en la room lo pisa
  después si se quiere un arma fija — coherente con que el Creation Code corre después
  del Create Event (ya documentado en la Fase 2).

## Pendiente identificado, no bloqueante

TEMPORAL, a resolver en el Paso 4:
- `MATCH_DEFAULT_SCORE_TO_WIN` / `MATCH_DEFAULT_ROUNDS_PER_BLOCK` / pool de mapas fijo
  en `obj_lobby_controller` → UI de ajustes de partida.
- Draw GUI de texto simple en `obj_menu_controller`/`obj_lobby_controller` → UI real.
- Dispositivo `"keyboard2"`: decidir si se retira antes de release o se documenta como
  modo de desarrollo permanente.
- `rm_intermission`: creada, sin uso — hoy la intermission se dibuja como overlay sobre
  el mapa actual, no en esa room.

Paso 3 (spawners de armas) — código escrito, **sin probar**:
- `obj_weapon_spawner` implementado; bloque `TEMPORAL` de armas de prueba sacado del
  Room Start.
- Falta: colocar instancias en `rm_sandbox`/`rm_sandbox_2` (y opcionalmente
  `rm_lobby`) y confirmar que el respawn funciona.

Heredados de fases anteriores (sin cambios, siguen sin resolver): sprite propio
FALL/SLIDE, hitbox de SLIDE, mecánica FLAP, Fase B de brazo/arma, `obj_room_controller`
sin uso, `spr_player_run_gun`/`_2` sin conectar, capa de red, `.gitattributes`, balas
que atraviesan a alta velocidad, bala naciendo dentro de pared, `weapon_resolve_overlap`
en pasillos muy estrechos, sin sonido/recarga/indicador de munición, sin sprite de
muerte, apuntado a 3 direcciones, input táctil. Se suman a la lista de "Unused Assets"
del compilador: `obj_room_controller`, `spr_bg_1`, `spr_bg_4`, `spr_bg_5`,
`Spr_Racoon_Idle_Gun`, `Spr_Racoon_Walk_Gun`, `Spr_Racoon_Walk_Gun_2`, `spr_tileset_3`,
`tls_3` — decidir si se borran.

## Verificaciones hechas al cierre de esta parte (todas OK, confirmadas por el usuario)

- Unión con teclado y con `"keyboard2"` de testeo; contador correcto; Enter → lobby.
- Ambos jugadores se mueven independientemente en el lobby.
- Enter en el lobby: bag shuffle de mapa, cuenta regresiva visible, jugador congelado.
- Al terminar la cuenta, responde con normalidad.
- Detección de "queda 1 vivo", suma de puntaje, pausa, cambio de mapa alternando sin
  repetir (con 2 mapas en el pool).
- Tras `rounds_per_block`, aparece `INTERMISSION` con los puntajes.
- Sin ganador → otro bloque automático. Con un solo líder → pantalla de ganador, Salto
  reinicia.
- Probado con `score_to_win` bajado temporalmente para confirmar el ciclo completo
  rápido.

## Configuración relevante en el editor

- Rooms: `rm_menu` (sin padre), `rm_lobby` (Parent: `rm_level_template`, con piso y
  spawn points), `rm_intermission` (sin padre, sin contenido, sin uso).
- Carpetas de Rooms: `Menu`, `Lobby`, `Intermission`, `Maps` (con Custom Order).
- Room Order: `rm_boot`, `rm_menu`, `rm_lobby`, `rm_intermission`, `rm_sandbox`,
  `rm_sandbox_2`.
- `obj_menu_controller` en `rm_menu`; `obj_lobby_controller` en `rm_lobby`.
- `obj_weapon_spawner`: implementado, **cero instancias colocadas** todavía en
  ninguna room.
- Controles `"keyboard2"` (TEMPORAL): flechas mover/apuntar, Numpad 0 saltar,
  Numpad 1 agarrar/tirar, Numpad 2 disparar.
- Sin cambios en Input Map ni grupos.

## Siguiente paso: Fase 3, Parte 2

Retomar el Paso 3: colocar instancias de `obj_weapon_spawner` en los mapas y probar el
respawn. Después, Paso 4 (UI real para menú/lobby/intermission/puntaje, pensada para
celular) reemplazando los bloques `TEMPORAL` y valores fijos de esta parte. Queda además
por decidir si `rm_intermission` se usa como room propia o si la intermission se queda
como overlay (no se discutió explícitamente todavía).
