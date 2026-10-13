# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase1_completa.md`,
`contexto_fase2_completa.md`, `contexto_fase3_parte1_completa.md`, `contexto_fase3_parte2_completa.md`,
`ADR-001-flujo-de-partida.md`, `guia_documentacion_tecnica.md`,
`Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y `duck_game_biblia.md` si Claude los
pide o para tenerlos de referencia.

## Estado: Fase 3 (Flujo de partida, lobby y menú), Parte 3 — EN CURSO

El usuario decidió empezar esta parte por el **personaje** en vez de por los pendientes que
dejaba la Parte 2 (agrandar mapa, ADR-002, ajustes de partida). Se rehízo el arte del mapache
(vista de perfil, ojos rojos, sprites de 32x32) y se construyó sobre él: **color distinto por
jugador mediante un shader de paleta** (sin duplicar sprites), **animación por frames** (carrera
y salto), **brazo como sprite separado del cuerpo** y **arma agarrada por la mano del brazo**
(dibujo, agarrar, soltar, disparar y morir usan el mismo punto de mano).

El resultado gustó al usuario y se dejó así a propósito: queda pulido pendiente (ver
"Pendiente"). Estilo de trabajo: paso a paso, explicando el porqué, probando después de cada
cambio chico, y analizando el arte real (colores, tamaño) antes de elegir la técnica.

## Estructura nueva agregada sobre la Fase 3 Parte 2

```
Shaders
└── sh_player_tint            (NUEVO: .vsh por defecto + .fsh de colores clave)

Scripts
└── Player → scr_player_palette                              (NUEVO)
    (modificados: scr_player_visuals, scr_player_weapon, scr_player_health,
     scr_weapon_actions, scr_lobby, scr_config)

Sprites (todos de 32x32)
└── Players → spr_player_run (6 frames), spr_player_jump (despegue, subida, caída),
              spr_player_crouch (1), spr_player_slide (1),
              spr_player_ragdoll (3: arriba vivo, abajo, arriba muerto sin pupila),
              spr_player_arm (1, NUEVO)
```

Objetos tocados: `obj_player` (Create, Step, Draw) y `obj_game_manager` (Create).

## Clases implementadas / modificadas y su responsabilidad

- **`sh_player_tint`** — Vertex shader: el que trae GameMaker, sin tocar. Fragment shader:
  reemplaza SOLO dos tonos de pelaje por los del color del jugador. Colores clave del sprite
  original: `KEY_MID #726D67` y `KEY_LIGHT #B1A8A1`, comparados con tolerancia `TOL 0.02` (no con
  igualdad exacta: las GPUs móviles tienen menos precisión). Uniforms: `u_mid`, `u_light`.
  No toca el contorno (`#000000`), el oscuro del antifaz/anillos/patas (`#34302C`) ni los ojos
  (`#FFFFFF`, `#9E0B0F`).
- **`scr_player_palette`** (NUEVO) — `player_palette_init()` arma `global.player_palette`
  (8 colores: Gris `114,109,103`; Rojo `200,50,50`; Amarillo `215,170,30`; Verde `60,150,70`;
  Azul `55,100,200`; Blanco `190,190,190`; Naranja `215,115,35`; Violeta `130,70,180`) y cachea
  los uniforms en `global.u_player_mid/light`. `palette_entry(_name,_mid)` deriva el tono claro
  como `merge_color(_mid, c_white, 0.4)` (agregar un color = una línea). `palette_apply(_index)`
  activa el shader, `palette_reset()` lo desactiva. `palette_first_free_index()` devuelve el
  primer color que nadie usa. `player_get_color_index(_player_index)` lee el color del jugador.
- **`scr_lobby`** — Nueva `lobby_add_player(_device_type, _device_index)`: ÚNICO lugar que crea
  la entrada de un jugador unido, con `{device_type, device_index, color_index, ready}`; asigna
  el primer color libre y rechaza jugadores de más. `lobby_scan_join` la usa (antes repetía el
  `array_push` del struct tres veces). `lobby_reset` y `lobby_device_joined` sin cambios.
