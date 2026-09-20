# Contexto del proyecto — Racoon Rumble (GameMaker LTS 2026, IDE 2026.0.0.16)

Pegar este documento al inicio de un chat nuevo, junto con `contexto_fase1_completa.md`,
`guia_documentacion_tecnica.md`, `Manual_de_Optimizacion_de_Videojuegos_GameMaker_2026.md`
y `duck_game_biblia.md` si Claude los pide o para tenerlos de referencia.

## Estado: Fase 2 (Sistema de Armas) — COMPLETA

Se construyó el sistema de armas de punta a punta con diseño data-driven: catálogo de
armas como datos, un único `obj_weapon` para todas, agarrar/tirar/lanzar con un solo
botón, disparo con proyectiles genéricos, "kick" del arma al disparar, y muerte de un
golpe. Además se adelantó un **primer boceto provisional** del flujo de partida (rondas,
siguiente mapa, puntaje final) que **será reemplazado** en la Fase 3 por el flujo definido
más abajo (sección "Siguiente paso"). Estilo de trabajo: paso a paso, explicando el porqué,
priorizando código organizado, reutilizable y sin repetición.

## Estructura nueva agregada sobre la Fase 1

```
Objects
├── Core          → obj_game_manager (modificado: catálogo, flujo de partida)
├── Players       → obj_player (modificado: arma sostenida, vida, disparo)
└── Weapons       → obj_weapon, obj_projectile            (NUEVOS)

Sprites
└── Weapons       → spr_bullet (8x3)                      (NUEVO)

Scripts
├── Core          → scr_match                             (NUEVO, provisional)
├── Player        → scr_player_weapon, scr_player_health  (NUEVOS)
└── Weapons       → scr_weapon_data, scr_weapon_actions,
                    scr_projectile                        (NUEVOS)
    (scr_config y scr_player_input: modificados)

Rooms
└── Test          → rm_sandbox_2 (duplicado de rm_sandbox, hija de rm_level_template)
```

## Clases implementadas / modificadas y su responsabilidad

**Regla de la fase:** cada script tiene una responsabilidad y el código no se repite.
Buscar/dibujar/soltar/disparar armas vive en `scr_weapon_actions` (no sabe nada de
jugadores); lo que depende del jugador vive en `scr_player_weapon`.

- **`scr_weapon_data`** — Solo datos CONSTANTES. `enum WEAPON_ID` (PISTOL, SHOTGUN,
  MAGNUM, SMG, COUNT; agregar siempre antes de COUNT, nunca reordenar). Constructor
  `WeaponDef()` con valores por defecto: `name, sprite, damage, ammo_max, fire_delay,
  recoil, bullet_speed, bullets, spread, muzzle_x, bullet_life, automatic, kick_up,
  kick_jitter, kick_max, kick_recovery`. `weapon_data_init()` construye
  `global.weapon_defs` (array indexado por el enum) una sola vez; `weapon_get_def(_id)` es
  el único punto de acceso. NO guarda estado (munición actual, kick) — eso vive en la
  instancia.
- **`obj_weapon`** — Un solo objeto para TODAS las armas (fusiona lo que iba a ser
  `obj_weapon_pickup`). `holder == noone` = suelta en el mundo; si no, la sostiene ese
  jugador. Create: `weapon_id` (llega por struct en `instance_create_layer`; por defecto
  PISTOL vía `variable_instance_exists`), `def`, `ammo`, `holder`, `hsp/vsp`, `tilemap`,
  `angle`, `spin`, `cooldown`, `kick`. Step: baja `cooldown` y `kick` SIEMPRE (también
  sostenida), y recién después hace `exit` si está sostenida; suelta: gravedad,
  `move_and_collide` en X e Y (rebote en pared, fricción en piso), rotación visual y
  aterrizaje "de pie/acostada". Draw: solo si está suelta, con
  `draw_sprite_ext(..., image_xscale, image_yscale, angle, ...)`.
