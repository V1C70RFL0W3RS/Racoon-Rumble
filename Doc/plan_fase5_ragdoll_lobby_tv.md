# Plan — Fases 5 a 8: Ragdoll, Casa de los Fans, Trash TV y Premiación

> Racoon Rumble · GameMaker LTS 2026 (IDE 2026.0.0.16) · Plan escrito el 11 nov 2026
> Estado: **APROBADO EN LO GENERAL** — decisiones en §11.
> Se apoya en: ADR-001 (flujo de partida), ADR-003 (agarrables), `contexto_fase4_partes6_7_8_9.md`.

---

## 0. Resumen en una pantalla

| Fase | Nombre | Qué deja funcionando | Partes |
|---|---|---|---|
| **5** | Ragdoll y equipamiento | Botón de "hacerse el muerto", arrastrarse, salir saltando; gorros físicos que se caen, se agarran y se equipan | 2 |
| **6** | La Casa de los Fans (lobby) | Lobby nuevo con cámara fija: tubo de llegada, sofá de 8 asientos, ropero, PC del host, TV encendida | 3 |
| **7** | Trash TV (motor de transmisión) | Pantalla de TV con efecto CRT, diálogos con 3 personajes, skip con manos, presentación de competidores, mejores momentos | 5 |
| **8** | Estadio y premiación | Pruebas animadas que muestran el puntaje, podio, portada de periódico, votación revancha/lobby | 4 |

**Orden y por qué:** el ragdoll va primero porque el lobby lo usa (los jugadores llegan por el tubo *en modo ragdoll*). El lobby va antes que la TV porque la TV del lobby es la primera pantalla que muestra la transmisión. La premiación va al final porque necesita el motor de TV y las estadísticas de la Fase 7.

Cada **Parte** termina en algo que puedes probar en el juego y confirmar antes de pasar a la siguiente (como hasta ahora).

---

## 1. Mundo y tono (lore)

- **Ciudad:** *Trash City*, una ciudad construida sobre un vertedero, donde los mapaches son celebridades.
- **Evento:** *XV Gran Torneo Rumble de Trash City* (el decimoquinto). Logo: un "XV" hecho con dos latas aplastadas y una tapa de basurero de corona.
- **Canal:** **TCTV — Canal 15** ("Trash City TV, la señal que huele a victoria"). Todo lo que sale "en la tele" lleva su logo en la esquina, la etiqueta **EN VIVO** y un zócalo con noticias absurdas.
- **Estadio:** *Estadio Vertedero Municipal* (gradas de neumáticos, pantalla gigante hecha con TVs rotas, reflectores de faroles).
- **Periódico:** *La Gaceta de Trash City* ("Noticias frescas desde 1987. Bueno, noticias.").
- **El lobby:** la sala de una familia de fans fanáticos (banderines, latas apiladas, fotos de campeones anteriores, un tubo de ventilación por donde "llegan" los competidores).

### 1.1 Elenco de la transmisión (personajes originales)

| Rol | Personaje | Especie / look | Personalidad | "Voz" (placeholder) |
|---|---|---|---|---|
| **Locutor** (presentador del torneo y del estadio) | **Rocco Basurto** | Zarigüeya con traje de lentejuelas y micrófono de lata | Grandilocuente, alarga las vocales: "¡¡Bienveniiidos!!" | blips graves y lentos |
| **Narrador** (cuenta la jugada) | **Lalo Latas** | Rata con audífonos gigantes | Rápido, gritón, inventa palabras | blips agudos y rápidos |
| **Comentarista** (analiza la jugada) | **Gertrudis Gaviota** | Gaviota ex-campeona, lentes de sol | Seca, sarcástica, técnica | blips medios, pausados |

Cómo trabajan juntos (como en una transmisión real): **Lalo narra** lo que pasó, **Gertrudis lo analiza** y **Rocco presenta** (abre, cierra, anuncia puntajes y ganadores).

### 1.2 Muestras de diálogo (tono)

> **Rocco:** ¡Buenas noches, Trash City! ¡Desde el Estadio Vertedero Municipal, bienvenidos al decimoquinto Gran Torneo Rumble!
> **Lalo:** ¡Quince años, Rocco! ¡Y el olor sigue igual de fuerte!
> **Gertrudis:** Ese es el puesto de hot dogs, Lalo.

> **Rocco:** Por la esquina azul, con su {gorro} reglamentario... ¡**{apodo}**!
> *(apodos generados: "El Terror del Contenedor", "La Pesadilla Reciclable", "Mano de Lata", "El Barón del Cartón"...)*

> **Lalo:** ¡{jugador} se hizo el muerto... y le FUNCIONÓ!
> **Gertrudis:** La técnica de la zarigüeya. Rocco debe estar orgulloso.
> **Rocco:** *(desde fuera de cámara)* ¡Es patrimonio familiar!

> **Lalo:** ¡A {víctima} le cayó una caja en la cabeza!
> **Gertrudis:** Mirar hacia arriba. Lección número uno.