- **`scr_player_visuals`**:
  - `player_get_sprite(_state)`: RUN → `spr_player_run`; JUMP/FALL → `spr_player_jump`;
    SLIDE → `spr_player_slide`; el resto (IDLE, HURT, DEAD) → frame 0 de `spr_player_run`.
  - `player_update_animation()`: se llama desde el Step. Cambia `sprite_index` y elige
    `image_index` a mano (RUN usa los frames 1..N-1 según `abs(hsp)`; JUMP muestra el frame 0
    unos steps y luego el 1; FALL el 2).
  - `player_get_base_aim_angle()` (0 derecha, 90 arriba, 180 izquierda), `player_get_arm_angle()`
    (base + kick del arma; sin arma devuelve 270, brazo colgando), `player_hand_x/y(_angle)`
    (hombro + `PLAYER_ARM_LENGTH` en la dirección del ángulo), `player_draw_arm(_angle)`.
  - Tabla del hombro por frame: `player_shoulder_table_init()`, `player_get_shoulder_offset()`
    (devuelve una referencia a la tabla, no crea arrays), `player_shoulder_x()/y()`.
  - `player_debug_arm(_angle)` — TEMPORAL (punto rojo en el hombro, amarillo en la mano).
- **`scr_weapon_actions`** — `weapon_draw_held(_weapon,_x,_y,_facing,_angle)` cambió de firma:
  ya no recibe `_aim_up` sino el ángulo mundial final (con kick), y se dibuja con ángulo +
  `yscale = _facing` (mismo convenio que el brazo). El resto de funciones sin cambios.
- **`scr_player_weapon`** — `player_grab_weapon` busca a la altura del hombro;
  `player_release_weapon` y `player_try_fire` usan la mano del brazo (las balas nacen en
  `mano + muzzle_x`, ya calculado por `weapon_try_fire`). `player_try_fire` dejó de repetir la
  cuenta del ángulo base: usa `player_get_base_aim_angle()` y `player_get_arm_angle()`.
- **`scr_player_health`** — `player_die` lee la posición de la mano ANTES de soltar el arma. Se
  corrigió su comentario (hablaba de un contador de respawn que no existe desde la Fase 2).
- **`obj_player`** — Create: `image_speed = 0; anim_time = 0;`. Step: `player_update_animation()`
  justo después de `player_update_state(id, _in)`. Draw: cuerpo (con shader) → arma (sin shader)
  → brazo (con shader) → `player_debug_arm` (TEMPORAL, fuera del shader).
- **`obj_game_manager`** — Create: llama `player_palette_init()` y `player_shoulder_table_init()`
  (después de `weapon_data_init()`).

**Macros nuevas en `scr_config`** (valores de partida propuestos en la sesión; el usuario pudo
ajustarlos a ojo en el editor, verificar los finales en `scr_config`):
`PLAYER_RUN_ANIM_RATE 0.08`, `PLAYER_JUMP_START_FRAMES 4`, `PLAYER_SHOULDER_X 1`,
`PLAYER_SHOULDER_Y -15`, `PLAYER_ARM_LENGTH 9`.

**Tabla del hombro de la carrera** (medida por el usuario en el editor, relativa al frame 0):
frames 0 y 3 → `[0, 0]`; frames 2 y 5 → `[0, -1]`; frames 1 y 4 → `[0, -2]`. La de
`spr_player_jump` quedó en ceros.

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** error de compilación `Vértice de shader: sh_player_tint ... 'texture2D', 'gm_BaseTexture',
   'gl_FragColor'` más `HLSL11 compiler failed with exit code -1`.
   **Causa real:** el código del fragment shader se pegó en el archivo del vertex shader (`.vsh`).
   Esas funciones solo existen en el fragment. Un shader de GameMaker son dos archivos, cada uno
   con su pestaña. Después apareció un segundo problema: el `.fsh` tenía la versión VIEJA
   (por luminosidad, uniform `u_tint`) y el script enviaba `u_mid`/`u_light`; no se hablaban.
   **Fix:** `.vsh` con el vertex por defecto, `.fsh` con la versión de colores clave.
2. **Síntoma:** `Draw failed due to invalid input layout` (DirectX 11).
   **Causa real:** `draw_point_color` (una primitiva SIN coordenadas de textura) se dibujaba
   mientras el shader de color estaba activo; el shader espera `in_TextureCoord`.
   **Fix:** las primitivas se dibujan SIEMPRE fuera del shader, después de `palette_reset()`.
   **Regla:** el shader de color solo se activa alrededor de dibujos con sprite.
