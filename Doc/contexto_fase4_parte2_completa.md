# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `plan_fase4_armas_fisicas_y_efectos.md`,
`contexto_fase4_parte1_completa.md`, `contexto_fase3_parte5_completa.md`, `ADR-001-flujo-de-partida.md`,
`ADR-002-camara-y-resolucion.md`, `ADR-003-objetos-agarrables.md`, `ADR-004-balas-por-segmento-y-municion.md`,
`guia_documentacion_tecnica.md`, `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y
`duck_game_biblia.md` si Claude los pide o para tenerlos de referencia.

## Estado: Fase 4 (Armas, físicas y efectos), Parte 2 — Fase A del plan (Balas robustas) — COMPLETA (Paso 4 diferido)

Se cerró el pendiente heredado desde la Fase 2: las balas rápidas atravesaban jugadores. La bala ahora
revisa **todo el segmento** que recorrió en el frame, y no solo su posición final. Además se definió de dónde
sale la bala de cada arma (boca del cañón con dos medidas, `muzzle_x` y `muzzle_y`), se evitó que nazca dentro de una
pared, y se separó la bala del arma (`AmmoDef` y `WeaponDef`). **Queda diferido a propósito el Paso 4**
(elegir velocidad y alcance definitivos): el usuario prefiere decidirlo cuando tenga los demás sprites y pueda
probar en local/LAN con su equipo. Estilo de trabajo: pasos chicos, una prueba confirmada por el usuario después de cada uno.

## Estructura nueva agregada sobre la Fase 4 Parte 1

```
Scripts
└── Weapons → scr_ammo_data                                   (NUEVO)
    (modificados: scr_projectile, scr_weapon_data, scr_weapon_actions)

