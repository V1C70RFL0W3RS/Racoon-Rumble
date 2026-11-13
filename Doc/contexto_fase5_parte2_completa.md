# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

> Para retomar: este doc + `contexto_fase5_parte1_completa.md` + `plan_fase5_ragdoll_lobby_tv.md`, los ADR
> (sobre todo **ADR-004 Equipamiento**), `guia_documentacion_tecnica.md` y el Manual de Optimización.

## Estado: Fase 5 (Ragdoll y equipamiento), Parte 2 — COMPLETA (confirmada por el usuario)

## Qué se hizo

### Gorros físicos y 3 ranuras de equipamiento (ADR-004)
- `enum EQUIP_SLOT { HEAD, BODY, FEET, COUNT }`; `EQUIP_NONE = -1`. Bandera `equip_slot` en `obj_holdable`.
- **Puesto = ficha de datos** en `player.equipped[slot]` (`{ obj, sprite, frame, slot }`); suelto = holdable.
  `equip_spawn` es el ÚNICO lugar donde una ficha vuelve a ser instancia.
- **Controles:** **C** agarra el gorro a la mano (se puede lanzar); **V** (disparar) con algo equipable en la
  mano se lo pone (`player_equip_held`). Si la ranura tenía algo, eso pasa a la mano.
- Cada ronda empieza con el gorro del lobby (`player_equip_init` → `player_equip_lobby_hat`). Cambiarlo en la
  PC del lobby lo cambia al instante.
- Se cae: **solo el gorro** al tirarse en ragdoll; **todo** al morir (salvo si cayó fuera del mapa).
- `obj_hat` (hijo de `obj_holdable`): `equip_slot = HEAD`, `grip_y = HAT_GRIP_Y`, `air_friction_mult`.
  `spr_hats` con máscara manual (1,6)–(14,15).
- **Tabla de la cabeza por pose** (`player_head_table_init` / `player_get_head_pose` en `scr_player_visuals`):
  `[dx, dy, ángulo]` respecto de los pies. En el slide el mapache va acostado: el gorro baja y gira 90°.
  Valores finales (afinados a ojo con el usuario): run `-21/-23/-22/-21/-23/-22`, jump `-21/-22/-23`,
  crouch `[0,-17]`, slide `[-10,-7,90]`.

### Spawner de objetos (antes de armas)
- `obj_weapon_spawner` → **`obj_item_spawner`**, variable `weapon_choice` → **`item_choice`** (rooms actualizadas).
- **`scr_spawn_items`**: catálogo `global.spawn_items` (`{ name, group, make }`), cada entrada sabe crearse.
  Opciones aleatorias en `global.spawn_choices` (`"Aleatoria"`, `"Aleatoria fija"`, `"Gorro aleatorio"`,
  `"Gorro aleatorio fijo"`). Se borraron `weapon_id_from_choice` y `weapon_pick_random_id`.
- Macros `ITEM_SPAWNER_RESPAWN_FRAMES`, `ITEM_SPAWNER_CHECK_RADIUS`, `enum SPAWN_GROUP { WEAPON, HAT }`.
- Un spawner de cada `rm_map_sandbox*` quedó en "Gorro aleatorio" para probar.

### Otros
- `player_index` se pasa en el struct de `instance_create_layer` (existe en el Create).
- `scr_hats`: se quitaron `hat_draw`, `player_hat_x/y`; nuevo `hat_spec`.

## Iteraciones con el usuario
1. Agarrar lo ponía al instante → agarrar a la mano + V para ponérselo.
2. No había forma de conseguir gorros en los mapas → spawner genérico.
3. Gorro flotando en el slide → tabla de cabeza con ángulo; ajustes de 1 px.

## Siguiente paso: Parte 5.3 — Casco y chaleco antibalas (bloquean 1 bala y se rompen)
