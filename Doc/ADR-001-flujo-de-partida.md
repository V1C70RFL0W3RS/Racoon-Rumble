# ADR-001: Flujo de partida (lobby, rondas, intermission, desempate)

## Estado
Aceptada

## Contexto
El `scr_match` de la Fase 2 fue un boceto provisional (playlist finita → MATCH_OVER)
para poder probar armas y muerte de un golpe cuanto antes. Racoon Rumble necesita un
flujo real inspirado en DuckGame: lobby jugable, partida configurable, rondas contra
puntaje, intermission periódica, y desempate.

## Alternativas consideradas
- **Selección de mapas:** orden fijo (predecible, aburre rápido) vs azar puro (puede
  repetir el mismo mapa varias veces seguidas) vs bag shuffle (baraja el pool, saca sin
  repetir, rebaraja al vaciarse).
- **Posicionamiento al inicio de ronda:** spawn central artificial vs reutilizar el
  sistema de `obj_spawn_point` ya construido en la Fase 1 (múltiples spawns repartidos
  por el mapa).
- **Alcance del lobby:** diseñarlo ya pensando en red vs solo local por ahora.
- **Desempate infinito:** repetir hasta que haya un único ganador vs muerte súbita
  (reducir vida/tiempo) vs co-campeones.

## Decisión
- Selección de mapas: **bag shuffle**.
- Posicionamiento de ronda: **reutilizar `obj_spawn_point`**, barajando la asignación
  jugador→spawn, permitiendo reuso si hay más jugadores que spawns.
- Lobby: **solo local por ahora**; LAN y online quedan como extensión futura de la capa
  de red ya desacoplada desde la Fase 1.
- Desempate: si un desempate vuelve a empatar, **se repite** hasta que haya un único
  ganador.

## Consecuencias
### Positivas
- Bag shuffle da variedad real sin el costo de un sistema de "no repetir" más complejo.
- Reutilizar `obj_spawn_point` evita inventar un sistema de posicionamiento nuevo: cero
  código extra, y el nivel ya se diseña pensando en varios spawns.
- Mantener el lobby local-only mantiene el alcance de esta fase manejable.

### Negativas / trade-offs aceptados
- El desempate infinito, en el peor caso teórico, podría alargar mucho una partida si
  los jugadores empatan por rachas — se acepta el riesgo porque es raro en la práctica
  y evita la complejidad de una regla de muerte súbita.
- Diseñar el lobby sin red en mente significa que, al agregar LAN más adelante, va a
  hacer falta revisar el modelo de "quién juega" (hoy pensado 100% local).