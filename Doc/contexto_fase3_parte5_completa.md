# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase1_completa.md`,
`contexto_fase2_completa.md`, `contexto_fase3_parte1_completa.md`, `contexto_fase3_parte2_completa.md`,
`contexto_fase3_parte3_completa.md`, `contexto_fase3_parte4_completa.md`, `ADR-001-flujo-de-partida.md`,
`ADR-002-camara-y-resolucion.md`, `ADR-003-objetos-agarrables.md`, `guia_documentacion_tecnica.md`,
`Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y `duck_game_biblia.md` si Claude los
pide o para tenerlos de referencia.

## Estado: Fase 3 (Flujo de partida, lobby y menú), Parte 5 — EN CURSO (cierre de sesión)

Esta parte se dedicó al **cadáver del jugador** (ragdoll de dos piezas) y, para poder agarrarlo, a
generalizar todo lo "agarrable": las armas pasaron a ser un caso particular de un padre común,
`obj_holdable`. El cadáver sale en dos mitades que se pueden agarrar, soltar y lanzar; siempre están
unidas por un punto de unión, y se comportan como el de Duck Game (biblia 4.4.5): una varilla de
longitud fija entre las dos piezas, ángulo deducido de la dirección entre ellas, la pieza en la mano
también gira, y la mitad que no se agarra cuelga y se balancea. Estilo de trabajo: paso a paso, probando
después de cada cambio; varias decisiones se tomaron **midiendo el arte real** (las capturas del usuario)
en vez de suponer.

También se confirmó que los colores clave del shader de tinte ya funcionan en todos los sprites del
mapache, y se decidió el formato de pantalla en celular (ver "Decisiones").

## Estructura nueva agregada sobre la Fase 3 Parte 4

```
Objects
├── Items   → obj_holdable (NUEVO, padre), obj_corpse_piece (NUEVO, hijo)
│             obj_weapon (ahora hijo de obj_holdable; el padre se asigna desde el botón "Matriz")
└── (sin cambios en el resto)

Scripts
├── Items   → scr_holdable (NUEVO)
├── Player  → scr_corpse (NUEVO)
│             (modificados: scr_weapon_actions, scr_player_weapon, scr_player_health,
│              scr_player_visuals, scr_config)

Sprites
└── Players → spr_corpse_upper (NUEVO, 2 frames: viva, muerta), spr_corpse_lower (NUEVO, 1 frame)
              spr_player_ragdoll: ya no existe (se renombró y sus frames se separaron en estos dos)
