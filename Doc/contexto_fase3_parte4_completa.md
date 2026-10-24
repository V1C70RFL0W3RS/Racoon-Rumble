# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase1_completa.md`,
`contexto_fase2_completa.md`, `contexto_fase3_parte1_completa.md`, `contexto_fase3_parte2_completa.md`,
`contexto_fase3_parte3_completa.md`, `ADR-001-flujo-de-partida.md`, `ADR-002-camara-y-resolucion.md`,
`guia_documentacion_tecnica.md`,
`Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y `duck_game_biblia.md` si Claude los
pide o para tenerlos de referencia.

## Estado: Fase 3 (Flujo de partida, lobby y menú), Parte 4 — EN CURSO (cierre de sesión)

El usuario decidió dedicar esta parte a la **sensación de juego (game feel)**: que el personaje se
sienta como el de Duck Game, ya que los sprites nuevos están basados en él. Se reemplazó el
movimiento por los **valores de Duck Game de la biblia** (secciones 4.3 y 4.3.1), se movió toda la
lógica de movimiento a un script propio, se alinearon las armas sueltas y el retroceso con esa
física, se implementaron **agacharse y deslizarse** (con su propio ángulo de brazo, con y sin
arma), el **brazo hacia arriba al aletear** y al acercar el arma a una pared deslizando, y se
rehízo la **cámara** para que funcione como la de Duck Game (zoom continuo, límite = tamaño de la
room) con una resolución de dibujo interna más alta. Estilo de trabajo: paso a paso, probando
después de cada cambio, y comprobando cada número contra la biblia en vez de inventarlo.

## Estructura nueva agregada sobre la Fase 3 Parte 3

```
Scripts
└── Player → scr_player_movement                              (NUEVO)
    (modificados: scr_config [reorganizado por secciones], scr_player_input,
     scr_player_state_machine, scr_player_visuals, scr_player_weapon, scr_weapon_data)

Objetos modificados
├── obj_player          → Create (variables nuevas), Step (14 líneas, delega en scr_player_movement)
├── obj_weapon          → Step (fricción en el aire)
├── obj_camera_controller → Create, Room Start, Step (rehechos)
└── obj_game_manager    → Step (guarda de ventana minimizada)

