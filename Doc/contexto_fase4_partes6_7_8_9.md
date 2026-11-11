# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

> **Resumen fusionado: Fase 4, Partes 6–9**
> Para retomar en un chat nuevo, pegar este doc + los anteriores a la Fase 4 (`contexto_fase4_parte5_completa.md` y anteriores), los ADR, `guia_documentacion_tecnica.md` y `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md`.

---

## Forma de trabajo (sin cambios)
Claude edita archivos directamente vía `device_bash` en `~/mnt/Racoon-Rumble` (Windows: `C:\Users\bryan\GameMakerProjects\Racoon-Rumble`). El usuario elige **Recargar** (nunca Guardar) en el IDE y prueba. Assets nuevos (sprites, sonidos): el usuario los crea vacíos en el IDE; Claude llena las propiedades. Scripts nuevos: Claude edita el `.yyp` para registrarlos.

---

## Parte 6 — Brazo arriba con pared al frente ✅

Con algo en la mano, si lo sostenido toca una pared al frente (de pie, caminando, agachado o deslizando), el brazo sube **del todo** (90°). Al alejarse vuelve a bajar. Disparar pegado al muro manda la bala hacia arriba.

**`scr_player_visuals`:**
- `player_update_arm_raise()`: objetivo 1 si hay algo en la mano, no se apunta arriba, y (`hovering` o `player_arm_touches_wall()`); si no, 0. `arm_raise` se acerca al objetivo con `PLAYER_ARM_RAISE_SPEED`.
- `player_arm_touches_wall()`: una `collision_line` desde el hombro con el ángulo SIN levantar, largo `PLAYER_ARM_LENGTH + muzzle_x + PLAYER_ARM_WALL_MARGIN`.

**Decisiones:** sube del todo (no "lo necesario"); se prueba con el ángulo sin levantar (anti-parpadeo); apuntando arriba no se prueba.

**Macros relevantes:** `PLAYER_ARM_WALL_MARGIN 4`, `PLAYER_ARM_RAISE_SPEED 0.2`.

---

## Parte 7 — Cajas ✅

Caja de madera (`obj_crate`, hijo de `obj_holdable`): se agarra y lanza; plataforma de un solo sentido; se apila; se rompe a balazos (3 frames de daño); escudo en la mano; al romperse suelta astillas y humo; al caer sobre la cabeza mata y da un saltito. Lanzamiento en diagonal (arriba + correr) para todo holdable.

### Banderas nuevas en `obj_holdable` (Create)
| Bandera | Defecto | Uso |
|---|---|---|
| `shield_when_held` | false | balas lo golpean aunque esté en mano |
| `max_hp` / `hp` | -1 | vida; -1 = indestructible |
| `platform` | false | se puede aterrizar encima suelto |
| `crush_speed` | 0 | >0: mata al caerle a esa vel. o más |

### `obj_crate` (Create)
`rotates=false`, `wall_bounce=CRATE_WALL_BOUNCE`, `air_friction_mult=CRATE_AIR_FRICTION_MULT`, `grip_x/y=CRATE_GRIP_X/Y`, `shootable=true`, `block_chance=1`, `impact_mult=CRATE_IMPACT_MULT`, `shield_when_held=true`, `hit_fx=HIT_FX.WOOD`, `max_hp=hp=CRATE_HP`, `platform=true`, `crush_speed=CRATE_CRUSH_SPEED`.

### Balas y daño
- `AmmoDef.object_damage` (defecto 1; HEAVY 3): vida que quita a objetos (separado de `damage`).
- `holdable_take_shot(_h,_dir,_power,_damage=0)`: suelto → empuja; `fx_holdable_hit`; si `hp>=0` → `holdable_damage`.
- `holdable_damage`: resta vida; frame = `floor((1-hp/max_hp)×frames)`; a 0 → `holdable_break`.
- `holdable_break` → `fx_holdable_break` + `holdable_destroy` (limpia `holder.held_item` antes de destruir).

### Plataformas
- `mask_bottom_offset()`: borde inferior real del sprite (no `bbox_bottom`; respeta `image_yscale`).
- `platform_find_below(_l,_r,_b0,_b1,_self)`: plataforma cuya tapa cruzó el borde inferior este frame.
- Jugador: `player_land_on_platform`, `standing_on`, `platform_drop_timer`. Abajo + saltar con `standing_on` → baja (`PLAYER_PLATFORM_DROP_FRAMES` frames ignorando plataformas).
- `obj_holdable` Step: si no tocó el mapa y bajaba, prueba plataformas.

### Aplastar
- `holdable_try_crush(_fall,_b0)`: si `crush_speed>0` y cayó a esa velocidad, mata jugadores con `bbox_top` bajo su borde inferior. El cadáver sale abajo; la caja rebota `HOLDABLE_CRUSH_BOUNCE`.