```

## Clases implementadas / modificadas y su responsabilidad

- **`obj_holdable`** (padre de todo lo que se agarra, suelta y lanza). Create: `holder` (noone = suelto),
  `hsp/vsp`, `tilemap`, `angle/spin` (giro solo visual), `color_index` (-1 = sin teñir; con guarda por
  si llega por struct), `rotates` (false = nunca gira, p. ej. cajas), `fires` (true solo en armas),
  `kick`, `held_angle/held_facing`, `grip_x/grip_y` (punto por donde la mano lo sujeta, relativo al
  origen), `drives_angle` (true = el propio objeto fija `angle`), y los parámetros de físicas
  `air_friction_mult`, `wall_bounce`, `floor_bounce` (valores que dejan a las armas igual que antes).
  Step: si está sostenido, sale; si está incrustado en el mapa, se desincrusta (`holdable_depenetrate`);
  gravedad; tope de velocidad (`HOLDABLE_MAX_HSP/VSP`); rebote lateral; vertical con rebote opcional;
  fricción en el aire; bloque de rotación en 4 ramas (`drives_angle`, `!rotates`, aterrizó, en el aire).
  Draw: `holdable_draw`.
- **`obj_weapon`** (hijo). Solo lo propio del arma: `weapon_id`, `def`, `ammo`, `cooldown`; pone
  `fires = true`. Hereda eventos Step (con `event_inherited()` al final) y Draw.
- **`obj_corpse_piece`** (hijo). `piece_frame` (0 = superior viva, 1 = inferior, 2 = superior muerta),
  `partner` (la otra mitad), `drives_angle = true`, y parámetros del cadáver. **Begin Step:** solo la
  parte superior llama `corpse_pair_update(id, partner)`, una vez por pareja y antes de que ninguna se
  mueva. **Step:** fija sprite/imagen (`corpse_apply_frame`) y el punto de sujeción desde la tabla.
  **Draw:** recorta el dibujo a `corpse_rest_length() + CORPSE_DRAW_SLACK` de su pareja (solo la que
  cuelga o la inferior), como el clamp de 8 px de la biblia.
- **`scr_holdable`**: `holdable_find_grabbable`, `holdable_draw` (único lugar donde se dibuja un
  holdable; tiñe si `color_index >= 0`), `holdable_draw_held`, `holdable_held_x/y` (dónde queda el
  ORIGEN para que el punto de sujeción caiga en la mano; tiene 3 ramas: `drives_angle`, `!rotates`,
  normal), `holdable_resolve_overlap`, `holdable_eject` (único lugar donde algo pasa de sostenido a
  suelto), `holdable_depenetrate` (saca un objeto incrustado por el lado más corto).
- **`scr_corpse`**: `corpse_joint_init/get`, `corpse_grip_get`, `corpse_rest_length`, `corpse_apply_frame`,
  `corpse_spawn` (único lugar donde se crean cadáveres; las dos piezas nacen ensambladas, con la misma
  velocidad, y el conjunto se desincrusta junto con `corpse_pair_free`), `corpse_pair_update` (el
  solucionador: ver decisiones). Más la sección TEMPORAL de afinadores.
- **`scr_player_weapon`**: `player_update_held_position` lleva lo sostenido a la mano **cada frame**
  (la posición del objeto es su ORIGEN, calculado con el punto de sujeción) y guarda `held_angle` y
  `held_facing`. `player_try_fire` ignora lo que no dispara (`fires`).
- **`scr_player_health`**: `player_die` llama a `corpse_spawn` (no si cayó fuera del mapa), después de
  soltar el arma.
- **`scr_player_visuals`**: `player_update_arm_raise` usa `muzzle_x` solo si lo sostenido dispara.
- **`obj_game_manager` → Create**: `corpse_joint_init()` junto a las otras inicializaciones.

**Macros nuevas en `scr_config`:** `HOLDABLE_MAX_HSP 12`, `HOLDABLE_MAX_VSP 8`,
`HOLDABLE_BOUNCE_MIN_SPEED 1.5`, `HOLDABLE_MAX_PUSHOUT 32`, `CORPSE_INERTIA 0.5`, `CORPSE_POP_SPEED -2`,
`CORPSE_SPAWN_JOINT_Y -12` (altura del punto de unión sobre los pies al morir; afinable a ojo),
`CORPSE_SPAWN_PUSHOUT 24`, `CORPSE_SNAP_FACTOR 5`, `CORPSE_AIR_FRICTION_MULT 0.3`, `CORPSE_BOUNCE 0.6`,
`CORPSE_DRAW_SLACK 2`. **Eliminadas:** `CORPSE_UPPER/LOWER_OFFSET_Y`, `CORPSE_UPPER/LOWER_JOINT_Y`,
`CORPSE_LINK_MIN/MAX/SLACK/STIFFNESS/DAMPING`, `CORPSE_SCATTER_X`, `CORPSE_SPIN`.

**Tablas del cadáver** (medidas con el afinador, en px respecto del origen (16,16) de cada sprite;
verificar los valores vigentes en `corpse_joint_init`): `corpse_joint` = superior `[0, 3]`, inferior
`[-3, -7]`; `corpse_grip` = superior `[0, -3]`, inferior `[-1, 0]`.

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** la pieza del cadáver no cambiaba de frame al asignarle `piece_frame`.
   **Causa real:** (a) el Draw del padre dibujaba siempre el frame 0 (copiado de `obj_weapon`, que solo
   tiene uno); (b) el Creation Code de una instancia corre DESPUÉS del Create, así que `image_index =
   piece_frame` en el Create ya se había evaluado.
   **Fix:** el Draw usa `image_index`, y el frame se fija en el Step cada frame.
2. **Síntoma:** el cadáver ensamblado salía alargado y "volaba".
   **Causa real (doble):** (a) los números `16x23` y `16x20` del usuario eran las **coordenadas del
   punto de unión** dentro del frame de 32x32, no tamaños: se leyeron mal dos veces; (b) `spr_player_ragdoll`
   tenía UNA máscara de colisión para sus 3 frames (una por sprite), con lo cual la parte inferior, más
   pequeña, flotaba sobre el suelo (diagnóstico por razonamiento, no medido).
   **Fix:** separar en dos sprites con máscara `Automatic, Rectangle`, y afinar el punto de unión con un
   afinador en vivo en vez de deducirlo de las imágenes.
3. **Síntoma:** al lanzar el cadáver, las piezas aceleraban sin control (velocidad horizontal de 40 a
   millones en pocos cientos de frames) y acababa con `ERROR ... invalid bound -nan(ind)` en
   `move_and_collide`.
   **Causa real:** el enlace entre las dos mitades era un resorte resuelto **pieza por pieza, cada una en
   su propio Step**: la segunda veía a la primera ya movida (a velocidad de lanzamiento, 7.5 px por frame,
   mayor que la separación de los puntos de unión) y el error se realimentaba, creciendo un ~13 % por
   frame hasta el infinito. El `-nan` era solo el síntoma final.
   **Fix:** un único solucionador por pareja (`corpse_pair_update`, en el Begin Step, con los mismos datos
   para las dos piezas) más el tope de velocidad en el padre. Antes se probó mover el resorte al Begin
   Step, pero se reemplazó por el solucionador de la biblia.
4. **Síntoma:** al morir, la parte inferior del cadáver aparecía dentro del suelo.
   **Causa real:** nacía a una altura fija sobre los pies, con la base del conjunto por debajo del piso, y
   `move_and_collide` no libera a un objeto que NACE incrustado (mismo origen que el bug #5 de la Fase 2).
   **Fix:** el cadáver se sube al nacer según las máscaras reales, y el padre desincrusta cualquier objeto
   suelto que quede dentro del mapa.
5. **Síntoma:** al morir pegado a una pared, el cadáver salía volando hacia arriba y luego caía.
   **Causa real:** el arreglo del bug #4 solo sabía subir (tope 32 px); con una pared lateral, subía todo
   lo que podía.
   **Fix:** `holdable_depenetrate` prueba cada distancia en los tres sentidos (arriba, derecha, izquierda)
   y gana el desplazamiento más corto; `corpse_pair_free` hace lo mismo para el conjunto de las dos piezas.
   **Lección:** un arreglo con una sola dirección crea un bug nuevo en cuanto el caso cambia de lado.

## Decisiones de diseño explícitas tomadas en esta parte

- **Padre `obj_holdable` en vez de reusar `obj_weapon` con un arma "falsa".** Cajas, equipamiento y
  piezas de cadáver comparten físicas y agarre; solo el arma tiene munición y kick. Formalizado en
  **`ADR-003-objetos-agarrables.md`**.
- **Banderas en el padre (`fires`, `rotates`, `drives_angle`, `color_index`, `grip`) en vez de métodos
  que cada hijo sobrescribe.** Todo el dibujo vive en `holdable_draw` y la mano no necesita saber qué
  lleva. Descartado: `draw_held` como método por objeto (habría duplicado el código de color y escala).
- **Cadáver de dos piezas enlazadas, ambas agarrables** (decisión del usuario). La otra mitad cuelga con
  físicas y se balancea. Descartado: tres piezas con articulación invisible (Duck Game): se adaptó a dos
  cuerpos y una varilla, porque el punto de unión ya sale de la tabla.
- **Varilla de longitud fija entre los orígenes**, con la longitud sacada de la tabla de uniones (origen
  inferior − origen superior = unión superior − unión inferior). **El ángulo no se simula:** sale de la
  dirección entre las dos piezas, y es el mismo para las dos, así que la pieza que se lleva también gira.
  **Diferencia con Duck Game:** la pieza en una mano tiene masa inversa 0 (no se corrige) y la que cuelga
  recibe toda la corrección; Duck Game reparte a medias.
- **Descartados, en orden:** resorte entre centros con distancia mínima y máxima (no sirve con piezas
  rectangulares); resorte por cajas de colisión (se basaba en unos tamaños mal leídos); unión por puntos
  con resorte y amortiguación (se disparaba, ver bug #3); cuelga rígida sin balanceo (paso intermedio).
- **Un sprite por pieza, con su origen en (16,16) y máscara `Automatic`.** Evita calcular máscaras a mano
  y que una pieza flote por culpa de la máscara de la otra.
- **Parámetros de la biblia aplicados por objeto, no globales:** fricción en el aire ×0.3, rebote 0.6 (vertical
  y lateral) y recorte visual a unos px de la pareja; las armas conservan sus valores (rebote vertical 0).
- **La posición de un objeto sostenido es su ORIGEN**, recalculada cada frame desde la mano y el punto de
  sujeción (antes se quedaba en el lugar donde se agarró y solo se dibujaba en la mano).
- **Orden dentro del frame:** cualquier restricción entre dos objetos que se mueven a la vez se resuelve
  ANTES de que se muevan (Begin Step), nunca en el mismo evento donde se mueven.
- **Formato de pantalla en celular (decisión del usuario):** no le molesta mostrar **más mundo a los lados**
  en pantallas alargadas; la regla propuesta es fijar la altura de la vista (180) y dejar que el ancho
  crezca. Afecta a la cámara (`CAMERA_ASPECT` hoy es fijo en 16:9) y a la zona de los controles táctiles:
  se formalizará en un ADR aparte cuando se diseñen.
- **Afinadores temporales:** el usuario prefirió NO borrarlos todavía (se necesitan para afinar más
  adelante); se propuso hacerlos condicionales con una macro `DEBUG_TOOLS`.

## Pendiente identificado, no bloqueante

TEMPORAL / deuda a propósito, documentada:
- **Afinadores:** el del hombro (heredado de Parte 4: `player_debug_*`, `shoulder_tune`, `tune_*`), el del
  punto de unión y sujeción (`corpse_debug_tune_joint`, `corpse_debug_draw_joint`; **F5** activa, **F6**
  pieza, **F7** unión/sujeción, **Numpad 4/6/8/2** mueven, **P** imprime), y `corpse_debug_check`. Falta
  decidir: macro `DEBUG_TOOLS` (propuesta, sin confirmar que se aplicó) o borrarlos.
- **Nombres a limpiar:** las macros `WEAPON_WALL_BOUNCE`, `WEAPON_GROUND_FRICTION`, `WEAPON_AIR_FRICTION`,
  `WEAPON_SETTLE_RATE`, `WEAPON_GRAB_RADIUS`, `WEAPON_MAX_PUSHOUT` y `WEAPON_KICK_LIFT` ya no son solo de
  armas → `HOLDABLE_*` (buscar y reemplazar). La variable del jugador `held_weapon` y las funciones
  `player_update_weapon / grab_weapon / release_weapon` ahora manejan cualquier holdable → `held_item` y
  nombres neutros (buscar en todo el proyecto, en un paso aparte).
- `corpse_spawn` ya hace varias cosas (crear, enlazar, desincrustar); si crece, separar "crear" de "colocar".
- El ángulo es **uno solo para las dos mitades** (varilla rígida): Duck Game deja doblar un poco la cintura.
  Si se ve rígido, se añade un grado de libertad.
- Las piezas no reciben todavía la dirección del disparo que mató (salen con la inercia del jugador).
- Costo: `holdable_depenetrate` hace un `place_meeting` por holdable suelto y por frame (barato con el
  tilemap, pero a revisar si algún día hay muchos).
- **Pendiente de verificar contra el código real de Duck Game:** los números del cadáver de la biblia
  (distancias 6/12, masas 2.1, rebote 0.6, clamp 8 px) no se comprobaron contra el código fuente (ADR-002 ya
  anota lo mismo para la cámara).
- Efectos de game feel, sin empezar (screenshake, hitstop, partículas, sonido).

Heredados de la Parte 4 (siguen sin resolver):
- (Heredado de Fase 3 Parte 4) Peso del arma (P7), soltar el arma agachado, formato de pantalla en celular
  (ahora con decisión, falta el ADR), sincronización vertical desactivada antes de publicar, ventana inicial
  a 4x, apuntado de ángulo libre, parámetro `input` sin uso en `player_update_state`.
- (Heredado de Fase 3 Parte 4) Rendimiento de la resolución 1920x1080 en celular sin medir.

Heredados de fases anteriores:
- (Heredado de Fase 1) Sprite propio para `FALL`, `obj_room_controller` sin uso, `spr_player_run_gun`/`_2` sin
  conectar, capa de red, `.gitattributes`.
- (Heredado de Fase 2) Balas que atraviesan jugadores a alta velocidad (pasar a `collision_line`: se revisa la
  línea que la bala recorrió en el frame y no solo su posición final), bala naciendo dentro de una pared,
  `weapon_resolve_overlap` (hoy `holdable_resolve_overlap`) en pasillos muy estrechos, sin indicador de
  "clic vacío", recarga ni munición, sin efecto de muerte, retoques del kick.
- (Heredado de Fase 3 Parte 1) Dispositivo `"keyboard2"`, `rm_intermission` sin uso.
- (Heredado de Fase 3 Parte 2) Ajustes de partida configurables desde el lobby, controles táctiles, pulido
  visual de menú/lobby/intermission, spawners de armas en `rm_map_sandbox_2`.
- (Heredado de Fase 3 Parte 3) Elegir color desde el lobby, assets sin usar del compilador (el último
  registro lista 120: fondos `spr_bg_*`, tilesets y los `_dec`).

Resuelto en esta parte: ragdoll/cadáver del jugador, y los colores clave de los sprites del mapache
(confirmados por el usuario).

## Verificaciones hechas al cierre de esta parte

Confirmadas por el usuario:
- Los colores clave funcionan en los sprites del mapache y de las piezas del cadáver.
- Paso 1: `obj_weapon` como hijo de `obj_holdable` se comporta igual que antes.
- Agarrar piezas del cadáver, con su color y en la mano (paso 4) funciona.
- Ensamblado de las dos mitades con la tabla del punto de unión y el punto de sujeción.
- El solucionador de pareja (lanzar, agarrar, soltar) funciona sin que se dispare la velocidad.
- Los parámetros del cadáver (fricción en el aire, rebote) funcionan.
- El cadáver ya no nace dentro del suelo y ya no sale volando al morir pegado a una pared.

Sin confirmación explícita:
- Que las armas conserven **exactamente** su caída y rebote tras los cambios de parámetros (se pidió probarlo).
- Que los spawners de armas sigan reapareciendo igual con el arma sostenida moviéndose con la mano.
- Mirar a la izquierda en todas las situaciones (muerte, agarrar con otra orientación, soltar).

## Configuración relevante en el editor

- **Objetos:** `obj_weapon` y `obj_corpse_piece` con **Parent = `obj_holdable`** (botón "Matriz" del objeto);
  `obj_holdable` sin sprite y sin instancias en ninguna room. `obj_corpse_piece` tiene eventos Create,
  **Begin Step**, Step y Draw.
- **Sprites del cadáver:** `spr_corpse_upper` (frame 0 = viva, frame 1 = muerta) y `spr_corpse_lower` (un
  frame, **girado 180° en el editor** para que su orientación sea la correcta); ambos 32x32, Origin (16,16),
  Collision Mask `Automatic, Rectangle`. Los colores del pelaje usan exactamente `#726D67` y `#B1A8A1`.