Sprites ya existentes, ahora conectados: spr_player_crouch, spr_player_slide
```

## Clases implementadas / modificadas y su responsabilidad

- **`scr_player_movement`** (NUEVO) — Todo el movimiento del jugador. Punto de entrada
  `player_update_movement(_in)`; el ORDEN importa: `player_update_crouch` → `player_apply_horizontal`
  → `player_apply_gravity` → `player_apply_jump` → `player_move_and_collide`.
  - `player_update_crouch`: decide las banderas `crouching` / `sliding`. Solo actúa en el piso; en el
    aire la pose queda congelada. "Abajo" con `abs(hsp) > PLAYER_SLIDE_MIN_SPEED` inicia el slide;
    una vez iniciado dura hasta soltar "abajo". Si no cabe de pie (techo bajo) se queda abajo.
  - `player_can_stand`: prueba la máscara de pie (`mask_index = spr_player_run`) en la posición
    actual y la restaura con `mask_index = -1`.
  - `player_apply_horizontal`: acelera con tope (`PLAYER_ACCEL`) y SIEMPRE resta fricción después
    (`approach(hsp, 0, fricción)`), en suelo y aire. Agachado o deslizando (también en el aire) no
    se acelera y la fricción vale `PLAYER_FRICTION * PLAYER_CROUCH_FRICTION_MULT`. No se gira
    (`facing`) durante un slide.
  - `player_apply_gravity`: gravedad lineal `PLAYER_GRAVITY` con tope `PLAYER_MAX_FALL_SPEED`, más el
    aleteo: si `hovering` y `vsp >= 0`, la caída se limita a `PLAYER_FLAP_MAX_FALL` y se resta
    `PLAYER_FLAP_LIFT`.
  - `player_apply_jump`: coyote time, jump buffer, salto (consume ambos timers), corte único ×0.5 al
    soltar el botón subiendo (bandera `jumping`), y activación del aleteo con una pulsación NUEVA en
    el aire. No se salta si está bajo y no cabe de pie. El slide-jump no toca `hsp`.
  - `player_move_and_collide` y `player_corner_correct` (empuja hasta `PLAYER_CORNER_CORRECT_PX` en X
    si la cabeza roza una esquina subiendo).
- **`scr_player_input`** — Ahora `move_x` del mando es digital con zona muerta
  (`INPUT_STICK_DEADZONE`). `down_held` ya existía en los tres dispositivos.
- **`scr_player_state_machine`** — `crouching`/`sliding` (banderas de física) tienen prioridad y se
  traducen a `PLAYER_STATE.CROUCH` / `SLIDE`; al soltarlas vuelve a IDLE y el `switch` afina. El
  parámetro `input` quedó sin uso (se dejó para no tocar la llamada).
- **`scr_player_visuals`** —
  - `player_get_sprite` conoce CROUCH. Tabla del hombro ahora por sprite:
    `player_get_shoulder_table(_spr)` (único lugar que relaciona sprite → tabla).
  - `player_get_base_aim_angle`: `aim_up` → 90; si no, ángulo normal o de slide
    (`player_get_slide_aim_angle`), mezclado hacia 90 con `arm_raise` (`lerp`).
  - `player_update_arm_raise` (se llama desde el Step, antes de `player_try_fire`): lleva `arm_raise`
    hacia 1 si hay arma y (aletea, o desliza y `collision_line` desde el hombro, de largo
    `PLAYER_ARM_LENGTH + muzzle_x + PLAYER_ARM_WALL_MARGIN`, toca el tilemap); si no, hacia 0, con
    `PLAYER_ARM_RAISE_SPEED`. Siempre prueba con el ángulo de slide SIN levantar (evita parpadeo).
  - `player_get_arm_angle`: con arma → `weapon_get_aim_angle(...)`; sin arma → 90 aleteando,
    `PLAYER_SLIDE_ARM_FREE_DEG` (espejado con `facing`) deslizando, 270 (colgando) en el resto.
- **`scr_player_weapon`** — `player_apply_kick(_force, _angle)`: el retroceso horizontal REEMPLAZA
  `hsp` si va en contra o es mayor (no se suma); el vertical suma `ky - fuerza * 0.333`; si está
  agachado y el retroceso tiene componente horizontal, inicia un slide. `player_release_weapon`:
  lanzamientos con velocidad ABSOLUTA (corriendo `sign(hsp) * WEAPON_THROW_SPEED`; arriba, sin
  velocidad horizontal).
- **`scr_weapon_data`** — `recoil` pasó a ser el `_kickForce` de Duck Game: base 3 (pistola y Magnum
  lo heredan), escopeta 4, SMG 1.
- **`obj_weapon` (Step)** — Fricción en el aire `WEAPON_AIR_FRICTION` cuando no aterrizó ese frame.
- **`obj_camera_controller`** — Cámara estilo Duck Game (ver decisiones). `center_x`/`center_y` se
  guardan SIN redondear; el redondeo va solo al aplicar `camera_set_view_pos`. Room Start fija
  `view_wport/hport[0]` y hace `surface_resize(application_surface, ...)` a `CAMERA_RENDER_W/H`.
- **`obj_game_manager` (Step)** — `display_set_gui_size` solo si la ventana no está minimizada
  (tamaño > 0).

**Variables nuevas en el Create de `obj_player`:** `coyote_timer`, `jump_buffer`, `jumping`,
`hovering`, `crouching`, `sliding`, `arm_raise`. (TEMPORAL: `shoulder_tune`, `tune_pose`,
`tune_frame`, `tune_angles`.)

**Enum:** `PLAYER_STATE { IDLE, RUN, JUMP, FALL, CROUCH, SLIDE, HURT, DEAD }` (CROUCH agregado).

**Macros finales** (confirmadas por el usuario con su `scr_config` al cierre de la sesión):

| Grupo | Macro = valor |
|---|---|
| Movimiento (biblia 4.3) | `PLAYER_MOVE_SPEED 3.1`, `PLAYER_ACCEL 0.55`, `PLAYER_FRICTION 0.25` (velocidad real al correr: 2.85) |
| Salto | `PLAYER_GRAVITY 0.2`, `PLAYER_JUMP_FORCE -4.9`, `PLAYER_JUMP_CUT_MULT 0.5`, `PLAYER_MAX_FALL_SPEED 8` |
| Aleteo | `PLAYER_FLAP_MAX_FALL 1`, `PLAYER_FLAP_LIFT 0.15` |
| Asistencias | `PLAYER_COYOTE_FRAMES 7`, `PLAYER_JUMP_BUFFER_FRAMES 4`, `PLAYER_CORNER_CORRECT_PX 4` (esta última NO es de Duck Game) |
| Agachado/slide | `PLAYER_SLIDE_MIN_SPEED 1.0`, `PLAYER_CROUCH_FRICTION_MULT 0.28` (fricción 0.07) |
| Brazo en slide | `PLAYER_SLIDE_AIM_DEG 0` (con arma), `PLAYER_SLIDE_ARM_FREE_DEG 0` (sin arma), `PLAYER_ARM_WALL_MARGIN 4`, `PLAYER_ARM_RAISE_SPEED 0.2` |
| Armas sueltas | `GRAVITY 0.2`, `WEAPON_GROUND_FRICTION 0.25`, `WEAPON_AIR_FRICTION 0.175`, `WEAPON_THROW_SPEED 7.5`, `WEAPON_THROW_LIFT -2`, `WEAPON_THROW_UP_SPEED 5`, `WEAPON_KICK_LIFT 0.333` |
| Input | `INPUT_STICK_DEADZONE 0.25` |
| Cámara | `CAMERA_VIEW_W/H 320/180`, `CAMERA_RENDER_W/H 1920/1080`, `CAMERA_ASPECT (W/H)`, `CAMERA_MIN_HEIGHT 60`, `CAMERA_TOP_MARGIN 64`, `CAMERA_BORDER_MIN/MAX 60/90`, `CAMERA_BORDER_REF_W 740`, `CAMERA_POS_LERP 0.05`, `CAMERA_ZOOM_LERP 0.05`, `CAMERA_SNAP_DIST 0.5`, `CAMERA_HARD_MARGIN 24` (no es de Duck Game) |

**Macros eliminadas en esta parte:** `PLAYER_AIR_ACCEL`, `PLAYER_AIR_FRICTION`, `PLAYER_JUMP_MIN_SPEED`,
`PLAYER_FALL_GRAVITY_MULT`, `PLAYER_APEX_*`, `PLAYER_SLIDE_END_SPEED`, `CAMERA_MAX_ZOOM_OUT`,
`CAMERA_PADDING_X/Y`, `CAMERA_FOCUS_Y_OFFSET`, `HAND_OFFSET_X/Y` (ya no existían).

**Tablas del hombro finales** (medidas con el afinador, relativas a `PLAYER_SHOULDER_X/Y`):
`run` = `[0,0] [0,-2] [0,-1] [0,0] [0,-2] [0,-1]`; `jump` = `[0,0] [1,-1] [0,-2]`;
`crouch` = `[1,4]`; `slide` = `[-1,7]`.

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** el jugador "va muy rápido", el salto corto "es muy largo", luego "se siente pesado".
   **Causa real:** al pasar la cámara de 640x360 a 320x180 no se reescalaron las velocidades. Después,
   los valores propuestos eran una división a la mitad mía, no los de Duck Game; y durante las pruebas
   `CAMERA_VIEW` llegó a quedar en 1280x720, lo que hacía ver todo diminuto y lento.
   **Fix:** usar los valores exactos de la biblia (4.3 y 4.3.1), pensados para 320x180, y fijar
   `CAMERA_VIEW_W/H` en 320x180.
2. **Síntoma:** los valores de aceleración/fricción no se sentían como las macros.
   **Causa real:** la línea de `hsp` quedó duplicada en el Step (la vieja arriba y una nueva al final),
   así que la aceleración se aplicaba dos veces por frame.
   **Fix:** `hsp` se calcula una sola vez (hoy dentro de `player_apply_horizontal`).
3. **Síntoma:** al frenar un slide el sprite cambiaba a agachado.
   **Causa real:** el slide terminaba por debajo de `PLAYER_SLIDE_END_SPEED`, umbral tomado del código
   de ejemplo de la sección 11.2 de la biblia (no verificado en el código fuente).
   **Fix:** el slide dura hasta soltar "abajo"; se eliminó la macro.
4. **Síntoma:** al saltar deslizando el sprite volvía a pie, y al disparar agachado no se deslizaba.
   **Causa real:** en el aire se borraban `crouching`/`sliding`; el retroceso suma un empuje vertical
   que despega al jugador unos frames, así que la pose se cancelaba antes de verse.
   **Fix:** en el aire la pose queda congelada hasta aterrizar.
5. **Síntoma:** con la SMG, disparar agachado no iniciaba el slide.
   **Causa real:** la condición era `abs(hsp) > PLAYER_SLIDE_MIN_SPEED` (1.0) y el retroceso de la SMG
   es exactamente 1.0; la fricción baja de slide lo frena entre balas.
   **Fix:** la condición mira si el retroceso tiene componente horizontal (`abs(_kx) > 0.001`), no la
   velocidad resultante.
6. **Síntoma:** deslizando se podía mover y aletear en el aire.
   **Causa real:** un cambio mío exigía estar en el suelo para contar como "bajo".
   **Fix:** `_low = crouching || sliding` sin exigir suelo, y el aleteo no se activa si
   `crouching || sliding`.
7. **Síntoma:** el cuerpo del sprite de slide no cambiaba de color en el jugador teñido (cabeza y cola sí).
   **Causa real:** el cuerpo usaba `#69645F`, `#A39B95` y `#302C28` (~8 % más oscuros) en vez de los
   colores clave `#726D67`, `#B1A8A1` y `#34302C`; el shader solo tiñe los exactos.
   **Fix:** corregir el arte (hecho por el usuario). Falta revisar los demás sprites.