- **`scr_weapon_actions`** — `weapon_find_grabbable` (arma suelta más cercana en
  `WEAPON_GRAB_RADIUS`), `weapon_draw_held(_weapon,_x,_y,_facing,_aim_up)`,
  `weapon_resolve_overlap(_weapon,_away)`, `weapon_eject(...)` (ÚNICO lugar donde un arma
  pasa de sostenida a suelta), `weapon_get_aim_angle`, `weapon_try_fire`
  (cadencia + munición + creación de balas + kick).
- **`scr_projectile` (`projectile_spawn`)** — ÚNICO punto de creación de proyectiles
  (para poder cambiar a un pool sin tocar a nadie más). Pasa `hsp, vsp, damage, life,
  owner` por struct (existen antes del Create).
- **`obj_projectile`** — Create: `tilemap`, `image_angle` según su velocidad. Step: baja
  `life`; `move_and_collide` contra el tilemap (destruye al chocar); `instance_place`
  contra `obj_player` (ignora al `owner` y a los muertos) y llama `player_take_hit`.
- **`scr_player_weapon`** — `player_update_weapon(_in)` (un botón: agarra si tiene las
  manos vacías, suelta si no), `player_grab_weapon`, `player_release_weapon(_in)`
  (arriba = lanza hacia arriba; en movimiento = lanzamiento fuerte; quieto = toss suave),
  `player_try_fire(_in)` (semiautomática con `fire_pressed`, automática con `fire_held`;
  aplica el retroceso al jugador con la dirección BASE, no la del kick).
- **`scr_player_health`** — `player_take_hit(_player,_damage)` y `player_die()`
  (estado DEAD, `visible = false`, el arma que llevaba sale despedida). Sin respawn.
- **`obj_player`** (cambios) — Create: `held_weapon = noone`, `aim_up`, `hp`. Step: si
  está DEAD hace `exit` en la primera línea; llama `player_update_weapon(_in)`,
  actualiza `aim_up` y llama `player_try_fire(_in)`. Draw: `weapon_draw_held(...)`.
- **`scr_player_input`** (cambios) — campos nuevos en el struct: `grab_pressed`,
  `up_held`, `fire_held`. Sigue siendo el único lugar que conoce teclado/gamepad.
- **`scr_match` (PROVISIONAL)** — `enum MATCH_STATE {PLAYING, ROUND_OVER, MATCH_OVER}`,
  `match_start()` (arma `global.match` con `scores`, `maps`, `map_index`, `timer`,
  `winner` y va al primer mapa), `match_update()` (cuenta jugadores vivos; con ≤1 vivo
  sube el puntaje del ganador, espera `MATCH_ROUND_END_FRAMES`, pasa al siguiente mapa o
  a MATCH_OVER; en MATCH_OVER cualquier jugador reinicia con salto),
  `match_draw_debug()` (TEMPORAL: texto simple).
- **`obj_game_manager`** (cambios) — Create: `weapon_data_init()` y luego
  `match_start()` (reemplazó al `room_goto(rm_sandbox)`). Step: `match_update()`.
  Draw GUI: `match_draw_debug()`. Room Start: sigue creando jugadores; contiene además
  un bloque TEMPORAL que crea armas de prueba.

**Macros nuevas en `scr_config`** (valores de partida, afinados a ojo):
`WEAPON_GROUND_FRICTION 0.3`, `WEAPON_WALL_BOUNCE 0.4`, `WEAPON_GRAB_RADIUS 24`,
`WEAPON_THROW_MIN_SPEED 0.5`, `WEAPON_THROW_SPEED 9`, `WEAPON_THROW_LIFT -3`,
`WEAPON_THROW_UP_SPEED 9`, `WEAPON_THROW_SPIN 14`, `WEAPON_DROP_SPEED 3`,
`WEAPON_DROP_LIFT -2`, `WEAPON_DROP_SPIN 3`, `WEAPON_SETTLE_RATE 0.25`,
`WEAPON_MAX_PUSHOUT 96`, `HAND_OFFSET_X 8`, `HAND_OFFSET_Y -18`, `PLAYER_MAX_HP 1`,
`MATCH_ROUND_END_FRAMES 150`.

