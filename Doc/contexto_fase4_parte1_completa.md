# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `plan_fase4_armas_fisicas_y_efectos.md`,
`contexto_fase3_parte5_completa.md`, `ADR-001-flujo-de-partida.md`, `ADR-002-camara-y-resolucion.md`,
`ADR-003-objetos-agarrables.md`, `guia_documentacion_tecnica.md`,
`Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y `duck_game_biblia.md` si Claude los
pide o para tenerlos de referencia.

## Estado: Fase 4 (Armas, físicas y efectos), Parte 1 — Fase 0 del plan (Limpieza) — COMPLETA

Se hizo la limpieza que el plan marcaba como bloqueante: nombres que ya no decían la verdad
(`WEAPON_*`, `held_weapon`), código de depuración sin interruptor, y un parámetro sin uso. No se
agregó ninguna mecánica nueva; el juego debe comportarse igual que al cerrar la Fase 3 Parte 5.
Estilo de trabajo: un nombre a la vez, buscando el nombre viejo con "Find in Project" hasta obtener
0 resultados, y probando entre cambios.

## Estructura nueva agregada sobre la Fase 3 Parte 5

Sin objetos, sprites ni rooms nuevos. Solo cambios de nombre y de organización:

```
Scripts
├── Core    → scr_config (reordenado: nueva sección "OBJETOS AGARRABLES"; la sección "CADÁVER" queda solo con CORPSE_*)
├── Player  → scr_player_weapon: player_update_weapon / grab_weapon / release_weapon → player_update_item / grab_item / release_item
└── Player  → scr_player_state_machine: player_update_state(player) ya no recibe `input`
```

## Clases implementadas / modificadas y su responsabilidad

- **`scr_config`** — Mismas constantes; cambió su organización y varios nombres (ver tabla abajo).
  Regla de la cabecera: cada macro va en la sección de su sistema, no al final del archivo.
- **`obj_player`** — La variable `held_weapon` pasó a `held_item` (puede llevar un arma o una pieza de
  cadáver). Las llamadas a los afinadores quedaron protegidas con `if (DEBUG_TOOLS)`.
- **`obj_holdable` (Step)** — Usa `HOLDABLE_GRAVITY` en vez de `GRAVITY`.
- **`player_update_state`** — Firma reducida a `(player)`; el parámetro `input` no se usaba desde la Parte 4.

| Antes | Ahora |
|---|---|
| `WEAPON_WALL_BOUNCE`, `WEAPON_GROUND_FRICTION`, `WEAPON_AIR_FRICTION`, `WEAPON_SETTLE_RATE`, `WEAPON_GRAB_RADIUS` | `HOLDABLE_*` (mismo sufijo) |
| `WEAPON_MAX_PUSHOUT` (96) | `HOLDABLE_OVERLAP_PUSHOUT` (lo usa `holdable_resolve_overlap`) |
| `WEAPON_THROW_*`, `WEAPON_DROP_*` | `HOLDABLE_THROW_*`, `HOLDABLE_DROP_*` |
| `GRAVITY` | `HOLDABLE_GRAVITY` |
| `held_weapon` | `held_item` |
| `HOLDABLE_MAX_PUSHOUT` (32) | Sin cambios; lo usa `holdable_depenetrate` |
| `WEAPON_KICK_LIFT`, `WEAPON_SPAWNER_*`, `WEAPON_CHOICE_*` | Sin cambios: solo aplican a armas |
| `CORPSE_LINK_MIN` / `CORPSE_LINK_MAX` | Eliminadas (quedaron sin uso desde la Parte 5) |

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** `Variable obj_weapon.GRAVITY ... not set before reading it` en el Step de `obj_holdable`
   (línea `vsp += GRAVITY;`).
   **Causa real:** al renombrar la macro, un uso quedó con el nombre viejo. GML no avisa al compilar:
   interpreta un nombre desconocido como variable de instancia sin asignar y falla al ejecutar
   (misma familia que Fase 1 #3, Fase 2 #1 y Fase 3 Parte 2 #2).
   **Fix:** reemplazar por `HOLDABLE_GRAVITY`.
   **Lección:** tras renombrar, buscar el nombre viejo con "coincidir palabra completa" (`GRAVITY`
   también está dentro de `PLAYER_GRAVITY`) y exigir 0 resultados antes de ejecutar.

## Decisiones de diseño explícitas tomadas en esta parte

- **Criterio de renombrado:** una macro pasa a `HOLDABLE_*` si la usa cualquier objeto agarrable; se
  queda como `WEAPON_*` si solo aplica a quien dispara (retroceso, spawners).
- **Dos macros distintas para "sacar de la pared":** `HOLDABLE_MAX_PUSHOUT` (32, desincrustar) y
  `HOLDABLE_OVERLAP_PUSHOUT` (96, buscar lugar libre al nacer solapado). No se fusionan: resuelven
  problemas distintos.
- **`DEBUG_TOOLS` protege las LLAMADAS, no las funciones ni las variables.** Las variables
  `shoulder_tune`, `tune_*` siguen existiendo siempre (así el `if (shoulder_tune)` de
  `player_get_arm_angle` no puede dar "not set before reading it"). Descartado: envolver el Create en
  `if (DEBUG_TOOLS)`, porque con `false` esas variables no existirían.
- **Assets sin usar se quedan hasta la fase final** (`spr_bg_*`, tilesets, variantes `_dec`, etc.); se
  borrarán cuando terminen de crearse los niveles. `obj_room_controller` y `spr_player_run_gun`/`_2`
  ya estaban eliminados.
- **`CAMERA_TOP_MARGIN` puesto en 0 a modo de prueba:** fuera de la room no hay mapa ni fondo. Si un
  jugador que salta muy alto cerca del techo queda pegado al borde de la pantalla, subir a 16–32.

## Pendiente identificado, no bloqueante

Nuevo en esta parte (mejoras de calidad, para después):
- **Soltar el arma agachado o deslizando:** debe caer de la mano, no salir lanzada ni teletransportarse.
  (Ya estaba como pendiente de la Parte 4: en Duck Game cae con velocidad 0, biblia 4.4.4.)
- **Sprite al terminar un slide:** si el jugador desliza y queda quieto, o salta estando quieto, debe
  pasar al sprite de agacharse; si salta deslizando y sigue en movimiento, mantiene el sprite de
  deslizamiento. **Ojo:** contradice a medias la decisión de la Parte 4 (bug #3: el slide dura hasta
  soltar "abajo"). Se propone resolverlo solo en lo visual: la bandera `sliding` no cambia, solo el
  sprite según `abs(hsp)`, con dos umbrales distintos para entrar y salir para evitar parpadeo. Cuidado
  con la máscara: slide y crouch tienen alturas distintas, comprobar que cabe al cambiar.
- `WEAPON_CHOICE_RANDOM` vive en `scr_weapon_data` y `WEAPON_CHOICE_RANDOM_LOCKED` en `scr_config`:
  juntarlas cuando se toque `scr_weapon_data` (Fase B).
- Por confirmar: macro `Release:DEBUG_TOOLS false` y la configuración `Release` (el editor de
  configuraciones está en el menú Extras del Asset Browser y en el Target Manager, no en Tools).

Heredados de fases anteriores (siguen sin resolver):
- (Heredado de Fase 1) Sprite propio para `FALL`; diseño de la capa de red (LAN primero, online después).
- (Heredado de Fase 2) Balas que atraviesan jugadores a alta velocidad; bala naciendo dentro de una
  pared; `holdable_resolve_overlap` en pasillos muy estrechos; sin clic vacío, recarga ni indicador de
  munición; sin efecto de muerte; retoques del kick.
- (Heredado de Fase 3 Parte 1) Dispositivo `"keyboard2"`; `rm_intermission` sin uso.
- (Heredado de Fase 3 Parte 2) Ajustes de partida desde el lobby; controles táctiles; pulido visual de
  menú/lobby/intermission; spawners en `rm_map_sandbox_2`; mapa más grande para probar la cámara.
- (Heredado de Fase 3 Parte 3) Elegir color desde el lobby; borrar assets sin usar (ahora diferido a la fase final).
- (Heredado de Fase 3 Parte 4) Peso del arma (P7); vsync desactivada (activar antes de publicar); ventana
  inicial a 4x; verificar contra el código real la fricción en el aire del pato y el final del slide.
- (Heredado de Fase 3 Parte 5) `corpse_spawn` hace varias cosas; un solo ángulo para las dos mitades del
  cadáver; las piezas no reciben la dirección del disparo; constantes del cadáver sin verificar.

Resueltos en esta parte: renombrado `WEAPON_*` → `HOLDABLE_*`, `held_weapon` → `held_item`, macro
`DEBUG_TOOLS` aplicada, parámetro `input` sin uso, `.gitattributes`, verificaciones de la Parte 5.

## Verificaciones hechas al cierre de la fase (confirmadas por el usuario)

- Tirar un arma quieto: arco corto y caída; lanzarla corriendo: sale con fuerza, gira y rebota en la pared.
- Lanzarla hacia arriba: cae de pie o acostada; no flota ni cae demasiado rápido.
- Agarrar el arma de un spawner y caminar con ella: reaparece otra tras ~5 s.
- Agarrar el arma, caminar lejos y soltarla: el punto del spawner cuenta como libre y genera otra.
- Dejar el arma en su punto: no aparecen duplicados.
- Agarrar un arma y una pieza de cadáver, soltarlas y lanzarlas.
- Morir con un arma en la mano; morir pegado a una pared, a la izquierda y a la derecha.
- Con `DEBUG_TOOLS` en `false` el juego corre sin errores ni puntos de depuración.

## Configuración relevante en el editor

- **`scr_config`:** `#macro DEBUG_TOOLS true` (valor por defecto). Opcional: `#macro Release:DEBUG_TOOLS false`
  con una configuración llamada exactamente `Release` (Extras del Asset Browser → Configuration Editor).
- **`CAMERA_TOP_MARGIN`:** 0 (prueba).
- Sin cambios en Input Map, grupos, Room Order ni sprites.

## Siguiente paso: Fase 4, Parte 2 — Fase A del plan (Balas robustas)

- Bala por `collision_line` desde su posición anterior a la nueva (cierra el pendiente de la Fase 2).
- Que la bala no nazca dentro del tilemap al disparar pegado a una pared.
- `AmmoDef` separado de `WeaponDef`; decidir penetración y rebote; confirmar velocidad de bala
  (la biblia dice 28 px/frame; hoy la más rápida va a 16).
- Candidato a ADR-004 (afecta armas, jugadores, mapas y red; cara de revertir).