8. **Síntoma:** el afinador del hombro aplicaba el mismo ángulo de brazo a todas las poses.
   **Causa real:** el ángulo forzado era una sola variable (`tune_angle`).
   **Fix:** tabla `tune_angles[pose][frame]`.
9. **Síntoma (riesgo, corregido antes de probarlo):** `player_can_stand` podía dejar la máscara
   fijada al sprite actual. **Causa real:** restaurar `mask_index` con el valor leído, que puede ser
   el id del sprite en vez de `-1`. **Fix:** restaurar siempre con `-1`.
10. **Síntoma:** personajes que se salen de la cámara en una room de 1280x720.
    **Causa real:** el zoom máximo era 2x (640x360) y la room mide 4x la vista base; además el lerp
    iba atrasado en caídas rápidas, se medían los pies y no el cuerpo, y un tope por tamaño de room
    (agregado por error) impedía alejarse lo suficiente.
    **Fix:** cámara estilo Duck Game (ver decisiones) más una garantía dura de margen.
11. **Síntoma:** píxeles desparejos mientras cambia el zoom.
    **Causa real:** la imagen se dibujaba a 640x360 (viewport de la room); con zoom no entero, cada
    píxel del mundo ocupa 1 o 2 píxeles (50 % de error).
    **Fix:** `view_wport/hport` y `application_surface` a 1920x1080 (error de ~17 %); además, el
    zoom se fija exacto al llegar (`CAMERA_SNAP_DIST`) para no quedar fraccionario en reposo.