> **Lalo:** {víctima} decidió explorar el fondo del mapa.
> **Gertrudis:** Valiente. Equivocado, pero valiente.

Los diálogos viven en un archivo de datos (ver §6.4), con **variantes** por evento para que no se repitan.

---

## 2. Flujo completo de una partida

```
Menú ─► CASA DE LOS FANS (lobby, cámara fija)
          │  llegan por el tubo (ragdoll) · ropero · PC host · TV encendida
          │  todos sentados en el sofá (mín. N) ─► "¡Silencio, empieza!"
          ▼
        Zoom a la TV ─► SHOW "PRESENTACIÓN" (Rocco presenta a cada competidor)
          ▼
   ┌─► Cuenta 5-4-3-2-1 ─► RONDA ─► ... (bloque de rondas, como hoy)
   │      ▼
   │   SHOW "ENTRETIEMPO": estudio (Lalo + Gertrudis) ─► mejores momentos
   │      ─► corte al ESTADIO: Rocco anuncia puntajes con la PRUEBA animada
   │      ▼
   └── ¿alguien llegó a los puntos? no ─┘   sí ─► (empate ─► desempate, igual que hoy)
          ▼
        SHOW "FINAL": prueba animada final ─► PODIO ─► foto ─► PORTADA DEL PERIÓDICO
          ▼
        VOTACIÓN: [Revancha]  [Volver a la casa]
```

En cualquier show: **skip** con la manito y el cartel (§6.5).

---

## 3. FASE 5 — Ragdoll y equipamiento

### 3.1 Comportamiento acordado

- Una tecla activa el **modo ragdoll**: el jugador cae al piso como un cadáver, con **la misma física del cadáver** (la pareja de piezas de la Parte 5, Fase 3).
- Los demás **lo pueden agarrar y lanzar** como a un cadáver.
- Se le **cae el gorro** (sale volando como objeto agarrable).
- Lo que tenía en la mano **se cae** (como al agacharse: sin impulso).
- Solo se puede **arrastrar a izquierda y derecha** (empujoncitos cortos, solo con la pieza en el piso).
- **Saltar = salir** del ragdoll: se pone de pie donde está la pieza superior.
- Para recuperar el gorro, lo **agarra** con el botón de agarrar y se lo **pone** automáticamente. Si ya lleva un gorro (u otro casco), **el que tenía pasa a la mano**.

### 3.2 Reglas finas que propongo (puedes cambiarlas)

| Situación | Propuesta |
|---|---|
| Le disparan al ragdoll **sin protección** | **Muere de verdad**: las piezas pasan a cadáver (ojos sin pupila) y suelta pelo. Fingir es arriesgado. |
| Le disparan al ragdoll **con equipamiento que bloquea balas** (chaleco, casco...) | El equipamiento **detiene esa bala y se rompe** (sale volando en pedazos con chispas). La siguiente bala ya mata. Se usa primero el que cubre la pieza golpeada (§3.4). |
| Le cae una caja encima | Muere (igual que de pie). |
| Cae fuera del mapa | Muere. |
| Alguien lo lleva en la mano | **Queda atrapado:** saltar **no** lo libera. Puede seguir moviendo el ragdoll (izquierda/derecha sacuden la pieza que cuelga), pero **sin afectar** al jugador que lo sostiene. Solo sale cuando el otro lo suelta o lo lanza; entonces vuelve a poder levantarse saltando. |
| Para el conteo de la ronda | Cuenta como **vivo** (si no, la ronda terminaría y el engaño no serviría). |
| Ojos | La pieza superior usa el frame **vivo** (con pupila). Detalle para los atentos: parpadea cada tanto. |
| Enfriamiento | 0,4 s entre entrar y salir para que no se pueda abusar como "esquiva instantánea". |
| Teclas | Teclado: **X** · Mando: **Y / Triángulo** · Celular: botón en pantalla (cuando se diseñen los controles táctiles). |

### 3.3 Cómo se implementa (reutilizando, sin duplicar)

La idea clave: **el ragdoll ES un cadáver con dueño vivo.** No se escribe física nueva.

1. **`corpse_spawn` se generaliza** (`scr_corpse`):
   - Devuelve la pareja `{ upper, lower }` en vez de nada.
   - Nuevo parámetro `_owner` (`noone` = cadáver normal; un jugador = ragdoll). Con dueño, la pieza superior usa el frame vivo (0) en vez del muerto (2).
   - Un solo lugar crea piezas, como ya está decidido.
