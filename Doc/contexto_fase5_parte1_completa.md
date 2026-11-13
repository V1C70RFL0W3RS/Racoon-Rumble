# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

> Para retomar en un chat nuevo: este doc + `plan_fase5_ragdoll_lobby_tv.md` + `contexto_fase4_partes6_7_8_9.md`
> y anteriores, los ADR, `guia_documentacion_tecnica.md` y `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md`.

## Estado: Fase 5 (Ragdoll y equipamiento), Parte 1 — COMPLETA (confirmada por el usuario)

## Forma de trabajo
Se trabaja en una copia de trabajo (git worktree) en `.claude/worktrees/racoon-rumble-ragdoll-lobby-64b529`,
rama `claude/racoon-rumble-ragdoll-lobby-64b529`. El usuario abre ESE proyecto en el IDE y usa **Recargar**
(nunca Guardar). Si el IDE tiene un archivo abierto, Windows puede bloquear la escritura un momento.

---

## Qué se hizo

### Modo ragdoll ("hacerse el muerto")
- Tecla **X** (teclado), **Numpad 3** (`keyboard2` TEMPORAL), **Y/Triángulo** (mando). Campo `ragdoll_pressed` en el input.
- El cuerpo **es un cadáver con dueño vivo**: `corpse_spawn(..., _tumble, _body_of)` con `_body_of = jugador`.
  La parte superior usa el frame vivo (0). Nada de física nueva.
- El jugador queda invisible (`visible = false`) y **sigue a sus piezas** (`player_ragdoll_follow`): la cámara y
  el conteo de la ronda lo siguen viendo vivo sin cambios.
- Al tirarse: suelta lo que tiene en la mano; el cuerpo hereda **toda** la velocidad (`RAGDOLL_INERTIA 1`) y un
  volteo (`RAGDOLL_TUMBLE`), así sigue el arco del salto y gira.
- **Arrastrarse a saltitos**: mismo empujón horizontal para las dos piezas (si no, gira y "cabecea"); la pieza que va
  adelante salta un poco más (`RAGDOLL_CRAWL_HOP_LEAD/TRAIL`). Solo con alguna pieza apoyada.
- **Levantarse**: saltar, solo si alguna pieza está apoyada (`corpse_piece_on_ground`: mapa o plataforma; NO
  `vsp == 0`, que también vale al chocar con un techo), nadie lo sostiene y pasó el enfriamiento (0,4 s).
- **Atrapado**: si alguien sostiene una pieza, saltar NO libera; izquierda/derecha sacude la pieza que cuelga
  (`RAGDOLL_STRUGGLE_*`) sin mover a quien lo sostiene (la pieza sostenida es punto fijo del solucionador).
- **Morir en ragdoll**: bala, caja encima o caer del mapa. `body_of` en `obj_holdable` redirige el golpe al dueño
  (`obj_projectile`, `holdable_try_crush`). `player_die` no crea otro cadáver: `player_ragdoll_die` →
  `corpse_pair_kill` (frame muerto, `body_of = noone`, pelo).

### Cuerpo articulado (cadáveres y ragdolls) — revierte un trade-off del ADR-003
- Antes: una varilla rígida y **un solo ángulo** para las dos mitades → se veía como una tabla.
- Ahora: **tres puntos** (superior, **cintura invisible**, inferior). La cintura vive en `rig` de la pieza superior
  (`corpse_rig_create`, reutilizado cada frame: sin asignaciones). `corpse_pair_update` (Begin Step de la superior):
  - dos varillas cintura↔pieza (`corpse_rod_solve`, impulso de Duck Game, `CORPSE_SOLVER_PASSES` pasadas);
  - **columna** elástica superior↔inferior hacia la distancia de reposo (`CORPSE_SPINE_STIFFNESS`): se dobla al
    moverse y se endereza quieto;
  - **tope** de plegado (`CORPSE_FOLD_MIN`, ≈ 60°);
  - la cintura choca con el mapa como círculo de `CORPSE_JOINT_RADIUS` (si no, el cuerpo tirado se hundía en V);
  - cada pieza saca **su** ángulo de la dirección cintura → pieza.