## Decisiones de diseño explícitas tomadas en esta parte

- **Valores de movimiento de Duck Game, no estimaciones propias.** Las escalas coinciden (vista
  320x180, sprites 32x32). La fricción se resta SIEMPRE, después de acelerar (velocidad real 2.85).
  Sin gravedad asimétrica ni hang time. **Descartados:** gravedad ×1.4 al caer y ×0.5 en la cima
  (propuestos al inicio; Duck Game no los usa, el aleteo cumple esa función); límite continuo de
  subida `PLAYER_JUMP_MIN_SPEED` (reemplazado por el corte único ×0.5 al soltar, que es el original).
- **Aleteo con pulsación nueva en el aire** (biblia P9), no manteniendo el botón desde el suelo;
  se apaga al soltar o aterrizar.
- **Movimiento en un script propio** (`scr_player_movement`): el Step de `obj_player` pasó de ~40 a
  14 líneas y cada pieza se afina por separado (mismo patrón que input, estados y visuales).
- **Banderas de física como fuente de verdad** (`crouching`/`sliding`); el estado visual se deduce
  de ellas en la máquina de estados, para no tener dos lugares que decidan lo mismo.
- **Agacharse solo en el piso; sin aceleración agachado o deslizando** (del ejemplo de la 11.2,
  no verificado en el código fuente); slide hasta soltar "abajo" (decisión del usuario); no se
  puede saltar ni levantarse con el techo encima (evita incrustarse en el tilemap).
