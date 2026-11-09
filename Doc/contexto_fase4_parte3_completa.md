# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `plan_fase4_armas_fisicas_y_efectos.md`,
`contexto_fase4_parte2_completa.md`, `contexto_fase4_parte1_completa.md`, `ADR-001-flujo-de-partida.md`,
`ADR-002-camara-y-resolucion.md`, `ADR-003-objetos-agarrables.md`, `ADR-004-balas-por-segmento-y-municion.md`,
`guia_documentacion_tecnica.md`, `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y
`duck_game_biblia.md` si Claude los pide o para tenerlos de referencia.

## Estado: Fase 4 (Armas, físicas y efectos), Parte 3 — Fase B del plan (Ciclo de vida del arma) + efectos de disparo — COMPLETA

Esta parte cerró los dos pendientes de calidad heredados de la Parte 1 (soltar el arma agachado y el sprite al
terminar un slide) y completó la Fase B del plan: clic vacío, munición visible (como opción de accesibilidad),
despawn del arma vacía con humo, recarga manual (escopeta de bombeo) y kick lineal. Además se rehicieron los
sprites de las cuatro armas a la escala y paleta del mapache, y, tomando como referencia un video de la SMG de
Duck Game, se agregaron los efectos de disparo: estela de bala, chispas en la pared, fogonazo, casquillos y humo
del cañón. También se cambiaron los controles de teclado (ya no se usa el mouse).

**Forma de trabajo nueva en esta parte:** Claude edita directamente los archivos del proyecto (carpeta
`GameMakerProjects/Racoon-Rumble` conectada desde la app de escritorio). Reglas acordadas:
- Los **assets nuevos** (scripts, objetos, sprites) los crea el usuario **vacíos** en el IDE; Claude escribe su
  contenido (o el usuario pega el código). Crear assets a mano exige registrarlos en el `.yyp` y es frágil.
- Después de cada cambio de Claude, en el aviso de GameMaker elegir **Recargar**, nunca Guardar (guardar pisa los
  cambios externos; pasó una vez con `PLAYER_ARM_LENGTH` y hubo que reaplicarlo).
- Claude no puede ejecutar el juego: el usuario prueba y confirma después de cada paso.

## Estructura nueva agregada sobre la Fase 4 Parte 2

```
Scripts
└── Core
    ├── scr_audio      (NUEVO) audio_play_sfx: punto único para reproducir sonidos
    ├── scr_settings   (NUEVO) global.settings: ajustes del jugador (accesibilidad)
    └── scr_fx         (NUEVO) partículas (humo, chispas, fogonazo, humo de cañón) + casquillos
    (modificados: scr_config, scr_player_movement, scr_player_weapon, scr_player_visuals,
     scr_player_input, scr_weapon_data, scr_weapon_actions, scr_ammo_data, scr_projectile,
     scr_holdable, scr_ui_draw)

Objects
├── Effects → obj_fx_shells   (NUEVO) un controlador de casquillos por room (Create/Step/Draw)
├── obj_projectile → Draw     (NUEVO evento: dibuja la estela)
└── modificados: obj_weapon (Create/Step, máscara), obj_holdable (Create), obj_player (Create/Step/Draw),
    obj_game_manager (Create, Room Start)

Sprites
└── Weapons/Guns → spr_weapon_pistol, spr_weapon_magnum, spr_weapon_smg, spr_weapon_shotgun (NUEVOS)
    (spr_weapon_shotgun tiene 2 frames: 0 = normal, 1 = corredera atrás)