2. **Nuevo estado `PLAYER_STATE.RAGDOLL`** (`scr_player_state_machine`) y nuevo script **`scr_player_ragdoll`**:
   - `player_ragdoll_enter()`: suelta el ítem, tira el gorro, crea la pareja con `_owner = id`, oculta al jugador y **desactiva su máscara** (las balas y las cajas golpean a las piezas, no al jugador invisible).
   - `player_ragdoll_update(_in)`: el jugador "sigue" a la pieza superior (así la cámara lo sigue sin cambios), aplica el arrastre (`RAGDOLL_CRAWL_IMPULSE`, solo si la pieza toca el piso y cada `RAGDOLL_CRAWL_INTERVAL` frames, para que se vea como tirones), y con salto llama a `player_ragdoll_exit()` **solo si ninguna de sus piezas tiene `holder`**.
   - **Atrapado:** si una pieza está en una mano, el input horizontal empuja **solo la pieza suelta** (`RAGDOLL_STRUGGLE_IMPULSE`). Esto ya es gratis con `corpse_pair_update`: la pieza sostenida es el punto fijo y nunca transmite fuerza a quien la sostiene, así que el que agarra no se mueve.
   - `player_ragdoll_exit()`: busca un lugar libre con `player_fits_mask` (mismo patrón de desincrustar del cadáver), destruye las piezas, restaura máscara y estado.
3. **Daño desde ragdoll:** `holdable_take_shot` y `holdable_try_crush`, si la pieza tiene `owner` vivo, llaman a **`player_take_hit`** del dueño (el mismo camino que de pie). Ahí, antes de restar vida, se pregunta a `equipment_try_block(player, piece)`: si hay un equipo que bloquea, se rompe y la bala se detiene. Si no, `player_die`, que reconoce que ya hay piezas: **no crea otras**, solo las "mata" (frame 2, `owner = noone`, pelo). Cero cadáveres duplicados.
4. **`get_player_input`** suma el campo `ragdoll_pressed` en `input_empty()` y en cada dispositivo. Ningún otro sistema lee teclas.

### 3.4 Gorros físicos y equipamiento (base para cascos y armaduras)