- **Slide-jump:** conserva toda la velocidad, mantiene la pose de slide hasta aterrizar, sin
  control en el aire (decisión del usuario). Consecuencia: llega muy lejos (fricción 0.07);
  se ajusta con `PLAYER_CROUCH_FRICTION_MULT`.
- **Armas alineadas con el jugador:** gravedad 0.2, fricción 0.25/0.175 y retroceso como P8/P10.
  Lanzamientos con velocidad absoluta (no suman `hsp`).
- **Brazo:** ángulo propio al deslizar (con y sin arma) y `arm_raise` común para "arma contra la
  pared" y "aleteando con arma", siempre con transición suave. **Descartado:** interpolar el brazo
  SIN arma al aletear (iría de 270° a 90° pasando por detrás del cuerpo); ahí cambia al instante.
- **Hombro por sprite y frame**, afinado en vivo con una herramienta temporal (no a ojo en el editor).
- **Cámara continua como Duck Game** (decisión del usuario: "no usemos zoom fijos"): se mide la caja
  del cuerpo (`bbox_*`) de los jugadores vivos, recortada a la room (con `CAMERA_TOP_MARGIN` sobre el
  techo); borde dinámico entre 60 y 90 px según el ancho de la vista; la altura se limita entre 60 px
  y la room entera; el ancho siempre sale de la altura (16:9); lerp 0.05. **Descartados:**
  `CAMERA_MAX_ZOOM_OUT` fijo (2x, luego 4x) y margen fijo de 64 px. Regla de diseño que surge: el
  zoom máximo es la room entera, así que un mapa grande implica personajes más pequeños en pantalla.
  Formalizado en **`ADR-002-camara-y-resolucion.md`**.
- **Garantía dura de margen en la cámara** (`CAMERA_HARD_MARGIN`): NO es de Duck Game; evita que
  alguien salga de la vista cuando el lerp va atrasado. Es borrable (un bloque marcado en el Step).
- **Resolución de dibujo interna 1920x1080** (6x la vista base) con la `application_surface`
  redimensionada; el viewport del editor (640x360) solo vale hasta el primer Room Start. Si pesa en
  celular, bajar a 1280x720 cambiando solo las dos macros (exactos 1x, 2x, 4x).
