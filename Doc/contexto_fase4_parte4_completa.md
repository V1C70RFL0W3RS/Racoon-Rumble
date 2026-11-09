# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase4_parte3_completa.md`,
`contexto_fase4_parte2_completa.md`, `contexto_fase4_parte1_completa.md`, los ADR (001–004),
`guia_documentacion_tecnica.md`, `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md` y
`duck_game_biblia.md` si Claude los pide o para tenerlos de referencia.

## Estado: Fase 4 (Armas, físicas y efectos), Parte 4 — Balas contra cadáveres + estela legible — COMPLETA

Las balas ya no atraviesan el cadáver: lo empujan en su dirección y lo usan como escudo imperfecto (parte de las
balas pasa). Al morir por un disparo, el cadáver sale volando hacia donde lo empujó la bala. Se dejó la base para
munición que atraviesa (sniper futuro) y para objetos que reciben balas (cajas que se rompen). La estela de la bala
ahora invierte el color del fondo para leerse sobre fondos blancos.

Forma de trabajo sin cambios: Claude edita los archivos; el usuario elige **Recargar** (nunca Guardar) y prueba.

## Clases implementadas / modificadas y su responsabilidad

### Datos
- **`AmmoDef`** (`scr_ammo_data`), campos nuevos:
  - `impact` — empujón en px/frame a lo que golpea. LIGHT 3, HEAVY 6, PELLET 1.5.
  - `pierce` — cuántos objetos `shootable` atraviesa siempre (0 en todas; sniper futuro ≥ 1). A los jugadores
    nunca los atraviesa.
  - `trail_invert` — `true` (defecto) = la estela invierte el color del fondo; `false` = usa `trail_color`
    (balas de color, p. ej. láser).
- **`WeaponDef.impact_mult`** (`scr_weapon_data`, defecto 1): multiplica el `impact` de la munición por arma.
  SMG = **0.4** (comparte LIGHT con la pistola pero dispara 10/s; con 3 lanzaba el cadáver).
- **`obj_holdable` → Create**, banderas nuevas (ADR-003: lo propio de cada tipo va en banderas):
  - `shootable = false` — ¿lo detectan las balas?
  - `impact_mult = 1` — cuánto lo mueve un disparo (0 = no se mueve).
  - `block_chance = 1` — probabilidad de **detener** la bala; si no, la deja pasar (igual la empuja).
- **`obj_corpse_piece` → Create**: `shootable = true`, `impact_mult = CORPSE_IMPACT_MULT`,
  `block_chance = CORPSE_BLOCK_CHANCE`.

### Balas (`scr_projectile`, `obj_projectile`)
- `projectile_spawn(..., _impact_mult = 1)`: la bala guarda `impact` ya multiplicado, `pierce` y `trail_invert`.
- **`projectile_find_hit(_x1,_y1,_x2,_y2,_owner,_ignore)`**: busca jugadores vivos **y** holdables `shootable`
  sueltos (descarte barato primero: bandera y `holder`, después `collision_line`). Devuelve el **primero en la
  trayectoria** (proyección del centro sobre la dirección del segmento), no el más cercano en línea recta.
  `_ignore` = lo ya atravesado.
- `obj_projectile` Create: `hit_list = []` (lo atravesado; evita golpear la misma pieza el frame siguiente).
- `obj_projectile` Step, bucle sobre el segmento del frame:
  1. Jugador → `player_take_hit(_t, damage, _dir, impact)` y se destruye.
  2. Holdable → `holdable_take_shot` (empuja **siempre**). Luego: `pierce > 0` → descuenta y sigue; si no,
     `random(1) < block_chance` → se detiene. Si sigue, se agrega a `hit_list` y se busca el siguiente en el
     **mismo** segmento (un jugador detrás del cadáver recibe el disparo ese frame).
- **Estela**: `projectile_draw_trail` + `projectile_draw_strip(cola→punta con color y alpha propios)`.
  Con `trail_invert`: `gpu_set_blendmode_ext_sepalpha(bm_inv_dest_colour, bm_inv_src_colour, bm_zero, bm_one)`
  y degradado **por color** (negro en la cola = sin cambio, blanco en la punta = invierte). El alpha del destino
  se conserva para no dejar huecos en la application_surface.

