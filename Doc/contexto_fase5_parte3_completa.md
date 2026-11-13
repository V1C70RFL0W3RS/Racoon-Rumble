# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

> Para retomar: este doc + `contexto_fase5_parte1/2_completa.md` + `plan_fase5_ragdoll_lobby_tv.md`, los ADR
> (sobre todo **ADR-004 Equipamiento**), `guia_documentacion_tecnica.md` y el Manual de Optimización.

## Estado: Fase 5 (Ragdoll y equipamiento) — COMPLETA. Parte 3 confirmada por el usuario.

## Qué se hizo en la Parte 3

### Equipo
| Objeto | Ranura | Qué hace | Sprite |
|---|---|---|---|
| `obj_helmet` | cabeza | detiene **1 bala** (se rompe); cajas y pisotones **lo abollan** (frame 1) y lo sigue aguantando | `spr_helmet` (2 frames, origen 8,15) |
| `obj_vest` | cuerpo | detiene **1 bala** al cuerpo (de pie o en ragdoll) y se rompe | `spr_vest` de perfil, origen 8,8 |
| `obj_boots` | pies | pisar una cabeza cayendo la mata y rebota; camina sobre pinchos | suelto `spr_boots`; puestas `spr_boots_worn` (11 frames) y `spr_boots_worn_corpse` |
| `obj_spikes` | — (nivel) | tocarlos sin botas mata; el ragdoll tirado encima siempre se pincha; una caja que cae rápido se daña/rompe | `spr_spikes`, origen 0,0 (grilla de 16) |

### Reglas
- **Zonas** (`HIT_ZONE { HEAD, BODY, TOP }`): bala a ≤ `PLAYER_HEAD_ZONE_RADIUS` (5) del centro de la cabeza → HEAD (solo
  casco); resto → BODY (solo chaleco); caja o pisotón → TOP (solo casco, se abolla). Ragdoll: siempre BODY.
- `player_take_hit(..., _zone)` llama a `player_equip_try_block` antes de quitar vida.
- **Ficha de equipo con campos en UNA tabla** (`equip_fields()`): `bullet_block`, `break_cols`, `dent_frame`, `stomps`,
  `spike_proof`, `worn_sprite`, `worn_sprite_ragdoll`.
- **Tabla de poses por ranura** (`player_equip_table_init`, `player_get_equip_pose`): `[dx, dy, ángulo]` desde los pies.
- **Botas por frame**: `feet_frame_base(sprite)` → run 0, jump 6, crouch 9, slide 10; mismo origen que el cuerpo.
  Generadas por script desde la silueta de los pies (si cambian los sprites del mapache, hay que regenerarlas).
- **Pinchos y cajas**: `holdable_try_spikes(_fall)`: daño = 1 + ⌊(vel − 3) / 1,25⌋; soltada desde la mano no se daña.
- Ragdoll: el chaleco y las botas se dibujan sobre las piezas (`corpse_draw_worn`, enganchado en `holdable_draw`).

### Spawner
Opciones nuevas: "Equipo aleatorio", "Equipo aleatorio fijo", "Casco", "Chaleco", "Botas" (`SPAWN_GROUP.EQUIPMENT`).

### Efectos
`fx_shards` (pedazos de dos colores, generaliza `fx_splinters`), `fx_armor_break`.

## Iteraciones con el usuario
1. El casco protegía el torso → casco solo cabeza, peto el resto.
2. Chaleco "de frente" tapado por el brazo y 1 px corrido → redibujado de perfil sobre la silueta del torso.
3. Gorro 1 px a la derecha de pie/agachado.
4. Botas como color plano → sprite propio por frame.
5. El casco se rompía con cajas/pisotones → se abolla.
6. Cajas sobre pinchos según velocidad.

## Pendiente
- Sonidos placeholder: `snd_armor_break`, `snd_helmet_dent` (hoy suena bala contra pared).
- Colocar pinchos en los mapas (los niveles se diseñan al final).

## Siguiente paso: Fase 6 — La Casa de los Fans (lobby). Parte 6.1: interactables multiusuario + ropero.