- Nuevo **`obj_hat`** (hijo de `obj_holdable`): se agarra, se lanza, rebota. Variable `hat_index` (frame de `spr_hats`).
- **Tres ranuras de equipamiento:** `EQUIP_SLOT.HEAD` (gorros, cascos), `EQUIP_SLOT.BODY` (chaleco antibalas...) y `EQUIP_SLOT.FEET` (botas...). Nueva bandera en `obj_holdable`: **`equip_slot`** (`EQUIP_SLOT.NONE` por defecto).
- **Equipos que bloquean balas:** bandera `bullet_block` (cuántas balas detiene; **1** para el chaleco y el casco). Al detener una bala se rompe (`holdable_break`, con fragmentos y chispas). Los gorros de lobby tienen `bullet_block = 0` (decorativos).
- **Qué pieza protege cada ranura:** pieza superior (cabeza y torso) → HEAD, luego BODY; pieza inferior → BODY, luego FEET. De pie, la misma regla según la altura del impacto. *(La regla de bloquear vale también de pie, para que el chaleco sirva siempre; si quieres que sea solo en ragdoll, es un cambio de una línea.)*
- En el jugador: `equipped = [noone, noone, noone]` (un objeto por ranura, guardado fuera del mundo mientras lo lleva puesto). Al crear al jugador se le pone el gorro elegido en el lobby. Cada equipo se dibuja con su propio punto de anclaje (cabeza: el de los gorros de hoy; torso y pies: tablas nuevas por frame, como la del hombro).
- `player_grab_item()` gana una rama: si lo que agarra tiene `equip_slot != NONE` → **`player_equip(item)`**: se lo pone; si ya había algo en ese slot, lo que tenía se crea como objeto y pasa **a la mano**.
- `player_unequip_drop(slot, hsp, vsp)`: el gorro sale volando (lo usan el ragdoll **y la muerte**: esto resuelve el pendiente #8 "gorro en cadáver").
- Se puede robar el gorro de otro jugador (si lo agarras del piso). Al empezar cada ronda cada uno vuelve a su gorro del lobby.
- **ADR-004 "Equipamiento"** documentará la decisión (bandera en el padre en vez de un objeto separado, por ADR-003).

### 3.5 Partes

| Parte | Contenido | Prueba de cierre |
|---|---|---|
| **5.1** Ragdoll | `corpse_spawn` generalizado, estado RAGDOLL, arrastre, salir saltando, agarrarlo (atrapado), morir desde ragdoll | Tirarse, arrastrarse, que otro lo agarre: saltar no libera y sacudirse no mueve al que agarra; al ser lanzado, levantarse; morir de un disparo estando tirado |
| **5.2** Gorros y 3 ranuras | `obj_hat`, `equip_slot` (cabeza/cuerpo/pies), equipar/intercambiar, gorro que sale al ragdoll y al morir | Tirarse → el gorro cae → levantarse → agarrarlo → se lo pone; con otro puesto, el viejo queda en la mano |
| **5.3** Equipo antibalas | `bullet_block`, `equipment_try_block`, chaleco (cuerpo) y casco (cabeza) en los spawners, rotura con fragmentos | Con chaleco, en ragdoll: el primer disparo rompe el chaleco, el segundo mata |

**Assets 5:** `spr_hats` ya existe (se reusa para `obj_hat`). Nuevos: `spr_vest` (chaleco: en el piso + puesto), `spr_helmet`, `spr_armor_shards`; `obj_vest`, `obj_helmet` (hijos de `obj_holdable`). Sonidos placeholder: `snd_ragdoll_flop`, `snd_hat_pop`, `snd_crawl`, `snd_armor_break`.

---

## 4. FASE 6 — La Casa de los Fans (lobby)

### 4.1 Diseño de la sala (cámara fija, una pantalla 320×180 ampliada)

```
 ┌───────────────────────────────────────────────────────────────┐
 │  ╔═╗ tubo     banderines ▼▼▼▼        foto campeón XIV   ventana │
 │  ║ ║                                                           │
 │  ╚╦╝  (caen aquí)       ┌──────────┐                           │
 │   ▼                     │  TV TCTV │   lámpara                 │
 │ [ROPERO]   [PC host]    │  EN VIVO │                 [nevera]  │
 │                         └──────────┘                           │
 │      ┌─────────────── SOFÁ (8 asientos) ───────────────┐      │
 │ ████████████████████████████████████████████████████████████ │
 └───────────────────────────────────────────────────────────────┘
```

- **Tubo:** por donde llega cada jugador al unirse. Sale escupido **en modo ragdoll** (reutiliza la Fase 5) con un "¡plop!", nube de polvo y el gorro rebotando al lado. Detalle divertido: el jugador tiene que recoger su gorro al llegar.
- **Ropero** (reemplaza a las PCs por jugador): cambia **color y gorro**. Lo pueden usar **varios a la vez** (cada uno ve su propio menú flotando sobre su cabeza). La puerta del ropero se abre y el mapache "entra" mientras elige.
- **PC del host:** como hoy (puntos para ganar, rondas por bloque, máx. jugadores) + opciones nuevas: **"Shows de TV: completo / corto / apagado"** (para partidas rápidas).
- **TV:** muestra el canal en vivo en miniatura (Rocco en el estudio, la cuenta de quién está sentado, publicidad absurda de Trash City). Es **el mismo motor de TV de la Fase 7** dibujado en pequeño — no se duplica nada.
- **Sofá:** 8 asientos. Agarrar cerca de un asiento = **sentarse**; saltar = levantarse. Cuando **todos los jugadores unidos están sentados** y son al menos el mínimo (ver §11), la TV dice "¡Ya empieza!", se apagan las luces de la sala y la cámara hace **zoom hacia la TV** → empieza el show de presentación.
- Con 1–4 jugadores el sofá muestra 4 asientos; con 5–8 se extiende (o aparece un segundo sillón). Esto resuelve los pendientes #1 y #2 (layout de cabinas y cámara del lobby) de otra forma: **ya no hay cabinas**, la cámara es fija y la sala siempre es la misma.

### 4.2 Cambios de código

- **`obj_interactable` multiusuario:** hoy guarda un solo `user` y el estado del menú en el objeto. Se mueve el estado del menú **al jugador** (`player.menu_state`) y el objeto pasa a tener `max_users` (PC host = 1, ropero = 8). Así cualquier interactable futuro (máquina expendedora, botón) sirve para varios.
- **`obj_seat_group`** (sofá) hijo de `obj_interactable` con un array de puntos de asiento. Nuevo estado del jugador `PLAYER_STATE.SEATED` (quieto, sprite sentado, sin gravedad).
- **`obj_lobby_tube`:** escucha `lobby_scan_join` (vía un evento `lobby_on_join`) y crea al jugador en ragdoll con velocidad de salida.
- **`obj_lobby_controller`:** pierde el "ENTER para empezar"; ahora vigila `lobby_all_seated()`.
- `rm_lobby` se rediseña (sigue siendo hija de `rm_level_template`).

### 4.3 Partes

| Parte | Contenido | Prueba de cierre |
|---|---|---|
| **6.1** Interactables multiusuario + ropero *(hecho, falta confirmar; el Draw GUI de la PC estaba vacío y se corrigió)* | refactor de `obj_interactable`, `obj_wardrobe`, quitar las PCs por jugador | 3 jugadores en el ropero a la vez, cada uno cambia lo suyo |
| **6.2** Sala y tubo | layout nuevo, `obj_lobby_tube`, llegada en ragdoll | unirse con teclado y mando: caen por el tubo |
| **6.3** Sofá y arranque | `obj_seat_group`, estado SEATED, condición de inicio, apagar luces + zoom a la TV (por ahora pasa directo a la cuenta regresiva) | todos sentados → zoom → partida |

**Assets 6 (los dibujo yo como PNG, tú creas los assets vacíos):** `spr_lobby_tube`, `spr_wardrobe` (cerrado/abierto), `spr_sofa` (tramos de 2 asientos), `spr_tv_lobby`, `spr_player_sit`, tiles/decoración de la sala (pared, piso, banderines, foto, lámpara, nevera). Sonidos: `snd_tube_whoosh`, `snd_tube_plop`, `snd_sofa_sit`, `snd_lights_off`, `snd_wardrobe_door`.

---

## 5. FASE 7 — Trash TV (el motor de transmisión)

### 5.1 Arquitectura (lo más importante del plan)

Todo show (presentación, entretiempo, final) es **una lista de "beats"** que ejecuta un único director. Nada de código especial por show: los shows son **datos**.

```
 scr_show_data (o datafiles/shows_es.json)       ← QUÉ pasa (datos)
        │  lista de beats
        ▼
 obj_show_director  ── ejecuta 1 beat a la vez ──►  scr_show_beats   ← CÓMO se hace cada tipo
        │                                              say · wait · cut_set · camera · anim
        │                                              highlight · score_event · podium · paper
        ▼                                              vote · call · fade · static
 tv_surface (320×180)  ──►  scr_tv_render  ──► pantalla completa (con marco CRT)
                                            └─► TV del lobby (miniatura)
```

| Pieza | Responsabilidad |
|---|---|
| `scr_show_director` | Cola de beats, avanzar, saltar (skip), terminar y devolver el control a `scr_match` |
| `scr_show_beats` | Un constructor por tipo de beat (`BeatSay`, `BeatWait`, `BeatCut`...), cada uno con `start()`, `step()` → ¿terminó?, `draw()`. Agregar un tipo de beat = un constructor nuevo |
| `scr_dialogue` | Caja de diálogo, efecto máquina de escribir, retrato con boca animada, voz por blips, reemplazo de **tokens** (`{jugador}`, `{apodo}`, `{gorro}`, `{puntos}`) |
| `scr_tv_render` | Dibuja el show en `tv_surface`; aplica el **shader CRT** (`sh_crt`: líneas de barrido, curvatura leve, viñeta, aberración de color), logo del canal, EN VIVO, zócalo con noticias |
| `scr_transitions` | Estática de cambio de canal, encendido/apagado de TV (línea blanca), cortina con el logo del torneo, zoom a la TV del lobby, giro de periódico |
| `scr_match_events` | **Registro de eventos** de la partida (ver 5.3) |
| `scr_highlights` | Captura de **mejores momentos** (ver 5.4) |
| `scr_skip` | Votos de skip y dibujo de las manos (ver 6.5) |

**`scr_match` cambia poco:** `INTERMISSION` y `MATCH_OVER` ya existen; se agrega `MATCH_STATE.SHOW` con `global.match.show = { id, on_finish }`. Cuando un show termina, `on_finish` decide (empezar ronda, volver al lobby...). `match_draw_debug` desaparece.

**Rooms:** una sola **`rm_show`** con los "sets" (estudio, estadio, podio) como **capas** que se muestran u ocultan (`layer_set_visible`). Menos cambios de room = menos carga y transiciones sin cortes. Las animaciones complejas se pueden armar con **Sequences** del IDE (un beat `sequence` las reproduce), así puedes animar cosas visualmente sin tocar código.

**Red (a futuro):** el director corre en el host; los clientes solo reciben "beat N empezó" y los votos de skip viajan como input. Los textos ya generados (con tokens resueltos) se envían, no se recalculan.

### 5.2 Presentación de los competidores (show "intro")

1. Encendido de TV → cortina con el logo del XV Torneo (jingle).
2. Rocco en el escenario del estadio, reflectores: saludo de apertura (variantes).
3. Por cada jugador: **tarjeta de competidor** que entra de lado (mapache con su color y gorro posando, nombre "Jugador N", **apodo generado**, dato inventado: "Comida favorita: cáscara de plátano", "Récord: 3 cajas en la cabeza").
4. Lalo y Gertrudis dan su "predicción" (frase aleatoria).
5. "¡Que empiece el Rumble!" → estática → cuenta regresiva 5-4-3-2-1 del mapa.

### 5.3 Registro de eventos (estadísticas)

`match_event(type, data)` es el **único** punto donde el juego avisa algo notable. Lo escuchan las estadísticas, los mejores momentos y los diálogos.

| Evento | Se emite en | Datos |
|---|---|---|
| `KILL` | `player_die` | asesino (dueño de la bala), víctima, arma, causa (`BULLET`, `CRUSH`, `FALL`) |
| `MULTI_KILL` | derivado (2+ muertes del mismo asesino en ≤ 1,5 s) | asesino, cantidad |
| `FAKE_DEATH_WIN` | fin de ronda | ganador que estuvo en ragdoll en la ronda |
| `SELF_KILL` | caída sin asesino, caja propia | víctima |
| `ROUND_WIN` / `ROUND_DRAW` | `scr_match` | ganador, duración |
| `CLOSE_CALL` | bala que pasa a < 6 px y no mata (opcional) | jugador |

Requisito: la caja guarda `last_thrower` al lanzarse (para atribuir aplastamientos) y la bala ya tiene `owner`.

### 5.4 Mejores momentos (sin un sistema de repeticiones caro)

Una repetición real (grabar todo el estado cada frame y reproducirlo) es cara y frágil. Propongo **clips de fotos** (como un GIF):

- Un **búfer circular** de 12 superficies pequeñas (320×180). Cada 5 frames se copia la vista actual en la siguiente (1 copia cada 5 frames: barato).
- Cuando ocurre un evento con "puntaje de espectáculo" alto (multi-kill > aplastado > ragdoll ganador > kill normal), se **congela**: se copian esos 12 cuadros (los 2 segundos previos) + 6 posteriores a un sprite.
- Máximo **3 clips por bloque**; se borran (`sprite_delete`) al terminar el entretiempo. Memoria: ~3 MB por clip, estable.
- En el entretiempo se muestran en la TV del estudio con **cámara lenta**, un círculo rojo de "telestrador" sobre el jugador, y Lalo/Gertrudis comentando según el tipo de evento.

### 5.5 Show "entretiempo"

1. Estática → **Estudio TCTV**: escritorio con Lalo y Gertrudis.
2. Resumen del bloque (Lalo) + análisis (Gertrudis), elegidos por las estadísticas (quién mató más, quién murió más tonto...).
3. **Mejores momentos**: 1–3 clips con comentarios.
4. "¡Vamos con Rocco en el estadio!" → transición → **Estadio**: Rocco anuncia los puntajes con la **prueba animada** (Fase 8).
5. Vuelta a la acción (o al show final si alguien ganó).

### 5.6 Partes

| Parte | Contenido | Prueba de cierre |
|---|---|---|
| **7.1** TV | `tv_surface`, `sh_crt`, marco, logo, EN VIVO, zócalo; la TV del lobby muestra el canal | se ve "en la tele" en el lobby y en pantalla completa |
| **7.2** Director + diálogos | beats `say/wait/cut/fade`, caja de diálogo, tokens, voces blip, datos de diálogo | una escena de prueba con los 3 personajes hablando |
| **7.3** Skip | votos, manos con cartel, saltar beat/show | 2 jugadores pulsan → se salta |
| **7.4** Presentación | show "intro" completo con tarjetas y apodos | del sofá a la cuenta regresiva pasando por la presentación |
| **7.5** Eventos + mejores momentos + entretiempo | `scr_match_events`, `scr_highlights`, show "entretiempo" (estudio + clips) | jugar un bloque y ver los clips comentados |

**Assets 7:** retratos/sprites de Rocco, Lalo y Gertrudis (reposo + boca 3 frames + gesto), `spr_tv_frame`, `spr_tctv_logo`, `spr_live_badge`, `spr_studio_set` (escritorio, fondo), `spr_stage_set`, `spr_competitor_card`, `spr_telestrator_circle`, `spr_skip_hand` (en blanco, se tiñe con `sh_player_tint`). Sonidos: `snd_tv_on`, `snd_tv_off`, `snd_static`, `snd_jingle_tournament`, `snd_whoosh_card`, `snd_voice_rocco`, `snd_voice_lalo`, `snd_voice_gertrudis`, `snd_crowd_cheer`, `snd_crowd_ooh`, `snd_skip_slap`.

---

## 6. FASE 8 — Estadio y premiación

### 6.1 Ideas de "pruebas" para mostrar el puntaje (en vez de una tabla)

Todas comparten **la misma interfaz**: reciben el puntaje de cada jugador antes y después del bloque y el puntaje para ganar, y animan a cada mapache **uno por uno** (de menor a mayor puntaje, para que haya suspenso). Una **línea de meta** marca el puntaje para ganar. Agregar una prueba nueva = un archivo de datos + su dibujo, sin tocar el director.

| # | Prueba | Cómo representa el puntaje | Por qué encaja |
|---|---|---|---|
| 1 | **Torre de basura** | Cada mapache apila **cajas** (las del juego) — una por punto; la torre se tambalea y el ganador corona con su gorro arriba | Reusa `spr_crate` y su física visual; muy legible |
| 2 | **Carrera de carritos de súper** | El mapache empuja un carrito por una pista; avanza un tramo por punto; la meta es el puntaje para ganar | Lectura instantánea de "quién va primero" |
| 3 | **Concurso de comer pizza del basurero** | Come una rebanada por punto; los platos vacíos se apilan; el último bocado hace eructar al líder | Comedia; los platos funcionan como barra |
| 4 | **Lanzamiento de escoba** (jabalina) | Lanza una escoba; cae más lejos con más puntos; banderita con su color donde cae | Tensión del vuelo; cámara sigue la escoba |
| 5 | **Cohete de botella** | Bombea una botella-cohete; sube más con más puntos; explota en fuegos artificiales de su color al llegar a la meta | Gran final visual |
| 6 | **Tiro al contenedor** | Encesta bolsas en un contenedor desde distancias crecientes; un acierto por punto | Rápido, buen ritmo para 8 jugadores |

**Mi recomendación:** sortear la prueba en cada entretiempo (bag shuffle, como los mapas) y empezar implementando **2**: *Torre de basura* (la más legible) y *Carrera de carritos*. Las demás se agregan cuando quieras, una por parte. En la **final** se usa siempre la más espectacular (*Cohete de botella*) para que se sienta distinta.

Rocco narra durante la prueba: "¡{jugador} suma {n}... y se pone a {faltan} del título!"; el público reacciona (oooh / aplausos).

### 6.2 Podio

- **1.º** al centro, escalón más alto; **2.º** a la derecha, escalón medio; **3.º** a la izquierda, escalón más bajo (como pediste).
- Confeti del color del ganador, el ganador levanta un **trofeo hecho con una lata dorada**, Rocco le pone una **corona de tapa de basurero**.
- **Propuestas para 4.º a 8.º** (elige una o combinamos):
  - **A) Dentro de botes de basura** frente al podio, asomando la cabeza con la tapa en la cabeza, con su número en el bote. *(Mi favorita: muy Trash City, y se ven todos.)*
  - **B) En la tribuna**, primera fila, sosteniendo un cartel "¡El año que viene!" y aplaudiendo (o abucheando).
  - **C) En una banca de "perdedores"** al costado, compartiendo una pizza triste; el último lleva el **gorro de burro**.
  - **D) Mixto:** 4.º y 5.º en una banca con medallas de chapita de lata; 6.º–8.º en botes de basura.