- **Redondeo de la cámara solo al aplicarla**, nunca al guardar el centro (si se redondeara el
  estado, la interpolación se trabaría a menos de 5 px del objetivo).

## Pendiente identificado, no bloqueante

TEMPORAL / deuda a propósito, documentada:
- **Afinador del hombro:** borrar la sección "TEMPORAL" de `scr_player_visuals`
  (`player_debug_arm`, `player_debug_shoulder`, `player_debug_tune_shoulder`,
  `player_debug_set_shoulder`), la llamada en el Step de `obj_player`, la de `player_debug_arm` en
  el Draw, las variables `shoulder_tune/tune_pose/tune_frame/tune_angles` del Create, y el bloque
  `if (shoulder_tune)` de `player_get_arm_angle`.
- **Pendiente de verificar contra el código fuente real** (DuckGameRebuilt: `Duck.cs`,
  `PhysicsObject.cs`, `Gun.cs`), porque la biblia no los resuelve o se contradice:
  fricción en el aire del pato (0.25 en P1 vs 0.175 en P6); cómo termina un slide y qué hace
  `slideBuildup`; si un pato agachado puede caminar, agacharse en el aire, o saltar/disparar.
- **Peso del arma (P7):** decidir si las armas de fuego frenan al jugador y/o bloquean el aleteo
  (el aleteo exige `weight <= 5`; con los pesos de diseño sugeridos las escopetas lo bloquearían).
  Hoy ninguna arma pesa nada ni frena.
- **Soltar el arma agachado:** en Duck Game cae con `hsp = vsp = 0` (biblia 4.4.4); no implementado.
- **Revisar los colores clave** de `spr_player_crouch`, `spr_player_jump`, `spr_player_ragdoll`
  y `spr_player_arm` (cuentagotas o script de paleta); confirmar `spr_player_slide` ya corregido.
- **Formato de pantalla en celular:** decidir barras negras (como Duck Game) o más mundo a los lados
  en pantallas más alargadas (19.5:9). Las opciones de Game Options de abajo son solo de Windows.
- **Ventana inicial:** se propuso abrirla a 4x la vista (1280x720) al final del Create de
  `obj_game_manager`; verificar si se aplicó.
- **Sincronización vertical desactivada:** activarla antes de publicar.
- **Efectos del plan de game feel, sin empezar:** screenshake (función única en la cámara), hitstop
  al matar, partículas de disparo y muerte, polvo y squash/stretch, sonido.
- **Apuntado de ángulo libre** (ratón, stick derecho, táctil): sigue en 3 direcciones.
- Parámetro `input` sin uso en `player_update_state`; limpiar junto con la llamada del Step.

Heredados de fases anteriores (siguen sin resolver):
- (Heredado de Fase 1) Sprite propio para `FALL` (usa el frame de caída de `spr_player_jump`),
  `obj_room_controller` sin uso, `spr_player_run_gun`/`_2` sin conectar, capa de red, `.gitattributes`.
- (Heredado de Fase 2) Balas que atraviesan jugadores a alta velocidad (pasar a `collision_line`),
  bala naciendo dentro de una pared, `weapon_resolve_overlap` en pasillos muy estrechos, sin
  indicador de "clic vacío", recarga ni munición, sin efecto de muerte, retoques del kick.
- (Heredado de Fase 3 Parte 1) Dispositivo `"keyboard2"` (decidir si se retira antes del release),
  `rm_intermission` sin uso.
- (Heredado de Fase 3 Parte 2) Ajustes de partida configurables desde el lobby (`MATCH_DEFAULT_*`
  siguen fijos), controles táctiles, pulido visual de menú/lobby/intermission, spawners de armas en
  `rm_map_sandbox_2`.
- (Heredado de Fase 3 Parte 3) Elegir color desde el lobby (hoy se asigna solo), ragdoll/cadáver
  (la muerte sigue ocultando al jugador; `spr_player_ragdoll` aparece sin usar en el compilador),
  assets sin usar del compilador (`spr_player_idle_2`, `spr_*_dec`, tilesets y fondos).