- Draw de la pieza: el recorte de seguridad ahora es hacia la cintura (`corpse_rod_length`).

## Funciones nuevas / modificadas
| Dónde | Qué |
|---|---|
| `scr_player_ragdoll` (nuevo) | `player_ragdoll_can_enter/enter/update/follow/on_ground/exit/die`, `corpse_piece_on_ground` |
| `scr_corpse` | `corpse_spawn` (devuelve `{upper, lower}`, recibe la velocidad final, `_tumble`, `_body_of`), `corpse_rig_create`, `corpse_pair_kill`, `corpse_pair_update` (3 puntos), `corpse_rod_solve`, `corpse_rod_length` (reemplaza `corpse_rest_length`) |
| `scr_player_weapon` | `player_drop_item(_hsp,_vsp,_spin)`: ÚNICO lugar donde se suelta lo de la mano (lanzar, morir, ragdoll) |
| `scr_player_health` | `player_die` calcula la velocidad del cadáver y delega en ragdoll; `player_is_upright()` (vivo y no en ragdoll) |
| `scr_holdable` | `instance_depenetrate(_inst,_max)` genérico (lo usa el jugador al levantarse); aplastar cuerpos en ragdoll |
| `obj_holdable` Create | `body_of = noone` |
| `obj_projectile` Step | víctima = jugador o `body_of` de la pieza |
| `scr_player_state_machine` / `scr_config` | estado `PLAYER_STATE.RAGDOLL` |

## Macros nuevas (scr_config)
CADÁVER: `CORPSE_HIT_TUMBLE 0.25`, `CORPSE_JOINT_INV_MASS 2`, `CORPSE_JOINT_DAMPING 0.98`, `CORPSE_JOINT_RADIUS 6`,
`CORPSE_FOLD_MIN 0.8`, `CORPSE_SPINE_STIFFNESS 0.12`, `CORPSE_SOLVER_PASSES 3`.
RAGDOLL: `RAGDOLL_COOLDOWN_FRAMES 24`, `RAGDOLL_INERTIA 1`, `RAGDOLL_TUMBLE 0.35`, `RAGDOLL_CRAWL_INTERVAL 16`,
`RAGDOLL_CRAWL_IMPULSE 0.9`, `RAGDOLL_CRAWL_HOP_LEAD -1.25`, `RAGDOLL_CRAWL_HOP_TRAIL -1.1`,
`RAGDOLL_STRUGGLE_INTERVAL 8`, `RAGDOLL_STRUGGLE_IMPULSE 1.8`, `RAGDOLL_GETUP_HOP -2.5`.

## Decisiones de diseño
- El ragdoll cuenta como **vivo** para la ronda (si no, el engaño no serviría).
- Un disparo al ragdoll lo mata (en la Parte 5.3, el equipo antibalas detendrá 1 bala).
- Se arrastra por saltitos, no a velocidad constante.
- Las piezas chocan con su máscara derecha (el ángulo es solo visual); por eso la columna lo endereza en reposo.

## Iteraciones con el usuario (lo que no funcionó)
1. Varilla rígida + un ángulo → "muy estático". → cintura articulada.
2. Caía recto al tirarse en un salto (inercia 0,5) → inercia 1 + volteo.
3. Cuerpo hundido en V → radio de la cintura.
4. Levantarse en el aire → solo apoyado.
5. "Cabezazos" al arrastrarse (más empuje arriba que abajo) → empuje igual, salta más la pieza de adelante.
6. Cuerpo hecho bola y "flotando" → columna elástica + tope de plegado 0,8.

## Pendiente
- Parpadeo de ojos en ragdoll (opcional). Sonido `snd_ragdoll_flop` (placeholder).
- Botón táctil (cuando se diseñen los controles de celular).

## Siguiente paso: Parte 5.2 — Gorros físicos y 3 ranuras de equipamiento