- Empates en el podio comparten escalón (hombro con hombro).

### 6.3 La foto y el periódico

1. Rocco: "¡Una foto para la historia!" → *flash* blanco.
2. La imagen del podio queda **congelada** (se copia la pantalla en un sprite) y se vuelve sepia/blanco y negro con grano.
3. El periódico **entra girando** (transición clásica de diario) y se detiene: **portada de *La Gaceta de Trash City***, con la foto, un titular generado ("¡{GANADOR} CONQUISTA EL XV TORNEO!", "¡{GANADOR} ARRASA: {kills} BAJAS!") y notas al costado con estadísticas reales de la partida ("Récord de la noche: 4 cajas en la cabeza").
4. Se abre la **votación**: cada jugador elige con izquierda/derecha **[Revancha]** o **[Volver a la casa]**; su manito con su color aparece sobre la opción.

### 6.4 Datos de diálogo y shows

- Archivo **`datafiles/tv_es.json`** (Archivos Incluidos del IDE): pools de frases por evento y por personaje, apodos, datos curiosos, titulares, noticias del zócalo.
- Ventaja: se pueden escribir y corregir frases **sin tocar código**, y a futuro traducir (`tv_en.json`).
- Selección de variantes con **bag shuffle** (no repetir frase hasta agotar el pool).