- **`obj_game_manager` → Create:** además de lo anterior, `corpse_joint_init()` (en esa sección, tras
  `player_shoulder_table_init()`).
- **Capas:** las piezas del cadáver nacen en `layer_items`, como las armas.
- **Controles del afinador del cadáver (jugador 1):** F5 activa/desactiva, F6 cambia de pieza, F7 cambia entre
  punto de unión y de sujeción, Numpad 4/6/8/2 mueven 1 px, P imprime las tablas. (Numpad 0/1/2 también los
  usa el dispositivo de prueba `"keyboard2"`.)
- Sin cambios en Input Map, grupos ni Room Order.

## Siguiente paso: Fase 3, Parte 6

A elección del usuario, en este orden sugerido:
1. **Cerrar la limpieza:** renombrar `WEAPON_*` → `HOLDABLE_*` y `held_weapon` → `held_item`, y decidir
   `DEBUG_TOOLS` o borrar los afinadores.
2. **Probar a fondo** lo que quedó sin confirmación (armas sin cambios, spawners, mirar a la izquierda).
3. **Efectos de game feel:** screenshake y hitstop al matar primero (el cadáver ya está), después partículas
   y sonido.
4. **Cajas y equipamiento** como segundos hijos de `obj_holdable` (`rotates = false` ya está previsto).
5. **ADR del formato de pantalla en celular** y los controles táctiles, antes de diseñar mapas nuevos.
6. Retomar los pendientes heredados: ajustes de partida y color en el lobby, `collision_line` en las balas.
