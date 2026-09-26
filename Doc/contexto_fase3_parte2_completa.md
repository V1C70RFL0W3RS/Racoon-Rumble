# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase1_completa.md`,
`contexto_fase2_completa.md`, `contexto_fase3_parte1_completa.md`, `ADR-001-flujo-de-partida.md`,
`guia_documentacion_tecnica.md`, `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y
`duck_game_biblia.md` si Claude los pide o para tenerlos de referencia.

## Estado: Fase 3 (Flujo de partida, lobby y menú), Parte 2 — EN CURSO

Se terminó y probó el Paso 3 (spawners de armas), pendiente desde el cierre de la Parte 1. Se
avanzó buena parte del Paso 4 (UI real): se cerró la decisión de resolución/cámara, se resolvió
un bug de gameplay real encontrado en el camino (caída fuera del mapa), se arregló el texto
borroso de la UI, se armó un sistema de dos fuentes y funciones reutilizables de dibujo, y el
pool de mapas del bag shuffle pasó de una lista a mano a detectarse solo por convención de
nombre. Quedan afuera de esta parte: ajustes de partida configurables desde el lobby, controles
táctiles, y el pulido visual de las pantallas (paneles, fondos). Estilo de trabajo: paso a paso,
verificando cada pieza con el usuario antes de seguir, y priorizando entender la causa real de
cada bug antes de parchearlo.

## Estructura nueva agregada sobre la Fase 3 Parte 1

```
Objects
└── Core       → obj_camera_controller (NUEVO, persistente)

Scripts
└── Core       → scr_ui_draw                              (NUEVO)
    (scr_config, scr_weapon_data, scr_match: modificados)

Fonts
├── fnt_title (Press Start 2P)                             (NUEVO)
└── fnt_body  (VT323)                                      (NUEVO)

Rooms
└── Maps       → rm_sandbox → rm_map_sandbox (renombrada)
                 rm_sandbox_2 → rm_map_sandbox_2 (renombrada)