### 6.5 Skip con las manitos

- Cualquier jugador pulsa **saltar** (o toca el borde de la pantalla en celular) → desde el borde (izquierda para jugadores pares, derecha para impares) entra **su manito de mapache, teñida de su color, sosteniendo un cartel "SKIP"**, con un pequeño rebote.
- Pulsar de nuevo la retira (cambiar de opinión).
- Al llegar a la regla elegida (ver §11), **sonido de "¡paf!"** → se salta **la escena actual** (no todo el show: el jugador no se pierde los puntajes por error). Mantener pulsado 1 s salta el show entero.
- Los diálogos además avanzan con un toque (si el texto se está escribiendo, se completa; si ya está completo, pasa al siguiente).

### 6.6 Partes

| Parte | Contenido | Prueba de cierre |
|---|---|---|
| **8.1** Estadio + interfaz de pruebas + *Torre de basura* | set del estadio, `scr_score_events`, primera prueba | entretiempo muestra puntajes como torres |
| **8.2** *Carrera de carritos* (+ las que elijas) | segunda prueba, sorteo | dos entretiempos seguidos muestran pruebas distintas |
| **8.3** Final y podio | show "final", *Cohete de botella*, podio, resto de jugadores | ganar una partida con 4 jugadores y ver el podio |
| **8.4** Periódico y votación | foto, sepia, giro, portada generada, votos | revancha reinicia la partida; "volver" va a la casa con los mismos jugadores |