Resuelto en esta parte: escala del personaje (se eligió la vista base 320x180), mecánica FLAP,
estados y sprites de agacharse y deslizarse (con su máscara baja), `HAND_OFFSET_*` (las macros ya no
existen), tabla del hombro de `spr_player_jump`, y la prueba de cámara con una room grande (1280x720).

## Verificaciones hechas al cierre de esta parte

Confirmadas por el usuario:
- El movimiento y el salto con los valores de Duck Game y la vista de 320x180 ("ya me parece mejor").
- El ángulo del brazo con arma al deslizar ("ya está bien con el arma").
- El brazo y el arma subiendo con transición suave al aletear con arma ("ya quedó").
- El proyecto compila y arranca sin errores en VM (registro de la consola).
- La cámara nueva estilo Duck Game funciona.
- El render interno a 1920x1080.
- El retroceso con la pistola y la escopeta.

Sin confirmación explícita (código entregado, pendiente de probar a fondo):
- Rendimiento del render a 1920x1080 en celular (solo se confirmó en PC).
- Slide al disparar agachado con Magnum y con la SMG tras la corrección.
- Los colores del sprite de slide en un jugador teñido tras corregir el arte.

## Configuración relevante en el editor

- **Game Options → Windows → Graphics:** `Interpolate colours between pixels` desactivado;
  `Keep aspect ratio` activado; `Allow window resize` activado; `Allow fullscreen switching`
  activado; `Start in fullscreen` desactivado; `Use synchronization to avoid tearing` desactivado;
  `Texture page size` 2048x2048.
- **`rm_level_template` → View 0:** viewport y cámara a 640x360 (valores del editor). El tamaño real
  de dibujo lo fija `obj_camera_controller` en cada Room Start (`view_wport/hport` y
  `application_surface` a `CAMERA_RENDER_W/H`). Comprobar que las rooms de mapa heredan View 0.
- **Rooms de mapa:** la room que se usó para probar la cámara mide 1280x720.
- **Máscaras de colisión por sprite** (cada pose su sprite): `spr_player_run` (de pie, usada también
  por `player_can_stand`), `spr_player_crouch` y `spr_player_slide` más bajas, con el origin debajo de
  los pies. `spr_player_slide` debe usar EXACTAMENTE los colores clave del pelaje.
- **Colores clave del shader de tinte:** `#726D67`, `#B1A8A1` (se tiñen); fijos: `#000000`,
  `#34302C`, `#FFFFFF`, `#9E0B0F`.
- **Controles añadidos/confirmados:** teclado: S = agacharse/deslizar (junto a W arriba, E agarrar,
  Espacio saltar); `"keyboard2"`: flecha abajo; mando: stick izquierdo hacia abajo (> 0.5).
  Afinador temporal (jugador 1): F1 activa, F2 cambia de sprite, F3 de frame, I/K/J/L mueven el
  hombro, U/O rotan el brazo (Shift = 1°), H resetea, P imprime tablas y ángulos.
- Sin cambios en Input Map, grupos ni Room Order.

## Siguiente paso: Fase 3, Parte 5

A elección del usuario, en este orden sugerido:
1. **Probar la cámara a fondo** y limpiar lo temporal (afinador del hombro, depuración del brazo).
2. ~~Escribir el ADR-002~~ (hecho: `ADR-002-camara-y-resolucion.md`). Abrir un ADR-003 solo
   cuando se decida el formato de pantalla en celular.
3. **Decidir el formato en celular** (barras negras o más mundo en pantallas alargadas) y la zona de
   los controles táctiles, antes de diseñar mapas nuevos.
4. **Efectos de game feel:** screenshake y hitstop primero (una función cada uno), después
   partículas de disparo y muerte, y sonido.
5. Retomar los pendientes de la Parte 2/3: ajustes de partida y selección de color en el lobby,
   spawners en el segundo mapa, balas con `collision_line`.