Doc/arte/armas  (NUEVO) PNG fuente de las armas, vista previa y armas_pixelart.py (script que las genera)
```

Sprites renombrados por el usuario con sufijo `_desc` (descartados): `spr_weapon_gun_1_desc`,
`spr_weapon_gun_2_desc`, `spr_bullet_desc`, `Spr_Racoon_*_dec`. **Ojo: `spr_bullet_desc` sigue siendo el sprite
(y por lo tanto la máscara de colisión) de `obj_projectile`; no se puede borrar** sin asignarle otro.

## Clases implementadas / modificadas y su responsabilidad

### Movimiento y agarre (pendientes heredados de la Parte 1)
- **`scr_player_weapon` → `player_release_item`**: primer caso nuevo: agachado o deslizando, el arma se suelta en
  la mano **sin impulso ni giro** (cae). Va antes que "mirar arriba".
- **`scr_player_movement`**:
  - `player_apply_jump`: al despegar desde un slide **ya detenido** (`abs(hsp) < PLAYER_SLIDE_STOP_SPEED`) pasa a
    `crouching`; deslizando en movimiento conserva el slide todo el salto. Se decide **una sola vez, al despegar**.
  - `player_fits_mask(_spr)`: ¿cabe la máscara de un sprite en la posición actual? `player_can_stand()` ahora la usa.

### Armas: ciclo de vida
- **`scr_weapon_actions`**:
  - `weapon_try_fire`: orden de comprobación → cadencia → **sin balas: `weapon_dry_fire`** → **sin recargar:
    `weapon_rack`** → disparo. Al disparar: fogonazo (uno por disparo), balas, kick angular con **bamboleo**,
    kick lineal (`recoil_back`), calor, casquillo (si no tiene `needs_rack`), `chambered = false` (si tiene).
  - `weapon_dry_fire`: cadencia propia, tirón (reusa `kick`), destello gris en la boca, `audio_play_sfx(snd_empty)`.
  - `weapon_draw_dry_flash`: dibuja ese destello.
  - `weapon_rack(_weapon, _x, _y, _facing)`: recarga manual; arranca `rack_timer` (animación de la corredera) y
    expulsa el cartucho.
  - `weapon_update_despawn`: arma **vacía, suelta y quieta** → espera `WEAPON_EMPTY_DESPAWN_DELAY`, se desvanece
    `WEAPON_DESPAWN_FADE_FRAMES`, humo y `instance_destroy`. Agarrarla cancela; una vez desvaneciéndose termina igual.
  - `weapon_update_smoke`: humo del cañón según el calor (ver efectos).
  - `weapon_debug_muzzle`: ahora usa `debug_draw_dot`.
- **`obj_weapon`**: variables nuevas `dry_flash`, `chambered` (empieza en `true`), `rack_timer`, `wobble_phase`,
  `heat`, `since_shot`, `empty_rest_timer`. Step: recupera `kick` y `recoil_back`, elige `image_index` (frame de
  corredera durante la primera mitad de la recarga), humo y, **al final**, despawn (puede destruir la instancia).
  **Máscara de colisión: "Same as Sprite"** (antes estaba fijada a `spr_obj_weapon`, 16x16 con origen arriba a la
  izquierda: con las armas chicas las hacía flotar).
- **`obj_holdable`**: `recoil_back = 0` (junto a `kick`); `holdable_draw` usa `_h.image_alpha` (para el desvanecido).

### Datos de armas (`WeaponDef`, `scr_weapon_data`)
Campos nuevos (con su valor por defecto):

| Campo | Defecto | Para qué |
|---|---|---|
| `snd_empty` | `undefined` | sonido del clic vacío |
| `needs_rack` | `false` | recarga manual con el mismo botón tras cada disparo |
| `rack_delay` | 15 | frames de la recarga |
| `snd_rack` | `undefined` | sonido de la recarga |
| `rack_frame` | -1 | frame del sprite con la corredera atrás |
| `flash_count` | 6 | partículas del fogonazo |
| `shell_len` / `shell_width` / `shell_color` | 3 / 1 / latón | casquillo (largo 0 = ninguno) |
| `heat_per_shot` | 0.2 | calor por disparo (humo del cañón) |
| `kick_wobble` / `kick_wobble_speed` / `kick_wobble_chaos` | 0 / 1 / 0 | bamboleo (onda seno con ritmo al azar) |
| `kick_back` / `kick_back_recovery` | 0 / 0.5 | kick lineal en px |

Valores por arma al cierre:

| | Pistola | Magnum | SMG | Escopeta |
|---|---|---|---|---|
| sprite | `spr_weapon_pistol` | `spr_weapon_magnum` | `spr_weapon_smg` | `spr_weapon_shotgun` |
| `muzzle_x / muzzle_y` | 11 / -3 | 17 / -3 | 12 / -3 | 18 / -2 |
| `fire_delay` | (sin cambio) | (sin cambio) | **6** (antes 4) | **15** (antes 30) |
| `spread` | — | — | **8** | 20 |
| kick | — | — | `kick_up 1`, `jitter 4`, `wobble 10`, `speed 0.9`, `chaos 0.7`, `max 30` | — |
| `kick_back` / recup. | 2 / 0.5 | 3 / 0.4 | 1 / 0.5 | 3 / 0.4 |
| `flash_count` | 6 | 12 | 4 | 14 |
| casquillo | latón 3 px | ninguno (revólver) | latón 2 px | rojo 4×2, **al recargar** |
| `heat_per_shot` | 0.2 | 0.45 | 0.07 | 0.5 |
| recarga | — | — | — | `needs_rack`, `rack_delay 15`, `rack_frame 1` |

### Munición (`AmmoDef`, `scr_ammo_data`)
Campos nuevos de la estela: `trail_length` (px), `trail_color`, `trail_width` (px).
LIGHT 24 / blanco / 2 — HEAVY 40 / blanco / 3 — PELLET 12 / blanco / 1. Velocidad y alcance siguen provisionales
(Paso 4 de la Parte 2, diferido).

### Balas (`scr_projectile`, `obj_projectile`)
- `projectile_spawn` pasa también `start_x/start_y` (boca del cañón) y los datos de la estela.
- `projectile_draw_trail`: la bala se dibuja como **estela** (opaca en la punta, transparente en la cola); con
  grosor 1 es una línea, con más es un `pr_trianglestrip`. Crece desde la boca, así nunca atraviesa el arma.
  El sprite de la bala ya no se dibuja (solo es máscara).
- `projectile_wall_contact`: punto exacto de impacto contra el muro (avanza de a 1 px desde el centro, devuelve el
  último píxel libre). Se usa para las chispas.
- `obj_projectile` Step: al chocar con pared → `fx_bullet_sparks` en el punto de contacto.

### Efectos (`scr_fx`, `obj_fx_shells`)
- `fx_init()` (en el Create de `obj_game_manager`) crea los **tipos** de partícula: `global.fx_smoke`,
  `global.fx_spark`, `global.fx_muzzle`, `global.fx_barrel_smoke`.
- `fx_get_system()`: sistema de partículas creado al usarlo (se pierde al cambiar de room); en `layer_effects`
  si existe.
- `fx_smoke_puff`, `fx_bullet_sparks(_x,_y,_dir)`, `fx_muzzle_flash(_x,_y,_dir,_count)`, `fx_barrel_smoke`.
- **Casquillos**: no son instancias. Viven como structs en el arreglo `shells` de **un** `obj_fx_shells` por room
  (lo crea `obj_game_manager` en Room Start si existe `layer_effects`). `fx_shell_spawn` (tope `SHELL_MAX`, borra
  el más viejo), `fx_shells_update` (colisión de un punto con `tilemap_get_at_pixel`; los que reposan no calculan
  nada) y `fx_shells_draw` (línea rotada con `draw_line_width_colour`, desvanecido final).

### Jugador
- `scr_player_visuals`:
  - `player_arm_reach()`: hombro → mano = `PLAYER_ARM_LENGTH - recoil_back` del objeto en la mano.
  - `player_hand_x/y`: dos medidas, como la boca del cañón: largo del brazo + desvío perpendicular
    `PLAYER_HAND_OFFSET` (× `facing`).
  - `player_draw_ammo_pips()`: puntitos de munición sobre la cabeza (si `global.settings.show_ammo_pips`).
  - Depuración del hombro y la mano con `debug_draw_dot`.
- `obj_player`: `ammo_pips_timer` (Create), cuenta regresiva en Step, puntitos en Draw (fuera del shader),
  destello del clic vacío en Draw. Se quitó un bloque `TEMPORAL` del afinador que estaba **duplicado** en el Create.
- `scr_player_input`: teclado sin mouse (ver Configuración).

### Sistemas base nuevos
- **`scr_settings`** → `settings_init()` crea `global.settings = { show_ammo_pips: false }`. Se llama **primero**
  en el Create de `obj_game_manager`. Hoy solo en memoria; es la base para el futuro menú de opciones.
- **`scr_audio`** → `audio_play_sfx(_snd, _pitch_var = 0.05)`: si el sonido es `undefined` no hace nada (permite
  programar avisos antes de tener los .wav); variación leve de tono.
- **`scr_ui_draw`** → `debug_draw_dot(_x,_y,_col)`: cuadro de `(2·DEBUG_DOT_HALF+1)` px.

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** las armas nuevas (chicas) quedaban flotando sobre el piso al estar quietas.
   **Causa real:** `obj_weapon` tenía fijada en el editor la máscara `spr_obj_weapon` (16x16, origen arriba a la
   izquierda): colgaba ~13 px bajo el agarre. Con las armas viejas, enormes, no se notaba. Boca abajo la máscara
   se voltea y por eso en esa pose sí tocaba el piso.
   **Fix:** máscara "Same as Sprite" (`spriteMaskId: null`).
2. **Síntoma:** el punto de agarre (amarillo) quedaba delante de la pata y el arma se veía despegada.
   **Causa real:** la mano se calcula en línea recta a `PLAYER_ARM_LENGTH` (9) del hombro, pero `spr_player_arm`
   mide ~6 px y está dibujado en diagonal **a propósito**.
   **Fix:** `PLAYER_ARM_LENGTH` 9 → **4** y nueva `PLAYER_HAND_OFFSET` = **-1** (desvío perpendicular). El usuario
   eligió no tocar el sprite.
3. **Síntoma:** al saltar deslizando en movimiento, a mitad del salto cambiaba a la pose de agachado.
   **Causa real:** la conversión slide→agachado se revisaba en cada frame del aire, y la fricción frenaba el
   slide-jump por debajo del umbral.
   **Fix:** se decide una sola vez, en `player_apply_jump`, al despegar.
4. **Síntoma:** las chispas salían 3–5 px antes de la pared.
   **Causa real:** `move_and_collide` detiene la bala cuando el **borde** de su máscara (8 px) toca el muro, pero
   `x,y` es el **centro**.
   **Fix:** `projectile_wall_contact`.
5. **Incidente de proceso:** el usuario eligió "Guardar" en vez de "Recargar" y el IDE pisó `scr_config`.
   Se verificó cambio por cambio y solo se había perdido `PLAYER_ARM_LENGTH`; se reaplicó.

## Decisiones de diseño explícitas tomadas en esta parte

- **Soltar agachado/deslizando = dejar caer**, y tiene prioridad sobre "arriba" (agachado nunca lanza).
- **Slide detenido en el piso conserva la pose de slide**; solo al saltar desde él pasa a agachado (el usuario
  corrigió la primera versión, que lo convertía al frenar).
- **Clic vacío visual + sonido** con cadencia propia (`WEAPON_DRY_FIRE_DELAY`) para que una automática no haga
  clic en cada frame; sin retroceso al jugador.
- **Puntitos de munición = opción de accesibilidad, desactivada por defecto** (decisión del usuario). Duck Game no
  muestra munición.
- **Despawn del arma vacía sin tocar el spawner:** si su arma deja de existir, el punto queda libre y su cuenta
  regresiva genera otra. El arma vacía puede quedar boca abajo (decisión del usuario: se mantiene).
- **Efectos con el sistema de partículas**, no con instancias (humo, chispas, fogonazo, humo de cañón).
- **Casquillos como structs en un controlador por room**, no instancias: necesitan físicas y quedarse en el piso,
  y siguen siendo baratos en celular (tope 60, 10 s de vida, los que reposan no calculan).
- **Recarga manual por datos (`needs_rack`)**: un rifle de cerrojo futuro solo activa el flag. Sin balas no se
  recarga (suena el clic). `chambered` se conserva al soltar el arma. La escopeta mantuvo su ritmo total
  (15 disparo + 15 recarga = 30, como antes).
- **La escopeta expulsa el cartucho al recargar; la Magnum no expulsa** (revólver).
- **Kick lineal acorta el brazo** (`player_arm_reach`), así mano, arma, boca del cañón y posición sostenida siguen
  el retroceso sin código extra.
- **Bamboleo de la SMG:** el descontrol viene del balanceo del arma (onda seno con ritmo al azar), no de más
  dispersión: con `spread 16` + balanceo ya no acertaba (se volvió a 8).
- **Sprites de armas:** a la escala de Duck Game (13–27 px), contorno negro de 1 px y la paleta cálida del mapache
  (más café de madera). Origen = agarre. Claude no pudo abrir la wiki de Duck Game (bloquea accesos
  automáticos); se diseñó desde el conocimiento general de su estilo.
- **Controles de teclado sin mouse:** C agarrar, V disparar. El salto sigue en Espacio porque W ya es "apuntar
  arriba" (pendiente de confirmar si el usuario quiere otra tecla).

## Pendiente identificado, no bloqueante

Nuevo en esta parte:
- **Sonidos:** `snd_empty` y `snd_rack` están en `undefined`. Al importar `snd_weapon_empty` (y uno de recarga),
  asignarlos en `WeaponDef` (o por arma).
- **Menú de opciones y ajustes persistentes:** `global.settings` vive solo en memoria; falta la casilla de
  `show_ammo_pips` y guardarlo en archivo (se suma al pendiente de la escala de GUI).
- **La estela termina en el centro de la bala** al chocar (unos px antes del muro) y desaparece de golpe; en Duck
  Game queda un instante desvaneciéndose. Si se nota, estirarla con `projectile_wall_contact`.
- **Humo/chispas/fogonazo sin verificar en rooms sin `layer_effects`** (se crea un sistema sin capa, depth por
  defecto).
- **Tecla de salto:** confirmar si se queda en Espacio.
- Ajustes finos que el usuario dejó "bien por el momento": tiempo de recarga, tamaño del fogonazo, cantidad de
  humo, fuerza de los casquillos.
- `spr_bullet_desc` sigue en uso como máscara de `obj_projectile` (no borrar).

Heredados que siguen sin resolver:
- (Fase 4 Parte 2) **Paso 4: velocidad y alcance definitivos de LIGHT/HEAVY/PELLET** (provisionales 20/400,
  24/500, 20/150); brazo que sube con pared al frente estando de pie; balas que no detectan holdables (cadáver);
  `projectile_find_hit` elige el más cercano por distancia al centro; `weapon_debug_muzzle` TEMPORAL.
- (Fase 1) Sprite propio para `FALL`; diseño de la capa de red (LAN primero).
- (Fase 2) `holdable_resolve_overlap` en pasillos estrechos; sin efecto de muerte.
- (Fase 3) `"keyboard2"` TEMPORAL; `rm_intermission` sin uso; ajustes de partida desde el lobby; controles
  táctiles; pulido visual de menú/lobby; spawners en `rm_map_sandbox_2`; mapa más grande para la cámara; elegir
  color en el lobby; borrar assets sin usar (fase final); peso del arma (P7); vsync; `corpse_spawn` hace varias
  cosas; piezas del cadáver sin la dirección del disparo.
- (Fase 4 Parte 1) `WEAPON_CHOICE_RANDOM` y `WEAPON_CHOICE_RANDOM_LOCKED` en archivos distintos;
  `Release:DEBUG_TOOLS false` por confirmar.

Resueltos en esta parte: soltar el arma agachado/deslizando; sprite al terminar un slide; clic vacío; munición
visible; despawn del arma vacía; kick lineal; recarga manual; sprites propios de Magnum y SMG (fin del sprite
prestado); armas sueltas flotando; estela visual de la bala (pendiente de la Parte 2).

## Verificaciones hechas al cierre de la fase

Confirmadas por el usuario:
- Slide: detenido en el piso conserva el sprite; saltando en movimiento conserva el slide; saltando detenido pasa a
  agachado.
- Soltar el arma agachado o deslizando la deja caer.
- Sprites nuevos con agarre correcto en la mano; puntos de depuración (hombro, mano, boca del cañón) visibles y en
  su lugar; mano ajustada a 4 / -1.
- Puntitos de munición funcionan (con la opción activada).
- Arma vacía quieta: se desvanece con humo y el spawner la repone.
- Escopeta: disparar → recargar → disparar; corredera animada; tiempo de recarga correcto.
- Estela de bala, grosor por munición, chispas en el punto correcto de la pared.
- SMG: cadencia 10 balas/s, balanceo caótico aceptado ("así está bien").
- Fogonazo, casquillos (incluido el cartucho rojo al recargar) y humo del cañón funcionan.

Sin confirmación explícita: el clic vacío (tirón + destello) se implementó antes de los sprites nuevos y no se
reportó una prueba específica; controles nuevos C/V recién cambiados.

## Configuración relevante en el editor

- **`obj_weapon`** → Collision Mask: **Same as Sprite**.
- **`obj_projectile`** → eventos Create, Step y **Draw** (nuevo). Sprite/máscara: `spr_bullet_desc`.
- **`obj_fx_shells`** (Objects/Effects) → sin sprite, no se coloca en rooms. Create: `shells = []`,
  `tilemap = layer_tilemap_get_id("layer_collision")`; Step: `fx_shells_update()`; Draw: `fx_shells_draw()`.
- **`obj_game_manager` → Create** (orden): `settings_init()`, `fx_init()`, `weapon_data_init()`,
  `ammo_data_init()`, … **Room Start:** al final crea `obj_fx_shells` si existe `layer_effects`.
- **Sprites de armas** (origin = agarre, máscara automática rectangular):

| Sprite | Tamaño | Origin |
|---|---|---|
| `spr_weapon_pistol` | 14×10 | 3, 5 |
| `spr_weapon_magnum` | 19×11 | 2, 7 |
| `spr_weapon_smg` | 17×11 | 5, 6 |
| `spr_weapon_shotgun` | 27×7 (2 frames) | 9, 4 |

  Si se mueve un origen, `muzzle_x/muzzle_y` cambian en la misma cantidad pero al revés.
- **Controles de teclado** (`scr_player_input`): A/D mover, W/S arriba/abajo (agacharse/deslizar), Espacio saltar,
  **C agarrar/tirar**, **V disparar**. Lobby: Espacio unirse, Enter empezar (sin cambios).
- **`scr_config`** — macros nuevas o cambiadas:
  - `DEBUG_DOT_HALF 1`
  - `PLAYER_ARM_LENGTH 4` (antes 9), `PLAYER_HAND_OFFSET -1`
  - `PLAYER_SLIDE_STOP_SPEED 0.3`
  - `WEAPON_DRY_FIRE_DELAY 18`, `WEAPON_DRY_KICK 4`, `WEAPON_DRY_FLASH_FRAMES 5`
  - `WEAPON_EMPTY_DESPAWN_DELAY 60`, `WEAPON_DESPAWN_FADE_FRAMES 20`, `FX_SMOKE_COUNT 8`,
    `FX_SPARK_COUNT 6`, `FX_SPARK_SPREAD 55`, `FX_MUZZLE_SPREAD 25`, `PROJECTILE_CONTACT_SEARCH 12`
  - `WEAPON_HEAT_DECAY 0.004`, `WEAPON_SMOKE_DELAY 10`, `WEAPON_SMOKE_MIN 0.05`, `WEAPON_SMOKE_RATE 0.35`
  - `SHELL_MAX 60`, `SHELL_LIFE 600`, `SHELL_FADE 60`, `SHELL_GRAVITY 0.2`, `SHELL_MAX_FALL 6`,
    `SHELL_BOUNCE 0.45`, `SHELL_REST_SPEED 1.0`, `SHELL_FRICTION 0.6`, `SHELL_COL_BRASS`, `SHELL_COL_RED`
  - `AMMO_PIPS_SHOW_FRAMES 90`, `AMMO_PIPS_FADE_FRAMES 20`, `AMMO_PIPS_PER_ROW 10`, `AMMO_PIPS_SIZE 2`,
    `AMMO_PIPS_GAP 1`, `AMMO_PIPS_MARGIN_Y 3`
  - Quitada: `WEAPON_RACK_KICK` (la reemplazó la animación de la corredera).

## Siguiente paso sugerido

- Hacer **commit** de todo lo de esta parte (hay muchos archivos modificados y assets nuevos sin versionar).
- Opciones para la Parte 4: Fase C/D del plan (físicas de holdables, balas que empujan cadáveres, efecto de muerte),
  o retomar con el equipo el Paso 4 de la Parte 2 (velocidad/alcance de balas) ahora que ya hay sprites y efectos.
- Considerar escribir **ADR-005** sobre la arquitectura de efectos (partículas + casquillos como structs en un
  controlador por room) si se va a extender con más efectos.