3. **Síntoma:** el arma se veía por encima del brazo.
   **Causa real:** orden de dibujo (cuerpo, brazo, arma).
   **Fix:** orden cuerpo → arma → brazo, activando el shader dos veces por jugador (costo
   despreciable: máximo 8 cambios por frame con 4 jugadores).
4. **Síntoma:** la mano del brazo no agarraba el arma por donde debía.
   **Causa real:** `weapon_draw_held` seguía usando `HAND_OFFSET_X/Y` fijos, sin saber dónde
   estaba la mano del brazo.
   **Fix:** el arma se dibuja en `player_hand_x/y` con el mismo ángulo que el brazo.

## Decisiones de diseño explícitas tomadas en esta parte

- **Recolor por colores clave (2 tonos de pelaje), no por luminosidad.** Primero se analizó el
  sprite viejo (32x39): el torso era limpio pero la cabeza y la cola tenían ~190 colores con
  degradados, así que se propuso un tinte por luminosidad con zonas protegidas (negros y
  blancos). Al rehacer el arte, el sprite nuevo resultó tener solo 6 colores; ahí los colores
  clave son más exactos y sin umbrales que ajustar. **Descartado:** luminosidad por bandas
  (fuzzy, y teñía parte del antifaz/ojos con umbrales mal puestos); tinte multiplicativo con
  `image_blend` (solo oscurece, los colores claros quedan apagados).
  **Regla:** todo sprite del mapache (cuerpo, brazo, ragdoll) debe usar EXACTAMENTE `#726D67` y
  `#B1A8A1` para el pelaje; un frame con un gris apenas distinto no se tiñe.
- **El color de cada jugador vive en `global.match.players_joined[i].color_index`, no en
  `obj_player`.** Los jugadores se recrean en cada ronda y deben conservarlo. Se lee en el Draw
  (no en el Create) porque no se garantizaba que `player_index` ya estuviera asignado en el
  Create. **Descartado:** array paralelo `player_colors` (el struct de cada jugador ya existía,
  el color es un campo más).
- **Un sprite por estado/animación, con su propia máscara de colisión.** La máscara es una por
  sprite (compartida por todos sus frames), así que agacharse, deslizarse y ragdoll son sprites
  aparte. Reglas: Origin debajo de los pies, en la columna del centro del cuerpo; la máscara
  simétrica respecto de ese origen (para que al voltear con `facing` no cambie de lado); la
  cola NO entra en la máscara; los pies de todos los sprites tocan la misma fila.
  Máscaras propuestas (si los pies están en la fila 31 y el origin es `(16,32)`):
  de pie `9,8,22,31`; agachado `9,16,22,31`; deslizándose `5,20,26,31`; ragdoll `8,8,23,23` con
  origin Middle Center (único que rota por físicas). Son valores de partida; las máscaras
  finales las puso el usuario en el editor.
- **Animación manual:** `image_speed = 0` y el frame lo elige `player_update_animation()`. El
  frame 0 de `spr_player_run` es la pose quieta, así que el ciclo de carrera usa los frames
  1..N-1. El cambio de `sprite_index` pasa del Draw al Step: en el Draw la máscara cambiaba un
  frame tarde respecto del movimiento y las colisiones.
- **Brazo separado, 1 frame horizontal apuntando a la derecha, rotado por código.** No hace
  falta un frame vertical (se obtiene rotando). Origin en el hombro. Sin arma, el brazo cuelga
  (270°). Si al rotar pixel art se ve dentado, se agregan frames pre-dibujados a 45° sin cambiar
  el sistema.
- **Un solo ángulo para brazo, arma y bala.** `player_get_arm_angle()` (base + kick) lo usan el
  dibujo del brazo, el del arma y el disparo. Convenio: ángulo MUNDIAL (0 derecha, 90 arriba,
  180 izquierda) y espejado con `yscale = facing`. **Descartado:** espejar con `xscale`: con
  `xscale` negativo GameMaker rota igual en sentido antihorario y los ángulos se invierten.
  El retroceso al jugador sigue usando la dirección BASE, no la del kick.
- **La mano es un solo punto** (`hombro + PLAYER_ARM_LENGTH` en la dirección del ángulo) y lo
  usan dibujar, agarrar, soltar, disparar y morir. En `player_release_weapon` y `player_die` la
  mano se calcula ANTES de soltar el arma: sin arma, `player_get_arm_angle()` devuelve el brazo
  colgando y el arma saltaría de lugar.