### Efectos
- `HIT_FX.WOOD`; `fx_splinters`; `fx_holdable_break` (astillas en todas direcciones + humo).

### Lanzar
- `player_release_item`: arriba + en movimiento → 45° a `HOLDABLE_THROW_DIAG_SPEED`; arriba quieto → recto arriba.

### Assets
- `spr_crate`: 3 frames 16×16 (0 entera, 1 rajada, 2 casi rota), origen Middle Centre (8,8). Fuente: `Doc/spr_crate_strip3.png`.
- `obj_crate`: parent `obj_holdable`, sprite `spr_crate`, carpeta Objects/Items.

### Macros (sección CAJA y EFECTOS en `scr_config`)
`CRATE_HP 4`, `CRATE_IMPACT_MULT 0.5`, `CRATE_WALL_BOUNCE 0.3`, `CRATE_AIR_FRICTION_MULT 0.35`, `CRATE_GRIP_X -6`, `CRATE_GRIP_Y 0`, `CRATE_CRUSH_SPEED 3`, `FX_SPLINTER_BREAK_COUNT 14`, `HOLDABLE_THROW_DIAG_SPEED 7`, `HOLDABLE_CRUSH_BOUNCE 2.5`, `PLAYER_PLATFORM_DROP_FRAMES 4`.

---

## Parte 8 — Sonidos ⏸️ (en pausa, pendiente de aprobación del usuario)

Sistema de audio **completo y conectado**; lo que falta es que el usuario apruebe el carácter de los sonidos.

### Assets (11 en Sounds/Weapons y Sounds/World)
`snd_pistol_fire`, `snd_smg_fire`, `snd_magnum_fire`, `snd_shotgun_fire`, `snd_weapon_empty`, `snd_shotgun_rack`, `snd_bullet_wall`, `snd_wood_hit`, `snd_wood_break`, `snd_player_death`, `snd_pickup`. Originales en `Doc/sfx`. Tres versiones: v1 retro 8 bits (rechazada), v2 realista saturada (rechazada), v3 investigación de mezcla (pendiente).

### `scr_audio`
- `audio_init()`: llamado en Create del manager, tras `settings_init`.
- `audio_play_sfx(_snd, _pitch_var, _priority)`: acepta array de variantes; anti-repetición `SFX_MIN_GAP_MS`; máx. `SFX_MAX_VOICES` copias (corta la más vieja); variación de volumen `SFX_GAIN_VAR`; volumen `global.settings.sfx_volume`.

### Conexiones
`WeaponDef.snd_fire` → `weapon_try_fire`; `snd_empty` → `weapon_dry_fire`; `snd_rack` → `weapon_rack`; bala en pared → `obj_projectile`; madera → `fx_holdable_hit/break`; muerte → `player_die` (`SFX_PRIORITY_HIGH`); agarrar → `player_grab_item`.

### Macros (sección AUDIO)
`SFX_MIN_GAP_MS 30`, `SFX_MAX_VOICES 4`, `SFX_GAIN_VAR 0.12`, `SFX_PRIORITY_NORMAL 1`, `SFX_PRIORITY_HIGH 10`.

### Pendiente para retomar
- Aprobación del carácter de los sonidos. Alternativa: CC0 de kenney.nl / opengameart.org (descarga el usuario).
- 2–3 variantes de los más frecuentes (SMG, bala en pared, madera).
- Sonidos que faltan: salto/aterrizaje, lanzar, cuenta regresiva, UI, música.
- Menú de opciones con `sfx_volume`.

---

## Parte 9 — Sistema de PCs del Lobby ✅ (error resuelto)

PCs interactables en el lobby: el host configura la partida, cada jugador cambia su color y gorro. El host también controla el **máximo de jugadores** (1–8, arranca en 4; según el valor se mostrarán 4, 6 u 8 cabinas — pendiente de implementar el layout).

### Fix aplicado en esta parte
**Error:** `Variable obj_lobby_pc.user(100207, -2147483648) not set before reading it`
**Causa:** `obj_lobby_pc/Create_0.gml` estaba vacío — sin `event_inherited()`, el Create del padre nunca corría.
**Solución (dos capas):**
1. `obj_lobby_pc/Create_0.gml` ahora empieza con `event_inherited()`.
2. `interact_find` tiene un guard `variable_instance_exists(id,"user")` antes de leer la variable.

### `obj_interactable` (padre)
Create_0: `user=noone`, `use_slot=INTERACT_ANYONE`, `menu=[]`, `menu_title=""`, `menu_index=0`, `nav_dir=0`, `nav_timer=0`, `image_speed=0`.