**Assets 8:** `spr_stadium_set`, `spr_crowd` (multitud animada barata: 2–3 frames por bloque), `spr_podium`, `spr_trash_can_place`, `spr_trophy`, props de las pruebas (carrito, pizza/platos, escoba, botella-cohete, contenedor), `spr_newspaper`, `spr_confetti`. Sonidos: `snd_drumroll`, `snd_fanfare`, `snd_camera_flash`, `snd_paper_spin`, `snd_crowd_applause`, `snd_crowd_boo`, `snd_firework`, y uno por prueba.

---

## 7. Arte y sonido (cómo los voy a producir)

- **Sprites:** los dibujo yo como PNG en `Doc/art/` (como `spr_hats_strip5.png` y `spr_lobby_pc_strip2.png`), en pixel art coherente con los mapaches 32×32. Tú creas los assets vacíos en el IDE y yo lleno las propiedades (orígenes, frames). Los personajes de la TV se dibujan **más grandes** (64×64 de retrato) porque la TV hace de "primer plano".
- **Paleta:** colores clave para teñir (manos, tarjetas, banderas, confeti) con el mismo `sh_player_tint`.
- **Sonidos placeholder:** los genero yo (sin licencias), con la mezcla que ya investigamos en la Parte 8. Las voces de los personajes son **blips** con tono propio (estilo "hablan en su idioma"), que es barato, gracioso y no necesita actores. La música de TV/jingle también placeholder. Todo se reemplaza después sin tocar código (los nombres `snd_*` quedan).