- **Sin structs por frame en el dibujo:** `player_get_shoulder_offset()` devuelve una referencia
  a la tabla armada una sola vez (el manual de optimización pide evitar presión sobre el GC).
- **Orden de dibujo cuerpo → arma → brazo**, para que la mano cubra la empuñadura.
- **Escala del personaje: DECISIÓN PENDIENTE.** El mapache nuevo mide ~24 px de alto (el
  anterior ~36), así que se ve más chico frente a los tiles y a las armas (la escopeta mide
  86 px, pensada para el tamaño viejo). Opciones: (A) acercar la cámara base cambiando
  `CAMERA_VIEW_W/H` (320x180 el doble; 480x270 un 33 % más grande, y a 1080p el escalado sigue
  siendo entero); (B) redibujar el mapache más grande; (C) escalar por código: DESCARTADA
  (píxeles de distinto tamaño, "mixels", y escala la máscara). Se sugirió probar 320x180 de
  forma temporal solo para afinar el hombro. **Candidato a ADR-002** junto con la cámara dinámica
  y la resolución 640x360 (afecta cámara, mapas, armas y UI de celular; cara de revertir con
  varios mapas hechos).

## Pendiente identificado, no bloqueante

TEMPORAL / deuda a propósito, documentada:
- `player_debug_arm` + su llamada en el Draw de `obj_player` + las líneas `shoulder_x/y` de
  `player_draw_arm`: borrar al terminar de pulir el brazo.
- Pulido del brazo (el usuario lo dejó "para luego"): afinar `PLAYER_SHOULDER_X/Y` y
  `PLAYER_ARM_LENGTH`, revisar el origin de `spr_player_arm`, y cómo se ve al agarrar.
- Tabla del hombro de `spr_player_jump` en ceros (medir si el brazo se despega al saltar/caer);
  `dx` en 0 en todos los frames.
- `HAND_OFFSET_X/Y` ya no deberían usarse en ningún lado: buscar `HAND_OFFSET` en todo el
  proyecto y borrar las macros si no hay más referencias.
- Verificar que `spr_player_jump` ya no tenga el frame de agacharse (ahora es `spr_player_crouch`).
- Decidir la escala del personaje (ver decisiones) y escribir el ADR-002.
- Assets sin usar en la lista del compilador: `spr_player_idle_2`, `spr_player_idle_dec`,
  `spr_player_run_dec`, `spr_player_jump_dec` (¿copias de respaldo?), además de los tilesets y
  fondos ya listados en la Parte 1.

Estados y sprites listos pero SIN conectar:
- Agacharse (`spr_player_crouch`) y deslizarse (`spr_player_slide`) tienen sprite y máscara,
  pero no existen como estados en `player_update_state` ni en el movimiento.
- Ragdoll/cadáver (`spr_player_ragdoll`, 3 frames): la muerte sigue ocultando al jugador
  (`visible = false`). Los frames son piezas distintas; probablemente pasen a objetos propios.
- Elegir color desde el lobby: hoy el color se asigna solo (primer color libre). Falta la
  pantalla de selección (saltando los ya tomados). Ojo: hay 8 colores y `MAX_PLAYERS` es 4.

Heredados de la Parte 2 (siguen sin resolver):
- (Heredado de Fase 3 Parte 2) Escribir el ADR-002; agrandar o crear un mapa más grande para
  probar la cámara; ajustes de partida configurables desde el lobby (`MATCH_DEFAULT_*` siguen
  fijos); controles táctiles; pulido visual de menú/lobby/intermission; colocar spawners de
  armas en `rm_map_sandbox_2`.

Heredados de fases anteriores:
- (Heredado de Fase 1) Sprite propio para FALL (hoy usa el frame de caída de `spr_player_jump`,
  parcialmente resuelto); SLIDE tiene sprite pero no estado. Reducción real de hitbox en SLIDE
  (máscara lista, falta el estado). Mecánica FLAP. `obj_room_controller` sin uso.
  `spr_player_run_gun` / `_2` (y sus variantes `_dec`) sin conectar. Diseño de la capa de red.
  `.gitattributes`.