### `scr_interact`
`interact_can_use`, `interact_in_range`, `interact_find` (con guard), `interact_someone_near`, `interact_begin` (asigna `user`, `menu_index=0`, `image_index=1`, `hsp=0`), `interact_end`, `interact_handle_input` (grab/jump = salir; si no, `menu_options_navigate`).

### `obj_lobby_pc`
Parent: `obj_interactable`. Sprite: `spr_lobby_pc` (2 frames 24×24, origen 12,23; 0=apagada, 1=encendida).
Variable de instancia `pc_slot` (rango INTERACT_HOST(−1)..7).
- `pc_slot == -1` (host): menú "Ajustes de partida" — Puntos para ganar, Rondas por bloque, **Máx. jugadores**.
- `pc_slot 0..7`: menú "Jugador N" — Color, Gorro.
Draw GUI: `menu_options_draw` si `user!=noone`; aviso "Agarrar: usar" si `interact_someone_near`.

### `scr_menu_options`
`menu_option(_label,_ctx,_get,_step)`, `menu_options_navigate` (repetición MENU_REPEAT_DELAY/RATE, vertical gana), `menu_options_draw` (fnt_body, MENU_COLOR, MENU_BG_ALPHA; footer "Agarrar: salir").

### `scr_hats`
`hats_init()`: 5 gorros en `global.hats` (Sin gorro, Gorra, Sombrero, Corona, Gorro de lana). `hat_draw(_index,_x,_y,_xscale)`: frame = índice (0 = nada). Dibujado en Draw de `obj_player` tras el cuerpo.

### `scr_lobby` — añadido `max_players`
- `lobby_reset()` inicializa `lobby_settings.max_players = LOBBY_MAX_PLAYERS_DEFAULT (4)`.
- `lobby_add_player` y `lobby_scan_join` usan `lobby_get_max_players()` en vez del macro fijo.
- `lobby_setting_range("max_players")` → `[1, 8]`.
- `lobby_set_setting` ya maneja `max_players` sin código extra.

### Macros nuevas / modificadas en `scr_config`
```
MAX_PLAYERS                  8      // (antes 4)
LOBBY_MAX_PLAYERS_MIN        1
LOBBY_MAX_PLAYERS_MAX        8
LOBBY_MAX_PLAYERS_DEFAULT    4
LOBBY_HOST_INDEX             0
LOBBY_SCORE_MIN/MAX          1/20
LOBBY_ROUNDS_MIN/MAX         1/10
INTERACT_RADIUS              24
INTERACT_ANYONE             -2
INTERACT_HOST               -1
MENU_REPEAT_DELAY            18
MENU_REPEAT_RATE             6
MENU_COLOR                   rgb(60,230,90)
MENU_BG_ALPHA                0.85
PLAYER_HAT_DX/DY             1 / -10
CAMERA_FIXED_ROOMS           [rm_lobby]
MATCH_DEFAULT_SCORE_TO_WIN   3
MATCH_DEFAULT_ROUNDS_PER_BLOCK 3
```

### Cámara del lobby
`obj_camera_controller`: `fixed=true` en rooms de `CAMERA_FIXED_ROOMS`; Step empieza con `if (fixed) exit`. Ajuste dinámico de cámara según cabinas visibles: **pendiente** (layout de room aún no diseñado).

### Lo que el usuario debe hacer en el IDE
1. Recargar → verificar parent `obj_lobby_pc → obj_interactable`.
2. Colocar en `rm_lobby`: una PC con `pc_slot=-1` (host) + cuatro con `pc_slot=0..3` (iniciales) + cuatro con `pc_slot=4..7` (para max 5–8, cuando el layout lo permita).
3. Ajustar tamaño de `rm_lobby` al layout final.

---

## Pendientes globales (prioridad de mayor a menor)

| # | Tarea | Notas |
|---|---|---|
| 1 | **Layout de cabinas en `rm_lobby`** (8 cabinas) | Diseño pendiente: 4+2+2 o 2×4 |
| 2 | **Cámara dinámica del lobby** según `max_players` | 4 cabinas / 6 / 8 según 1–4 / 5–6 / 7–8 |
| 3 | **Sonidos** (parte 8 en pausa) | Aprobación del usuario; CC0 como alternativa |
| 4 | **Controles táctiles** | Celular |
| 5 | **Paso 4** velocidad/alcance de balas | |
| 6 | Pulir cajas | Caja sostenida contra pared (brazo entra); aplastar al lanzador (¿ignorar unos frames?) |
| 7 | Renombrar `obj_fx_shells` → `obj_fx_debris` | Opcional |
| 8 | Gorro en cadáver | |
| 9 | `keyboard2` TEMPORAL quitar | |
| 10 | Ajustes persistentes | `sfx_volume` y otros |
| 11 | **Red** (LAN → online) | Todo lo marcado "host decide" ya está preparado |