Objetos modificados
├── obj_projectile → Step (rehecho; Create sin cambios)
├── obj_player     → Draw (una línea de depuración de la boca del cañón, dentro de DEBUG_TOOLS)
└── obj_game_manager → Create (llama ammo_data_init)
```

## Clases implementadas / modificadas y su responsabilidad

- **`scr_ammo_data`** (NUEVO) — Catálogo de munición, solo datos CONSTANTES. `enum AMMO_ID {LIGHT, HEAVY, PELLET,
  COUNT}` (agregar siempre antes de COUNT, nunca reordenar). Constructor `AmmoDef()` con `name, speed, range,
  damage, life`. `ammo_data_init()` arma `global.ammo_defs` una sola vez y **deriva** `life = ceil(range / speed)`
  para cada entrada; `ammo_get_def(_id)` es el único punto de acceso. Mismo patrón que el catálogo de armas.
- **`scr_weapon_data`** — `WeaponDef` perdió `damage`, `bullet_speed` y `bullet_life` (ahora viven en la
  munición) y ganó `ammo_id` (por defecto `AMMO_ID.LIGHT`) y `muzzle_y` (desvío perpendicular de la boca del cañón;
  positivo = hacia abajo en el sprite). Escopeta usa `PELLET`, Magnum `HEAVY`, pistola y SMG `LIGHT`.
- **`scr_weapon_actions`** — `weapon_muzzle_x/y(_def,_x,_y,_angle,_facing)`: ÚNICO lugar que calcula la boca
  del cañón en el mundo (mismo convenio que `weapon_draw_held`: ángulo mundial, espejado con `yscale = facing`).
  `weapon_try_fire` busca la munición una vez por disparo, comprueba con `collision_line` contra el tilemap el
  tramo mano → boca, y solo si está libre crea las balas. `weapon_debug_muzzle` es TEMPORAL (punto rojo).
- **`scr_projectile`** — `projectile_spawn(_x,_y,_angle,_ammo,_owner,[_origin_x],[_origin_y])`: recibe la
  `AmmoDef` entera (de ahí salen velocidad, daño y vida) y un origen opcional (la mano) que se guarda como
  `prev_x/prev_y` para el primer segmento. `projectile_find_hit(_x1,_y1,_x2,_y2,_owner)` devuelve el jugador vivo
  más cercano (distancia al centro) cuyo recorrido cruza el segmento, ignorando al dueño y a los muertos.
- **`obj_projectile` (Step)** — Orden: baja `life`; `move_and_collide` contra el tilemap (si choca, `x,y` queda en
  el punto de contacto); `projectile_find_hit` sobre `prev → actual`; mata al jugador si hay; DESPUÉS destruye
  por pared; al final actualiza `prev_x/prev_y`.

## Bugs encontrados y resueltos durante esta parte

1. **Síntoma:** con `bullet_speed` en 30, algunas balas atravesaban al jugador sin matarlo.
   **Causa real:** `obj_projectile` solo comprobaba solapamiento con `instance_place` en la posición FINAL del
   frame. Si la bala avanza más que el ancho del jugador (~14 px de máscara de pie) más el de la bala (8 px), o sea
   unos 22–24 px por frame, pasa de un lado al otro sin que ningún frame las vea solapadas. Las paredes no tenían
   el problema porque `move_and_collide` recorre todo el trayecto. Hasta ahora no se veía porque la bala más
   rápida iba a 16.
   **Fix:** `projectile_find_hit` con `collision_line(..., precise = true)` sobre el segmento posición anterior →
   actual. Reproducido antes (Paso 0) y confirmado después por el usuario: de cerca, de lejos y pegado a la mano.
   **Cierra:** pendiente heredado "balas que atraviesan jugadores a alta velocidad" (Fase 2).
2. **Síntoma (pendiente heredado de la Fase 2, no reportado como error):** la bala podía nacer dentro de la pared
   al disparar pegado a ella.
   **Causa real:** nace en `mano + muzzle_x`, y ese punto podía quedar dentro del tilemap; `move_and_collide` no
   libera lo que NACE incrustado (misma causa que el bug #5 de la Fase 2).
   **Fix:** si `collision_line` contra el tilemap encuentra pared entre la mano y la boca, el disparo se gasta
   (munición, cadencia, retroceso y kick) pero la bala no se crea. **Cierra:** "bala naciendo dentro de una pared".

## Decisiones de diseño explícitas tomadas en esta parte

- **Detección por segmento (`collision_line`) y no por subdivisión ni barrido píxel a píxel.** La biblia (4.6.7)
  describe un pipeline de 5 fases porque trabaja en C# sin esta función; GameMaker ya hace el barrido. Con 4
  jugadores son 4 llamadas por bala, sin listas ni `ds_*`.
- **Orden dentro del Step:** primero jugadores sobre el segmento, después destruir por pared. Como el segmento
  termina en el punto de contacto con la pared, un jugador detrás de un muro no recibe el disparo (confirmado
  por el usuario).
- **El primer segmento arranca en la MANO, no en la boca.** Así un enemigo pegado al arma también se detecta.
- **La línea no tiene grosor** (la máscara de la bala mide 8×3): un disparo que roza el borde de un jugador puede
  fallar por 1 px. Es el mismo criterio de 1 px del raycast de Duck Game; se acepta.
- **Disparo bloqueado = disparo gastado.** Una escopeta pegada a la pared consume su cartucho sin crear
  perdigones. Se descartó "no disparar" porque deja al jugador sin retroalimentación y complica la cadencia.
- **Dos medidas de boca (`muzzle_x`, `muzzle_y`) por arma**, medidas sobre el sprite como punto de la punta menos
  el Origin (el agarre). El sprite no manda: Magnum y SMG comparten sprite con la pistola pero cada una tiene su par.
- **`AmmoDef` separado de `WeaponDef`.** Varias armas pueden compartir bala; la bala se retoca en un solo lugar.
  El **alcance se define en píxeles** y la vida en frames se deriva (`range / speed`): subir la velocidad ya no
  alarga el alcance sin avisar.
- **Solo `speed`, `range`, `damage` y `life` en `AmmoDef`.** No se agregaron campos para lo que nadie usa todavía.
- **`ownerSafety` de Duck Game no se adopta:** sin rebote la bala nunca vuelve hacia su dueño, así que se ignora al
  dueño siempre. Revisar cuando entre el rebote.
- **Descartados / diferidos:** sub-stepping propio (GameMaker ya lo hace); `collision_line_list` (necesita
  `ds_list`); evaluación en dos pasadas armadura → cuerpo (no hay armaduras); hurtbox de daño más grande que la
  hitbox física (12×26 contra 8×22 en la biblia; hoy hay una sola máscara); **penetración y rebote especular**
  (nada tiene `thickness` todavía). Cuando lleguen, `move_and_collide` se queda corto: hará falta un raycast propio
  con punto de contacto y normal, y ahí conviene un ADR.
- **Velocidad y alcance finales: DIFERIDOS por el usuario** hasta tener los demás sprites y probar en local o LAN con
  su equipo. Para comparar se dejó anotado el juego de valores de la biblia (sin verificar contra el código real):
  LIGHT 28 / 250, HEAVY 36 / 300, PELLET 28 / 115 (velocidad px/frame / alcance px).

## Pendiente identificado, no bloqueante

Nuevo en esta parte:
- **Paso 4: elegir velocidad y alcance definitivos** de LIGHT, HEAVY y PELLET (hoy provisionales: 20/400, 24/500,
  20/150). Ojo: respecto a antes, la pistola baja de 30 a 20 px/frame, la SMG sube de 14 a 20 y el Magnum de 16 a 24.
- **El brazo debe subir al tener una pared al frente estando de pie** (hoy solo lo hace al deslizar o aletear). La
  escopeta, con la boca a 48 px del agarre, queda sin balas si hay pared más cerca (comprobado: no aparece bala dentro
  del muro); es coherente, pero se nota.
- **Estela visual de la bala:** a 28–36 px/frame el sprite de 8 px "salta" y puede verse entrecortado. Efecto de
  la Fase D del plan.
- **Las balas solo detectan `obj_player`:** atraviesan piezas de cadáver y otros holdables (Duck Game transfiere
  el impulso de la bala al cadáver; queda para otra parte).
- **`projectile_find_hit` elige el más cercano por distancia al centro del jugador**, aproximado; con jugadores
  superpuestos puede no ser el primero cruzado.
- `TEMPORAL:` `weapon_debug_muzzle` y su llamada en el Draw de `obj_player` (dentro de `if (DEBUG_TOOLS)`).
- `TEMPORAL:` Magnum y SMG siguen con el sprite prestado de la pistola (medidas de boca copiadas de ella).
- Candidatos para más adelante: `AmmoDef` con penetración, rebote, `deadly` y sprite propio; hurtbox de daño
  distinta de la hitbox física.

Heredados de fases anteriores (siguen sin resolver):
- (Heredado de Fase 1) Sprite propio para `FALL`; diseño de la capa de red (LAN primero, online después).
- (Heredado de Fase 2) `holdable_resolve_overlap` en pasillos muy estrechos; sin clic vacío, recarga ni indicador
  de munición; sin efecto de muerte; retoques del kick.
- (Heredado de Fase 3 Parte 1) Dispositivo `"keyboard2"`; `rm_intermission` sin uso.
- (Heredado de Fase 3 Parte 2) Ajustes de partida desde el lobby; controles táctiles; pulido visual de
  menú/lobby/intermission; spawners en `rm_map_sandbox_2`; mapa más grande para probar la cámara.
- (Heredado de Fase 3 Parte 3) Elegir color desde el lobby; borrar assets sin usar (diferido a la fase final).
- (Heredado de Fase 3 Parte 4) Peso del arma (P7); vsync desactivada (activar antes de publicar); ventana inicial
  a 4x; verificar contra el código real la fricción en el aire del pato y el final del slide.
- (Heredado de Fase 3 Parte 5) `corpse_spawn` hace varias cosas; un solo ángulo para las dos mitades del cadáver;
  las piezas no reciben la dirección del disparo; constantes del cadáver sin verificar.
- (Heredado de Fase 4 Parte 1) Soltar el arma agachado o deslizando; sprite al terminar un slide;
  `WEAPON_CHOICE_RANDOM` y `WEAPON_CHOICE_RANDOM_LOCKED` en archivos distintos; `Release:DEBUG_TOOLS false` por confirmar.

Resueltos en esta parte: balas que atraviesan jugadores a alta velocidad; bala naciendo dentro de una pared;
medidas de la boca del cañón por arma.

## Verificaciones hechas al cierre de la fase

Confirmadas por el usuario:
- Con `bullet_speed` en 30 el bug se reproducía antes del arreglo (Paso 0).
- Después del Paso 1: 20 disparos a otro jugador, de cerca y de lejos, mataron siempre; pegado a la mano también.
- Con una pared entre el tirador y el jugador, el de atrás no muere.
- El punto rojo de la boca del cañón se ve y coincide con el lugar de donde sale la bala.
- Tras el Paso 3: la búsqueda de `bullet_speed`, `bullet_life` y `def.damage` en todo el proyecto da 0 resultados;
  las cuatro armas conservan cadencia, retroceso y kick; el alcance en píxeles corta la bala donde se espera;
  con una pared entre medio y a 20 px/frame la bala sigue sin atravesar jugadores.
- Disparar pegado a una pared con la escopeta: el disparo se gasta y no aparece ninguna bala dentro del muro.
- El punto rojo de la boca del cañón queda en la punta también al mirar a la izquierda.
- `scr_weapon_data` revisado con las medidas finales: pistola, Magnum y SMG 15 / -5 (`muzzle_x` / `muzzle_y`); escopeta
  48 / -9.5; escopeta con `PELLET`, Magnum con `HEAVY`, pistola y SMG con `LIGHT`. `collision_line` contra el tilemap
  funcionó sin errores reportados.

Sin confirmación explícita: nada que bloquee el cierre de la parte.

## Configuración relevante en el editor

- **Sin cambios** en Input Map, grupos, Room Order ni sprites.
- **Medidas de las armas** (sprites temporales; punta del cañón y origen en píxeles del sprite):
  pistola punta (32, 13), origen (17, 18); escopeta punta (83, 9.5), origen (35, 19). Si se cambian los sprites,
  hay que volver a medir `muzzle_x` y `muzzle_y`.
- **`obj_game_manager` → Create:** `weapon_data_init()` y `ammo_data_init()` (en ese orden; las dos antes de que
  nadie dispare).
- **Capas:** las balas siguen naciendo en `layer_effects`; colisión de terreno contra `layer_collision`.
- **`scr_config`:** sin cambios en esta parte.

## Siguiente paso: Fase 4, Parte 3 — Fase B del plan (Ciclo de vida del arma)

- Clic vacío (sonido o indicador) y munición visible.
- Despawn del arma vacía al quedar quieta (fade + humo), **probado junto con los spawners**: el spawner decide si
  reaparece según el arma en su radio, y destruir armas lo afecta.
- Peso del arma: decidir si frena al jugador y/o bloquea el aleteo (hoy ninguna arma pesa).
- Kick lineal (el arma retrocede hacia el hombro) como campo nuevo de `WeaponDef`.
- Opcional: armas sin dueño que salen propulsadas al dispararse.
- Cuando haya más sprites y pruebas en equipo: retomar el Paso 4 de esta parte (velocidad y alcance de las balas) y
  el brazo que sube con una pared al frente.