- (Heredado de Fase 1) Fase B del sistema brazo/arma: el brazo independiente ya existe, pero el
  apuntado sigue limitado a 3 direcciones (derecha, izquierda, arriba); falta el ángulo libre
  (ratón, stick derecho y táctil requieren un campo de ángulo en el struct de input).
- (Heredado de Fase 2) Balas que atraviesan jugadores a alta velocidad; bala naciendo dentro de
  una pared; `weapon_resolve_overlap` en pasillos muy estrechos; sin sonido ni indicador de
  "clic vacío", sin recarga, sin indicador de munición; sin efecto de muerte; retoques del kick.
- (Heredado de Fase 3 Parte 1) Dispositivo `"keyboard2"` (decidir si se retira antes del
  release); `rm_intermission` sin uso.

## Verificaciones hechas al cierre de esta parte

Confirmadas por el usuario:
- El shader compila sin errores y el segundo jugador se ve rojo (cuerpo teñido; contorno,
  antifaz y ojos intactos).
- El brazo y el arma conectados a la mano: "ya se ve mejor" (agarrar y dibujar el arma en la mano).
- La tabla del hombro de la carrera fue medida por el usuario en el editor de sprites.

Sin confirmación explícita (código entregado, pendiente de probar a fondo):
- El color se mantiene igual en todas las rondas de una partida completa.
- Animación por frames: carrera sin la pose quieta en cada vuelta, salto con las 3 poses,
  sin saltos verticales al aterrizar.
- Que TODOS los frames (carrera, salto, deslizarse, brazo) usen exactamente los dos tonos clave
  (no se enviaron capturas de cada sprite para el análisis automático).
- Las balas salen desde la boca del cañón alineadas con el arma; soltar y morir con arma la
  sueltan desde la mano sin saltos; kick de Magnum/SMG moviendo brazo y arma juntos.

## Configuración relevante en el editor

- **`sh_player_tint`:** `.vsh` = vertex shader por defecto de GameMaker; `.fsh` = fragment de
  colores clave (`u_mid`, `u_light`). Son DOS archivos con pestañas separadas.
- **Colores del mapache:** pelaje medio `#726D67`, pelaje claro `#B1A8A1` (los dos que se
  tiñen); contorno `#000000`; oscuro fijo `#34302C`; ojos `#FFFFFF` y `#9E0B0F`.
- **Sprites del mapache (32x32):** Origin debajo de los pies, columna del centro del cuerpo
  (Bottom Center `(16,32)` si los pies tocan la última fila); máscara Manual, Rectangle,
  simétrica respecto del origen y sin la cola; `spr_player_ragdoll` con Origin Middle Center.
- **`spr_player_arm`:** un frame, brazo recto apuntando a la DERECHA, Origin en el hombro
  (extremo izquierdo, a media altura), máscara `Automatic` (no colisiona), mismos tonos clave.
- **`obj_game_manager` → Create:** `weapon_data_init()`, `player_palette_init()`,
  `player_shoulder_table_init()` (en ese orden, como mínimo la paleta antes de dibujar).
- **`obj_player` → Create:** `image_speed = 0`, `anim_time = 0`.
- **Game Options → Graphics:** `Interpolate colours between pixels` sigue desactivado (necesario
  para el escalado entero y para que los colores clave coincidan exactos).
- **Cámara:** `CAMERA_VIEW_W/H` en `scr_config` (hoy 640x360; se sugirió 320x180 temporal solo
  para afinar el hombro, verificar el valor vigente).
- Sin cambios en Input Map, grupos ni Room Order.

## Siguiente paso: Fase 3, Parte 4

A elección del usuario, según prioridad:
1. **Pulir el brazo y limpiar el debug** (borrar `player_debug_arm`), medir la tabla del hombro
   del salto, y borrar `HAND_OFFSET_*` si ya no se usa.
2. **Conectar los estados nuevos:** agacharse, deslizarse (con su máscara baja y su sprite) y la
   muerte con ragdoll/cadáver. Es lo que más enseña sobre la máquina de estados.
3. **Decidir la escala del personaje** y escribir el ADR-002 (cámara dinámica + resolución
   nativa + muerte por caída + tamaño del personaje).
4. **Retomar los pendientes de la Parte 2:** agrandar un mapa y probar la cámara, ajustes de
   partida en el lobby (junto con la selección de color), spawners en `rm_map_sandbox_2`,
   y más adelante los controles táctiles y el pulido visual de la UI.