```

## Clases implementadas / modificadas y su responsabilidad

- **`obj_weapon_spawner`** (completado) — Variable Definitions: `weapon_choice` (tipo
  `List`, opciones `Aleatoria`, `Pistola`, `Escopeta`, `Magnum`, `SMG`, `Aleatoria fija`).
  Create: `current_weapon`, `respawn_timer`, `locked_weapon_id` (`undefined` = todavía no
  sorteada), método `spawn_weapon()` (único lugar que crea armas: resuelve la opción
  elegida a un `WEAPON_ID` real recién en cada respawn). Step: contador de
  ocupado/libre igual al diseñado en la Parte 1, sin cambios.
- **`scr_weapon_data`** (funciones nuevas) — `weapon_pick_random_id()` (arma al azar
  válida); `weapon_id_from_choice(_choice)` (traduce el texto elegido en el editor a un
  `WEAPON_ID`, comparando contra `WeaponDef.name`; si no coincide ningún nombre, avisa por
  consola y elige una al azar en vez de romper el juego). Macros nuevas:
  `WEAPON_CHOICE_RANDOM` (`"Aleatoria"`), `WEAPON_CHOICE_RANDOM_LOCKED`
  (`"Aleatoria fija"`).
- **`obj_camera_controller`** (NUEVO, `Objects/Core`, Persistent) — Cámara dinámica con
  zoom, adaptada del ejemplo de `duck_game_biblia.md` (sección 11.6). Create: estado
  propio (`cam`, `view_w`, `view_h`, `snap_next`). Room Start: retoma `view_camera[0]`
  de la room nueva (mismo patrón que el tilemap en `obj_player`/`obj_weapon`: la
  instancia persiste, la room cambia); marca `snap_next = true`. Step: mide la
  dispersión de los jugadores **vivos** (`state != PLAYER_STATE.DEAD`); si no hay
  ninguno, no mueve la cámara; calcula el zoom necesario para que todos entren con
  margen, manteniendo proporción 16:9; en el primer Step de cada room (`snap_next`) se
  ubica directo, sin interpolar; el resto del tiempo usa `lerp` (posición y zoom con
  velocidades distintas); siempre queda acotada (`clamp`) a los bordes de la room, con
  una excepción si la room es más chica que la vista actual.
- **`obj_player`** (cambio) — Step: nueva comprobación, `y > room_height +
  ROOM_FALL_KILL_MARGIN` llama a `player_die()`. Encontrado como un gap real (nunca
  existió una forma de morir por caída desde la Fase 1) al notar que la cámara se
  alejaba sin límite siguiendo a un jugador cayendo fuera del mapa.
- **`obj_game_manager`** (cambio) — Step: sincroniza `display_set_gui_size` con el
  tamaño real de la ventana en cada frame (solo llama a la función si cambió), para que
  la capa GUI se dibuje a resolución nativa de pantalla en vez de a los 640×360 del
  mundo.
- **`fnt_title`** (Press Start 2P, bitmap/arcade) y **`fnt_body`** (VT323,
  terminal/CRT) — mismo criterio de dos fuentes que `biosFont`/`smallFont` en Duck
  Game: una para títulos y números grandes, otra para texto de lectura. Ambas con
  rango de caracteres `ASCII (0–255)` para soportar tildes y `ñ`.
- **`scr_ui_draw`** (NUEVO) — `ui_draw_centered` (única función que toca
  `draw_set_font`/`draw_set_halign`/`draw_set_color`), y los envoltorios
  `ui_draw_title`, `ui_draw_body`, `ui_draw_body_list`. Posicionan el texto como
  fracción de `display_get_gui_width()/height()` (no en píxeles fijos), así se adapta a
  cualquier resolución real de pantalla. El interlineado entre líneas sí queda en
  píxeles fijos a propósito (depende del tamaño de letra, no de la pantalla).
- **`obj_menu_controller`, `obj_lobby_controller`, `match_draw_debug()`** (cambio) —
  reescritos para usar `scr_ui_draw` en vez de `draw_text` suelto con coordenadas fijas.
- **`scr_match`** (función nueva) — `match_scan_maps()`: recorre todas las rooms del
  proyecto (`asset_get_ids(asset_room)`) y devuelve las que empiezan con
  `MAP_NAME_PREFIX`, para armar el pool de mapas sin mantenerlo a mano.
- **`obj_lobby_controller`** (cambio) — el tercer argumento de `match_settings_init(...)`
  pasó de un array fijo (`[rm_sandbox, rm_sandbox_2]`) a `match_scan_maps()`.

**Macros nuevas en `scr_config`:**
`CAMERA_VIEW_W 640`, `CAMERA_VIEW_H 360`, `CAMERA_MAX_ZOOM_OUT 2`,
`CAMERA_PADDING_X 64`, `CAMERA_PADDING_Y 64`, `CAMERA_POS_LERP 0.1`,
`CAMERA_ZOOM_LERP 0.05`, `ROOM_FALL_KILL_MARGIN 64`, `MAP_NAME_PREFIX "rm_map_"`.
Además, `WEAPON_SPAWNER_RESPAWN_FRAMES` y `WEAPON_SPAWNER_CHECK_RADIUS` (documentadas
en la Parte 1 pero nunca llegaron a escribirse realmente — ver bug #2).

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** `Variable Index [-1] out of range [4] - -9.weapon_defs` al crear un
   arma desde un spawner.
   **Causa real:** el spawner pasaba `weapon_id = -1` (su valor de "aleatorio")
   directo a `obj_weapon`, que no sabe qué es `-1` y lo usó como índice del catálogo.
   **Fix:** el spawner resuelve la elección a un `WEAPON_ID` real (`weapon_id_from_choice`
   / sorteo) **antes** de crear la instancia; `obj_weapon` nunca recibe un valor
   especial, solo ids válidos.

2. **Síntoma:** `Variable obj_weapon_spawner.WEAPON_SPAWNER_RESPAWN_FRAMES ... not set
   before reading it`.
   **Causa real:** la macro se había documentado como agregada en la Parte 1, pero
   nunca se escribió de verdad en `scr_config` — mismo patrón de "nombre no
   reconocido = variable de instancia sin asignar" que ya apareció en la Fase 1 (bug
   #3) y la Fase 2 (bug #1).
   **Fix:** agregar `WEAPON_SPAWNER_RESPAWN_FRAMES` y `WEAPON_SPAWNER_CHECK_RADIUS` a
   `scr_config`.

3. **Síntoma:** al probar la cámara dinámica, un jugador cayendo por un hueco del mapa
   hacía que la cámara se alejara indefinidamente (zoom al máximo) sin motivo aparente
   para el resto de los jugadores.
   **Causa real:** nunca existió una mecánica de muerte por caída fuera de la room
   (gap heredado desde la Fase 1, nunca antes visible porque no había cámara dinámica
   que lo evidenciara). El jugador caído seguía "vivo" y su posición, cada vez más
   lejos, entraba en el cálculo de dispersión de la cámara.
   **Fix:** `obj_player` llama a `player_die()` al superar
   `room_height + ROOM_FALL_KILL_MARGIN`. Al quedar `DEAD`, la cámara lo excluye
   (mismo filtro que ya usaba para muertos por bala).

4. **Síntoma:** al empezar cada ronda nueva, se veía un paneo notorio de la cámara
   desde la posición de la ronda anterior hasta la de los jugadores actuales.
   **Causa real:** `obj_camera_controller` es persistente; el Room Start centraba la
   cámara en el mapa (no en los jugadores), y el primer Step recién empezaba a
   interpolar (`lerp`) hacia ellos — eso se veía como el paneo.
   **Fix:** bandera `snap_next`, activada en Create y en cada Room Start; en el primer
   Step de cada room, la cámara se ubica directo en la posición/zoom objetivo sin
   interpolar (los `Room Start` de todas las instancias, incluida la creación de
   jugadores de `obj_game_manager`, ya terminaron para cuando corre el primer Step).

5. **Síntoma:** el texto de menú/lobby/debug se veía borroso al pasar a pantalla
   completa o en resoluciones altas.
   **Causa real:** la capa GUI se dibujaba por defecto al tamaño de la vista del mundo
   (640×360) y se escalaba junto con todo lo demás. Los sprites no sufren porque se
   desactivó la interpolación (nitidez del pixel art), pero el antialiasing de las
   fuentes, al escalarse sin suavizado, se ve sucio/borroso.
   **Fix:** `display_set_gui_size` sincronizado con el tamaño real de la ventana en
   `obj_game_manager`, para que la GUI se dibuje a resolución nativa, no a 640×360.

6. **Síntoma:** tras el fix anterior, los textos `TEMPORAL` de menú/lobby/debug
   aparecían amontonados en la esquina superior izquierda.
   **Causa real:** estaban escritos con coordenadas de píxeles fijas, pensadas para
   una GUI de 640×360; al pasar la GUI a resolución real (mucho más grande), esos
   números quedaron muy cerca del origen.
   **Fix:** reposicionados como fracción de `display_get_gui_width()/height()`
   (después migrados del todo a `scr_ui_draw`).

## Decisiones de diseño explícitas tomadas en esta parte

- **`weapon_choice` como `List` (desplegable) en vez de Creation Code:** más cómodo de
  usar desde el editor. El tipo `List` de GameMaker entrega el **texto** de la opción
  elegida, no un índice — confirmado probando con `show_debug_message` antes de
  escribir la lógica final. Por eso la comparación es por nombre
  (`WeaponDef.name`) y no por posición en la lista: el orden de los ítems del
  desplegable no tiene que coincidir con el orden del enum `WEAPON_ID`.
- **Opción "Aleatoria fija" además de "Aleatoria":** la primera sortea de nuevo en
  cada respawn; la segunda sortea una sola vez (`locked_weapon_id`) y mantiene esa
  arma toda la ronda. Como `locked_weapon_id` vive en la instancia del spawner y las
  instancias se recrean en cada room, el sorteo se renueva solo en cada ronda nueva,
  sin código extra.
- **Resolución nativa 640×360 para el mundo, desacoplada del tamaño de la room:** en
  vez de fijar el tamaño de cada mapa a la resolución de pantalla (lo que limitaba el
  mapa a una sola pantalla), la vista/cámara queda fija en 640×360 (escalado entero,
  nitidez del pixel art, legible en celular) y el tamaño de cada room queda libre —
  la cámara se encarga de mostrar más o menos mapa según haga falta.
- **Cámara dinámica con zoom (estilo Duck Game) en vez de mapas de una sola
  pantalla:** sigue a los jugadores vivos, ignora a los muertos, nunca se acerca más
  que la resolución nativa (`CAMERA_MAX_ZOOM_OUT` acota el alejamiento, no el
  acercamiento) y nunca muestra fuera de los límites de la room. Candidato a
  `ADR-002` (afecta cámara, diseño de niveles y los futuros controles táctiles; cara
  de revertir una vez que haya varios mapas grandes) — **decidido pero todavía sin
  escribir como documento**.
- **Muerte por caída fuera del mapa:** no es una decisión estética, es cerrar un
  agujero real de diseño heredado desde la Fase 1. Reutiliza `player_die()`
  existente, no agrega un sistema nuevo.
- **La GUI se dibuja a la resolución real de la pantalla, no a los 640×360 del
  mundo:** el texto no es pixel art y no necesita la misma protección de grilla de
  píxeles que los sprites; a resolución nativa se ve más nítido. Esto separa
  explícitamente "cómo se ve el mundo" (pixel-perfect, escala entera) de "cómo se ve
  la UI" (resolución real, con antialiasing).
- **Sistema de dos fuentes (`fnt_title`/`fnt_body`):** mismo criterio que
  `biosFont`/`smallFont` de Duck Game — una fuente ancha/llamativa para títulos
  (Press Start 2P) y una más legible para texto de instrucciones/puntajes (VT323).
  Evita usar una sola fuente demasiado difícil de leer en oraciones largas o
  demasiado simple para los títulos.
- **`scr_ui_draw` centraliza el dibujo de texto de UI:** ningún objeto de UI llama a
  `draw_set_font`/`draw_set_halign`/`draw_set_color` directamente; todos pasan por
  `ui_draw_title`/`ui_draw_body`/`ui_draw_body_list`. Si mañana cambia cómo se ve el
  texto (por ejemplo agregar sombra), se cambia en un solo lugar.
- **Pool de mapas automático por convención de nombre, no por carpeta del editor:**
  se verificó que GameMaker no expone la carpeta del Asset Browser (`Maps`) en tiempo
  de ejecución. La alternativa usada es que toda room cuyo nombre empiece con
  `MAP_NAME_PREFIX` (`"rm_map_"`) se considera un mapa jugable; `match_scan_maps()` las
  detecta solas con `asset_get_ids(asset_room)`. Agregar un mapa nuevo ya no requiere
  tocar `scr_match` ni `obj_lobby_controller` — solo nombrarlo así y ubicarlo en la
  carpeta `Maps` (la carpeta sigue siendo buena práctica organizativa, pero ya no es
  lo que decide si el mapa entra al pool).

## Pendiente identificado, no bloqueante

TEMPORAL / deuda a propósito, documentada:
- **Escribir `ADR-002`** (cámara dinámica + resolución nativa 640×360 + muerte por
  caída): la decisión ya está tomada y en uso, falta formalizarla como documento.
- **Agrandar `rm_map_sandbox`/`rm_map_sandbox_2`** (o crear mapas nuevos más grandes):
  hoy son chicos y el zoom dinámico casi no se nota; falta un mapa con margen real
  para separar jugadores y ver el efecto a fondo.
- **Ajustes de partida configurables desde el lobby:** `MATCH_DEFAULT_SCORE_TO_WIN` y
  `MATCH_DEFAULT_ROUNDS_PER_BLOCK` siguen fijos por macro; falta una pantalla simple
  para elegirlos antes de jugar (pendiente original de la Fase 3 Parte 1, sigue sin
  resolver).
- **Controles táctiles (Paso 4e):** decisión explícita del usuario de no diseñarlos
  todavía. El struct de `scr_player_input` ya tiene los campos reservados para
  llenarse cuando llegue el momento; no requiere cambios de arquitectura, solo
  implementación futura.
- **Pulido visual de menú/lobby/intermission (Paso 4d):** hoy es texto plano centrado,
  sin paneles, fondos ni botones reales. El usuario decidió ir mejorándolo
  gradualmente a medida que se avanza, no de una sola vez.
- **Colocar spawners de armas en `rm_map_sandbox_2`:** se probaron y confirmaron en
  `rm_map_sandbox`; falta repetir la colocación (sin código nuevo) en el segundo mapa.

Heredados de fases anteriores (sin cambios, siguen sin resolver): sprite propio
FALL/SLIDE, hitbox de SLIDE, mecánica FLAP, Fase B de brazo/arma, `obj_room_controller`
sin uso, `spr_player_run_gun`/`_2` sin conectar, capa de red, `.gitattributes`, balas
que atraviesan a alta velocidad, bala naciendo dentro de pared,
`weapon_resolve_overlap` en pasillos muy estrechos, sin sonido/recarga/indicador de
munición, sin sprite de muerte, apuntado a 3 direcciones, dispositivo `"keyboard2"`
(decidir si se retira antes de release), `rm_intermission` sin uso.

## Verificaciones hechas al cierre de esta parte (todas OK, confirmadas por el usuario)

- Spawners: aparición inicial correcta, arma fija (`Escopeta`) y aleatoria funcionando,
  respawn tras agarrar el arma, sin duplicados mientras el arma sigue en su puesto,
  regeneración al tirar el arma lejos, `"Aleatoria fija"` mantiene la misma arma toda
  la ronda.
- Cámara: se aleja al separar jugadores y se acerca al juntarlos, ignora a los
  muertos, no muestra nada fuera de los bordes del mapa, arranca sin paneo visible en
  cada ronda nueva.
- Muerte por caída: un jugador que cae fuera del mapa muere y deja de afectar el
  cálculo de la cámara.
- Texto de UI nítido en pantalla completa (ya no borroso).
- Fuentes `fnt_title`/`fnt_body` mostrando tildes y `ñ` correctamente.
- El bag shuffle sigue alternando entre los mapas existentes usando
  `match_scan_maps()`, sin lista fija en el código.

## Configuración relevante en el editor

- **Rooms renombradas:** `rm_sandbox` → `rm_map_sandbox`, `rm_sandbox_2` →
  `rm_map_sandbox_2` (el renombrado en el Asset Browser actualizó solas todas las
  referencias en código).
- **`obj_camera_controller`:** propiedad **Persistent** activada; una instancia
  colocada en `rm_boot`, junto a la de `obj_game_manager`.
- **Viewport/Camera de `rm_level_template`:** `Enable Viewports` activado, tamaño
  inicial 640×360 (valor de arranque; `obj_camera_controller` lo reconfigura en cada
  Room Start).
- **Game Options → Graphics:** `Interpolate colours between pixels` desactivado
  (necesario para que el escalado entero del mundo no se vea borroso).
- **`fnt_title`:** fuente Press Start 2P (instalada desde Google Fonts), tamaño a
  gusto (24–32), Anti-aliasing On, rango de caracteres **ASCII (0–255)**.
- **`fnt_body`:** fuente VT323 (Google Fonts), tamaño a gusto (16–20), Anti-aliasing
  On, rango **ASCII (0–255)**.
- **`obj_weapon_spawner` → Variable Definitions:** `weapon_choice`, tipo `List`,
  ítems `Aleatoria`, `Pistola`, `Escopeta`, `Magnum`, `SMG`, `Aleatoria fija` (los
  nombres de arma deben coincidir letra por letra con `WeaponDef.name` del catálogo).
  3 instancias colocadas en `rm_map_sandbox` (una fija en Escopeta, dos aleatorias).
- **Sin cambios** en Input Map ni grupos.

## Siguiente paso: Fase 3, Parte 3

Cerrar los pendientes marcados arriba, en el orden que el usuario priorice:
escribir `ADR-002`; agrandar o crear un mapa más grande para probar la cámara con
separación real; construir la pantalla de ajustes de partida en el lobby (reemplaza
los valores fijos `MATCH_DEFAULT_*`); y, cuando el usuario decida diseñarlos, los
controles táctiles del Paso 4e. El pulido visual de menú/lobby/intermission se sigue
haciendo de forma incremental, no como un paso cerrado aparte.