## Bugs encontrados y resueltos durante esta fase

1. **Síntoma:** `Variable obj_player.HAND_OFFSET_Y ... not set before reading it` al
   agarrar un arma por primera vez.
   **Causa real:** `HAND_OFFSET_X/Y` nunca estuvieron definidas como macros. El Draw
   viejo del jugador solo las evaluaba con `held_weapon != noone`, y hasta esta fase
   nadie sostenía nada, así que el error estaba latente. GameMaker interpreta un nombre
   desconocido como variable de instancia sin asignar (misma familia que el bug #3 de la
   Fase 1).
   **Fix:** definir ambas macros en `scr_config`.

2. **Síntoma:** errores de parseo en `scr_player_input` ("malformed assignment", "expected
   '}'", "expected ','").
   **Causa real:** al agregar un campo nuevo al final del struct, el campo que antes era
   el último quedó sin coma. En un struct literal todos los campos llevan coma salvo el
   último.
   **Fix:** agregar la coma faltante. (Pasó dos veces al sumar campos al input: revisar
   siempre la coma.)

3. **Síntoma:** al soltar el arma quieto, "se teletransportaba" al piso.
   **Causa real:** nacía en `y - 8` (a la altura de los pies), no en la mano; no recorría
   ninguna caída.
   **Fix:** nace en la mano y la gravedad hace el resto.

4. **Síntoma:** el arma tirada volvía a mirar como al principio, sin conservar hacia
   dónde miraba el jugador.
   **Causa real:** solo el jugador tenía `facing`; el arma suelta se dibujaba con
   `image_xscale = 1` por defecto.
   **Fix:** `weapon_eject` copia `facing` a `image_xscale` al soltarla.

5. **Síntoma:** arma suelta quedaba incrustada/flotando dentro de una pared al soltarla
   pegado a ella.
   **Causa real:** el primer chequeo probaba un solo píxel (`tilemap_get_at_pixel`) pero
   la máscara del arma es ancha; `move_and_collide` solo resuelve choques durante el
   movimiento, no libera un objeto que NACE solapado.
   **Fix:** `weapon_resolve_overlap` comprueba la máscara completa con `place_meeting`.

6. **Síntoma:** la escopeta (86 px) pegada del todo a la pared la atravesaba al soltarla.
   **Causa real (diagnóstico por razonamiento, ver "Verificaciones"):** la búsqueda de
   hueco probaba ambos sentidos alternando; un hueco libre del OTRO lado del muro también
   es "libre", y con paredes finas aparecía antes que el hueco válido.
   **Fix:** buscar solo en el sentido que se aleja de la pared (`-facing`), probando a cada
   distancia primero tal cual y luego espejada. Lección: un lugar libre no equivale a un
   lugar válido.

## Decisiones de diseño explícitas tomadas en esta fase

- **`obj_weapon` único con `holder`** (en vez de `obj_weapon` + `obj_weapon_pickup`):
  agarrar es poner `holder`; tirar es ponerlo en `noone`. La misma instancia vive toda la
  partida, así se conserva la munición y no se crean/destruyen instancias.
- **Definición (constante) separada de estado (por instancia):** todas las pistolas
  comparten un struct `WeaponDef`; solo `ammo`, `kick`, `cooldown` son propios.
- **Catálogo = array indexado por enum**, no `ds_map` (acceso directo, sin `ds_*`, lo
  recomienda el manual de optimización).
- **Struct como último argumento de `instance_create_layer`:** sus variables existen ANTES
  del Create. El "Creation Code" del editor corre DESPUÉS del Create, por eso se descartó
  para configurar el tipo de arma.
- **Un botón agarrar/tirar, tres formas de soltar:** mirando arriba → hacia arriba; en
  movimiento (`abs(hsp) > WEAPON_THROW_MIN_SPEED`) → lanzamiento fuerte heredando la
  velocidad; quieto → toss suave hacia adelante. La idea inicial ("quieto = cae a los
  pies") se cambió por pedido del usuario. Se decide por `hsp`, no por la tecla, así
  sirve igual con joystick analógico o táctil.
- **Rotación de la arma suelta solo VISUAL (`angle`), nunca `image_angle`:**
  `image_angle` rota también la máscara de colisión y el arma se trabaría en las paredes.
  Costo aceptado: en el aire sprite y máscara no coinciden del todo.
- **Aterrizaje "de pie" o "acostada":** rotar 180° equivale a espejar X e Y a la vez, y
  `image_xscale/yscale` sí voltean la máscara, así sprite y colisión coinciden. Al aterrizar
  con ángulo entre 90° y 270° se espeja y se resta 180° (el dibujo no cambia en ese
  instante), después el resto se endereza con `lerp`. Puede haber un saltito de unos
  píxeles por el ajuste hacia arriba. **Descartado:** "vertical" (parada sobre la culata):
  exigiría rotar la máscara 90° (sprite/máscara aparte por arma).
- **Kick ≠ spread:** `spread` es un error aleatorio por bala con el arma quieta; `kick`
  cambia la orientación del arma misma (estado por instancia). Un solo mecanismo cubre dos
  comportamientos: revólver (`kick_up` alto, recuperación lenta → sube con cada disparo) y
  automática (`kick_jitter`, recuperación rápida → tiembla arriba/abajo). Referencia
  confirmada en la wiki de Duck Game: el Magnum se inclina hacia arriba con cada disparo y
  baja lentamente; el temblor de las automáticas se implementó según la descripción del
  usuario (no se halló fuente).
- **La bala sale con la orientación ACTUAL y el kick se aplica DESPUÉS** (el primer tiro
  sale recto). El retroceso al jugador usa la dirección base.
- **Cadencia por contador de frames**, no `time_source`, por ser más barato para algo tan
  frecuente.
- **Un solo punto de creación de proyectiles** (`projectile_spawn`) para poder migrar a
  object pooling sin tocar a los llamadores; hoy no hace falta.
- **Refactor `weapon_eject`:** dos sitios sueltan armas (el botón y la muerte); se extrajo
  a una función para no repetir código.
- **Vida (`hp`) aunque hoy todo mata de un golpe** (`PLAYER_MAX_HP 1`): permite armas con
  daño parcial o armadura sin reescribir.
- **Contador de frames en lugar de `call_later` para el respawn** (descartado): la
  referencia a una instancia destruida podía quedar colgando al cambiar de room.
  Finalmente el respawn se eliminó del todo por decisión del usuario.
- **Muerte de un golpe SIN respawn (como Duck Game):** el jugador muerto se oculta y
  espera; al cambiar de mapa los jugadores se recrean (Room Start del manager).
- **Estado de partida en `obj_game_manager`** (persistente): los jugadores mueren con cada
  room, los puntos no pueden vivir en ellos.

## Pendiente identificado, no bloqueante

Deuda técnica a propósito, documentada:
- `TEMPORAL:` armas de prueba (pistola, escopeta, Magnum, SMG) creadas en el Room Start de
  `obj_game_manager`; se reemplazan por spawners de armas en los niveles.
- `TEMPORAL:` `match_draw_debug` (texto simple); se reemplaza por la UI real.
- `TEMPORAL:` Magnum y SMG usan `spr_weapon_gun_1` prestado; falta arte propio.
- `TEMPORAL:` si quedó la línea `show_debug_message(weapon_get_def(...).name)` del Paso 1
  en `obj_game_manager`, borrarla.
- El primer boceto de `scr_match` (playlist finita → MATCH_OVER) se reescribe en Fase 3.

Bugs / limitaciones menores conocidos:
- **Retoques del kick/armas:** el usuario anunció que hay retoques por hacer (sin detalle
  todavía); se harán más adelante.
- **Balas que atraviesan jugadores:** el choque con jugadores se comprueba solo al final de
  cada frame; una bala más rápida que ~24 px/frame (ancho del jugador + de la bala) puede
  saltárselo. Hoy la más rápida va a 16. Con un francotirador hay que pasar a
  `collision_line`.
- Si se dispara pegado a una pared, la bala puede nacer dentro del tilemap.
- Si un pasillo es más estrecho que el arma, `weapon_resolve_overlap` puede no hallar
  hueco en `WEAPON_MAX_PUSHOUT` px y la deja donde nació.
- Sin sonido/indicador de "clic vacío", sin recarga, sin indicador de munición.
- Sin efecto ni sprite de muerte (el jugador solo se oculta).
- Apuntado limitado a 3 direcciones (derecha, izquierda, arriba).
- Los 4 jugadores existen siempre, haya o no mando conectado (necesita lobby).
- El dispositivo de cada jugador está fijo en código (jugador 0 = teclado + ratón, el resto
  = mando `player_index - 1`); el input táctil para celular aún no existe (los campos
  del struct de input ya están listos para llenarse).

Heredados de la Fase 1 (siguen sin resolver):
- (Heredado de Fase 1) Sprite propio para `FALL` y `SLIDE` (hoy reusan `jump`/`idle`).
- (Heredado de Fase 1) Reducción real de hitbox en `SLIDE`.
- (Heredado de Fase 1) Mecánica `FLAP`.
- (Heredado de Fase 1) Fase B del sistema brazo/arma: brazo independiente con ángulo de
  apuntado libre (esta fase solo agregó inclinar el arma hacia arriba y el kick).
- (Heredado de Fase 1) `obj_room_controller` sin uso: decidir si se borra.
- (Heredado de Fase 1) `spr_player_run_gun` / `spr_player_run_gun_2` sin conectar.
- (Heredado de Fase 1) Diseño de la capa de red (LAN primero, online como extensión).
- (Heredado de Fase 1) Agregar `.gitattributes` (`*.yy linguist-generated=true`).

Resuelto en esta fase: "Sistema de armas en sí (`obj_weapon`, pickup, disparo)" pendiente
de la Fase 1.

Decisión pendiente de documentar:
- **ADR-001 (a escribir cuando se cierre el diseño de la Fase 3):** flujo de partida
  (lobby, rondas, intermission, desempate). Cumple los cuatro criterios de la guía: afecta
  a varios sistemas, es cara de revertir, hubo debate y es probable que se cuestione luego.

## Verificaciones hechas al cierre de la fase (todas OK)

Confirmadas por el usuario:
- Agarrar y soltar con el mismo botón; lanzar en movimiento; lanzar hacia arriba.
- El arma suelta conserva hacia dónde miraba, gira en el aire y cae de pie o acostada
  (el usuario quedó conforme con el resultado).
- Disparo con pistola y escopeta (cadencia, munición, dispersión, retroceso) y con
  Magnum/SMG (kick).
- Una bala mata de un golpe; los muertos no respawnean.
- Con un solo jugador vivo: aparece el ganador, pasa al siguiente mapa, y tras el último
  se muestra el puntaje final y se puede reiniciar.

Sin confirmación explícita (se corrigió por diagnóstico y no se reportó de nuevo):
- Bug #6: la escopeta contra la pared ya no la atraviesa.

## Configuración relevante en el editor

- **`spr_bullet`:** 8x3 px, amarillo; Origin `Middle Center`; Collision Mask `Automatic`;
  Texture Group por defecto (se agrupa con jugador y armas para no cortar el batch).
- **`obj_projectile`:** sprite asignado `spr_bullet`.
- **`obj_weapon`:** sin sprite asignado (lo pone su Create según el arma).
- **Eventos de `obj_game_manager`:** Create, Room Start, **Step (nuevo)**, **Draw GUI
  (nuevo)**. Sigue con **Persistent** activada.
- **`rm_sandbox_2`:** duplicado de `rm_sandbox`; debe seguir siendo hija de
  `rm_level_template` y tener `obj_spawn_point`. No se tocó el Room Order: `room_goto`
  funciona con cualquier room y el orden real de mapas lo define el array `maps` de
  `scr_match`.
- **Capas usadas:** armas en `layer_items`, proyectiles en `layer_effects`, colisión contra
  `layer_collision` (nombres exactos, case-sensitive).
- **Controles actuales:**
  - Jugador 1 (teclado + ratón): A/D mover, Espacio saltar, **E** agarrar/tirar, **W**
    apuntar arriba, clic izquierdo disparar (mantener para automáticas).
  - Jugadores 2-4 (mando, `player_index - 1`): stick izquierdo mover, `gp_face1` saltar,
    `gp_face3` agarrar/tirar, stick hacia arriba apuntar arriba, `gp_shoulderrb` disparar.
- **Sin cambios** en Input Map, grupos ni Room Order (no se usan; el input se lee directo
  en `scr_player_input`).

## Siguiente paso: Fase 3 — Flujo de partida, lobby y menú

**Diseño de flujo definido por el usuario** (reemplaza el modelo provisional de `scr_match`):

```
Menú → crear lobby → lobby → (cuenta 5-4-3-2-1) → partida → intermission → ...
```

- **Lobby jugable, como el de Duck Game:** los jugadores se mueven por él, ven a los demás y
  personalizan su personaje. Ahí mismo se personaliza la partida: cantidad de mapas
  (rondas por bloque), puntos necesarios para ganar (ejemplo: 10), y más opciones de la
  partida y de la intermission.
- **Inicio de ronda:** los jugadores se colocan en el medio del mapa y corre una cuenta
  regresiva 5-4-3-2-1 antes de empezar.
- **Intermission:** si ningún jugador alcanzó el puntaje objetivo, se juega otra vez la
  misma cantidad de rondas hasta la siguiente intermission, y así hasta que haya un
  ganador.
- **Empate:** se juega 1 ronda solo entre los jugadores empatados y quien la gane es el
  ganador final.

**Lo que ya está listo y se reutiliza:** el estado de partida en `obj_game_manager`
persistente, el conteo de vivos y la detección de fin de ronda, el puntaje por jugador, los
jugadores recreados en cada Room Start, y el input abstraído. **Lo que cambia:** `maps`
pasa de playlist finita a una configuración de partida; `MATCH_STATE` crece
(LOBBY, COUNTDOWN, PLAYING, ROUND_OVER, INTERMISSION, MATCH_OVER, TIEBREAK); hace falta un
struct de ajustes de partida; y el dispositivo de cada jugador debe pasar de estar fijo en
código a una asignación jugador→dispositivo (quién se unió y con qué).

**Plan tentativo:**
1. Lobby de unión: quién juega (teclado, mandos, y táctil para celular). Resuelve el
   problema de los "4 jugadores siempre".
2. Ajustes de partida y estados nuevos (cuenta regresiva, intermission, desempate).
3. Spawners de armas en los niveles (reemplaza el código TEMPORAL).
4. Pantallas de UI reales (menú, puntaje, intermission) con escala pensada para celular.

**Por decidir en el próximo chat:**
- (RESUELTO, confirmado por el usuario) "Cantidad de mapas" = cuántas rondas se juegan
  entre una intermission y la siguiente.
- ¿Cómo se eligen los mapas: orden fijo, al azar o pool configurable? ¿Pueden repetirse?
- ¿Qué pasa si el desempate vuelve a empatar?
- "Los jugadores se ponen en el medio del mapa": ¿spawn central o cámara centrada
  en el mapa antes de la cuenta regresiva?
- Alcance de "crear lobby": ¿solo local por ahora (recomendado) o ya pensado para red?
- Escribir el ADR-001 con estas decisiones cerradas.