### Holdables (`scr_holdable`)
- **`holdable_take_shot(_h, _dir, _power)`**: ÚNICA entrada de una bala a un objeto (como `player_take_hit`).
  Suma `_power × impact_mult` en la dirección de la bala; si está en una mano no hace nada. Los topes
  `HOLDABLE_MAX_*` los aplica el Step. Aquí se sumará el daño de las cajas.

### Muerte con dirección
- `player_take_hit(_player, _damage, _dir = 0, _power = 0)` → `player_die(_dir = 0, _power = 0)` →
  `corpse_spawn(..., _hit_dir = 0, _hit_power = 0)`: el empujón se suma a la inercia y al saltito con la misma
  fórmula que un disparo a un cadáver caído (`impact × CORPSE_IMPACT_MULT`). La muerte por caída llama
  `player_die()` sin argumentos (sin empujón). Con la escopeta, los perdigones siguientes empujan además al
  cadáver recién creado.

## Decisiones de diseño explícitas tomadas en esta parte
- **La bala se detiene en el cadáver por defecto**, pero el cadáver es **escudo imperfecto**: cada pieza bloquea
  el 50 % (las dos juntas ≈ 75 %). Atravesar no quita el empujón. Decisión del usuario.
- **Dos mecanismos separados para atravesar:** `pierce` es de la **munición** y es determinista (sniper);
  `block_chance` es del **objeto** y es azar (cadáver, cajas). Se evalúa primero `pierce`.
- **Solo el cadáver es `shootable` por ahora**; armas en el piso no (basta con encender la bandera).
- **Pieza en la mano no se empuja y la bala la atraviesa** (no sirve de escudo sostenida). Sin objeción del
  usuario; revisable.
- **Ajuste de empujón por arma (`impact_mult`)** en vez de una munición nueva para la SMG.
- **Estela: inversión del fondo** en vez de contorno (al usuario no le gustó el contorno) y en vez de leer
  píxeles (`surface_getpixel` es muy lento, sobre todo en celular).

## Pendiente identificado, no bloqueante

Nuevo en esta parte:
- **Red:** `block_chance` usa `random()`. En LAN/online cada máquina sacaría un resultado distinto: la decisión
  debe tomarla el host (o usar una semilla compartida). Tenerlo en cuenta al diseñar la capa de red.
- **Estela sobre gris medio:** la inversión da casi el mismo gris. Si pasa en un mapa, combinar inversión con un
  núcleo fino de color.
- Pieza del cadáver sostenida como escudo (hoy la bala la atraviesa).
- Sin efecto visual al impactar un cadáver (chispas/pelo); encaja con el efecto de muerte.
- Cajas que se rompen con balas: usar `shootable`, `block_chance` y daño en `holdable_take_shot`.

Heredados que siguen sin resolver: ver `contexto_fase4_parte3_completa.md` (sonidos `snd_empty`/`snd_rack`,
ajustes persistentes, Paso 4 velocidad/alcance de balas, brazo con pared al frente, efecto de muerte,
`keyboard2` TEMPORAL, controles táctiles, capa de red, etc.).

Resueltos en esta parte: balas que solo detectaban `obj_player`; `projectile_find_hit` por distancia al centro;
piezas del cadáver sin la dirección del disparo; estela poco visible sobre fondos blancos.

## Verificaciones hechas al cierre (confirmadas por el usuario)
- Disparar al cadáver lo empuja y la bala se detiene / a veces lo atraviesa.
- El cadáver sale en la dirección del disparo al morir; SMG ya no exagera (impact_mult 0.4).
- Estela invertida visible sobre fondos claros ("va bien por el momento").

## Configuración relevante
- **`scr_config`** (sección CADÁVER): `CORPSE_IMPACT_MULT 1`, `CORPSE_BLOCK_CHANCE 0.5`.
  Quitadas: `PROJECTILE_TRAIL_OUTLINE*` (contorno descartado).
- Sin cambios en el editor (no hubo assets nuevos).

## Siguiente paso sugerido
- Efecto de muerte (pelo/humo con `scr_fx`) y efecto de impacto en el cadáver.
- O el brazo que sube con pared al frente, o el Paso 4 de velocidad/alcance con el equipo.
