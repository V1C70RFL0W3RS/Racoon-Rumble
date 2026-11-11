# ADR-003: Objetos agarrables (`obj_holdable`) y enlaces entre objetos

## Estado
Aceptada

## Contexto
Hasta la Fase 3 Parte 4, lo único que se podía agarrar, soltar y lanzar era un arma, y todo ese
comportamiento vivía dentro de `obj_weapon`: físicas sueltas (gravedad, rebote, aterrizar de pie o
acostada) mezcladas con lo propio del arma (munición, cadencia, kick). El jugador asumía en varios
sitios que lo que llevaba en la mano era un arma (`.def`, `.kick`, `weapon_draw_held`).

En la Parte 5 apareció el cadáver del jugador, en dos mitades que también se agarran, y ya se sabe que
habrá más: cajas, equipamiento, casquillos. Cada uno tiene físicas distintas (las cajas no giran, el
cadáver decide su ángulo por la dirección entre sus dos piezas, las armas giran con las físicas del
padre) y algunos van **enlazados** (las dos mitades del cadáver deben mantenerse juntas y colgar una de
otra al agarrarlas). Es una decisión que afecta a varios sistemas (jugador, armas, spawners, cámara), es
cara de revertir una vez que haya más tipos, hubo debate real entre alternativas y es probable que se
vuelva a preguntar por qué está hecho así.

## Alternativas consideradas
- **Reusar `obj_weapon` con un arma "falsa" que no dispara.** Es rápido, pero mezcla cosas distintas y
  obliga a repetir el truco con cada objeto nuevo; el cadáver acabaría cargando munición y kick que no usa.
- **Padre `obj_holdable` con hijos (elegida).** Las físicas y el agarre viven una sola vez en el padre;
  cada hijo añade lo suyo con `event_inherited()`. Costó una refactorización inicial (la lista de pasos de
  la Parte 5) pero deja la base lista para cajas y equipamiento.
- **Un método sobrescribible por hijo** (por ejemplo, `draw_held` distinto en cada objeto). Se descartó:
  obligaba a repetir en cada hijo el tratamiento del color y de la escala, y el jugador tenía que conocer
  cada hijo.
- **Enlace entre las dos mitades con un resorte** (rigidez y amortiguación), resuelto en el Step de cada
  pieza. Se implementó primero y se descartó: la segunda pieza veía a la primera ya movida y el error se
  realimentaba hasta el infinito al lanzar (ver bug #3 de la Parte 5).
- **Tres piezas con una articulación invisible**, como Duck Game. Se adaptó a dos cuerpos con una varilla,
  porque el punto de unión ya sale de una tabla y no hacía falta la tercera pieza.

## Decisión
- **`obj_holdable` es el padre de todo lo que se agarra, suelta y lanza.** Contiene el estado común
  (`holder`, velocidades, tilemap, ángulo visual, color de jugador, punto de sujeción) y el Step común
  (gravedad, tope de velocidad, rebotes, aterrizaje, desincrustación).
- **Lo propio de cada tipo se expresa con banderas en el padre**, no con métodos que se sobrescriben:
  `fires` (¿dispara?), `rotates` (¿gira?), `drives_angle` (¿decide su propio ángulo?), `color_index` (¿se
  tiñe?), más los parámetros de físicas `air_friction_mult`, `wall_bounce`, `floor_bounce`. Todo el dibujo
  pasa por `holdable_draw`, y las acciones genéricas (buscar, soltar, desincrustar) viven en `scr_holdable`.
- **Una pareja enlazada se resuelve en un solo lugar, una vez por frame y antes de que se mueva
  ninguna pieza** (Begin Step), con los mismos datos para las dos. Se usa una varilla de longitud fija entre
  los dos cuerpos con el impulso corrector de Duck Game, el ángulo sale de la dirección entre ellos, y la
  pieza que está en una mano es el punto fijo (no se corrige).
- **La posición de un objeto sostenido es su origen**, calculada cada frame desde la mano y su punto de
  sujeción.

## Consecuencias
### Positivas
- Un objeto agarrable nuevo (caja, casco) es un hijo con unas pocas líneas: hereda físicas, agarre, soltar,
  lanzar y dibujo, y se enciende lo que necesite con las banderas.
- El jugador deja de saber qué lleva en la mano; solo le importan `fires` y el punto de sujeción.
- El enlace entre piezas es reutilizable para cualquier pareja de objetos (una bola con cadena, un cuerpo de
  tres piezas), porque no depende del cadáver.
- Los topes de velocidad y la desincrustación viven en el padre, así que ningún hijo puede disparar la
  velocidad ni quedar clavado en el mapa.

### Negativas / trade-offs aceptados
- **Nombres desactualizados:** varias macros `WEAPON_*` y la variable `held_weapon` ya no son solo de armas.
  Hay que renombrarlas a `HOLDABLE_*` y `held_item`; se deja anotado como pendiente de la Parte 5.
- **Un solo ángulo para las dos mitades del cadáver** (varilla rígida): Duck Game deja doblar un poco la
  cintura. Se acepta por simplicidad.
- **El padre crece** con cada bandera nueva (hoy 5). Si llegara a mezclar demasiadas excepciones, habría que
  separar un padre intermedio (por ejemplo, uno para objetos con ángulo propio).
- **Coste por frame:** cada holdable suelto hace una comprobación de colisión contra el mapa para
  desincrustarse. Es barata con el tilemap, pero se debe revisar si algún día hay muchos.
- **Las constantes del cadáver** (distancias, masas, rebote 0.6, recorte de 8 px) vienen de la biblia y no
  se verificaron contra el código fuente real de Duck Game.