---

## 8. Rendimiento y buenas prácticas (Manual de Optimización)

- **Superficies:** `tv_surface` y el búfer de mejores momentos se crean una vez, se verifican con `surface_exists` cada frame (se pierden al minimizar en celular) y se liberan al salir. Sprites de clips y de la foto: `sprite_delete` al terminar.
- **Sin asignaciones por frame:** los beats se crean al armar el show, no en cada Step. Los textos con tokens se resuelven una vez al empezar el beat.
- **Público y confeti:** sistema de partículas (`part_system`) en vez de instancias; la multitud es un tile animado.
- **Shader CRT:** un solo pase sobre la superficie de 320×180 (barato también en celular); opción para desactivarlo en ajustes.
- **Desacople:** el juego **no sabe** que existe la TV; solo emite eventos. Si se borra la Fase 7, el juego sigue funcionando.

---

## 9. Archivos nuevos y modificados (resumen)

| Nuevo | Fase |
|---|---|
| `scr_player_ragdoll`, `obj_hat`, `scr_equipment` | 5 |
| `obj_wardrobe`, `obj_seat_group`, `obj_lobby_tube`, `obj_lobby_tv` | 6 |
| `obj_show_director`, `scr_show_director`, `scr_show_beats`, `scr_dialogue`, `scr_tv_render`, `scr_transitions`, `scr_match_events`, `scr_highlights`, `scr_skip`, `sh_crt`, `rm_show`, `datafiles/tv_es.json` | 7 |
| `scr_score_events` (pruebas), `scr_podium`, `scr_newspaper`, `scr_vote` | 8 |
| **ADR-004** Equipamiento · **ADR-005** Shows como datos (director de beats) · **ADR-006** Mejores momentos por clips de superficie | 5–7 |

| Modificado | Cambio |
|---|---|
| `scr_corpse` | `corpse_spawn` devuelve la pareja y acepta dueño |
| `scr_player_health` | muerte desde ragdoll, emite `KILL`, tira el gorro |
| `scr_player_state_machine` | estados `RAGDOLL`, `SEATED` |
| `scr_player_input` | `ragdoll_pressed`, `skip` |
| `scr_player_weapon` | rama de equipar en `player_grab_item` |
| `obj_holdable` / `scr_holdable` | bandera `equip_slot`, `owner` en piezas, `last_thrower` |
| `obj_interactable` / `scr_interact` | multiusuario, menú por jugador |
| `scr_match` | estado `SHOW`, adiós a `match_draw_debug` |
| `scr_lobby` | evento al unirse (para el tubo), `lobby_all_seated` |
| `scr_config` | secciones nuevas: RAGDOLL, EQUIPO, LOBBY CASA, TV, SHOW, PREMIACIÓN |

---

## 10. Riesgos

| Riesgo | Mitigación |
|---|---|
| Alcance grande (14 partes) | Cada parte es jugable sola; la TV puede quedar en modo "corto" mientras se completa |
| Arte de muchos personajes | Empezar con retratos simples y animar solo la boca; mejorar al final |
| El ragdoll como "esquiva" rompe el balance | enfriamiento + morir de un disparo estando tirado; se ajusta probando |
| Superficies perdidas en celular | `surface_exists` siempre; los clips se guardan como sprites, no superficies |
| Shows largos aburren | opción del host "completo / corto / apagado" + skip por escena |

---

## 11. Decisiones

### Tomadas (11 nov 2026)
1. **Skip:** hacen falta **todos** los jugadores con el cartel levantado. (Mantener pulsado 1 s para saltar el show entero también exige a todos.)
2. **Mínimo para empezar:** **2 jugadores** sentados (máx. 8). Para probar solo se sigue usando el `keyboard2` TEMPORAL.
3. **Pruebas de puntaje:** se hacen **las seis** (*Torre de basura*, *Carrera de carritos*, *Comer pizza*, *Lanzamiento de escoba*, *Cohete de botella*, + *Tiro al contenedor* si sobra tiempo), sorteadas por bag shuffle. Orden de implementación: Torre → Carritos → Pizza → Escoba → Cohete (el Cohete queda reservado para la final).
4. **Puestos 4.º–8.º:** **botes de basura** frente al podio, asomando la cabeza con la tapa y su número.

### Por defecto (salvo que digas otra cosa)
5. **Votación final:** mayoría; si empata, decide el host.
6. **Ragdoll:** enfriamiento 0,4 s, tecla **X** / botón **Y**.

### Ajustadas (11 nov 2026)
7. **Disparo en ragdoll:** mata, **salvo** que lleve equipamiento que bloquee balas: detiene **1 bala** y se rompe.
8. **Equipamiento en 3 ranuras:** cabeza, cuerpo y pies.
9. **Atrapado:** si alguien te lleva en la mano, saltar **no** te libera; puedes sacudir el ragdoll sin mover al que te agarra. Te levantas cuando te suelta o te lanza.
