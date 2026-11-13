# ADR-004: Equipamiento (gorros, cascos, chalecos, botas)

## Estado
Aceptada (Fase 5, Parte 2)

## Contexto
Hasta la Fase 4 el gorro era solo un número (`hat_index` en `players_joined`) que el jugador dibujaba
sobre la cabeza. La Fase 5 pide que el gorro **se caiga** (al tirarse en ragdoll y al morir), que se pueda
**agarrar y volver a poner**, robar el de otro, y que haya **tres ranuras** (cabeza, cuerpo, pies) para
equipamiento futuro que **bloquea balas** (chaleco y casco, Parte 5.3). Afecta al jugador, a los objetos
agarrables, a las balas y a la red futura, y es caro de cambiar cuando haya varios tipos de equipo.

## Alternativas consideradas
- **Lo puesto sigue siendo una instancia** (`holder = jugador`, invisible). Reusa todo `obj_holdable`, pero
  cada sistema que recorre holdables (balas, plataformas, buscar agarrable, destruir) tendría que saber
  ignorarla, y `holdable_destroy` limpiaría por error `held_item`.
- **Un objeto aparte por ranura** (`obj_equipment`). Duplicaría físicas, agarre y dibujo que ya están en
  `obj_holdable` (va contra ADR-003).
- **Puesto = ficha de datos; suelto = holdable (elegida).**

## Decisión
- Todo lo equipable es un **hijo de `obj_holdable`** con la bandera `equip_slot` (`EQUIP_SLOT.HEAD/BODY/FEET`;
  `EQUIP_NONE` para lo demás). Suelto se comporta como cualquier holdable.
- Lo equipable **se agarra como cualquier objeto** (a la mano: se puede lanzar) y **el botón de disparar
  se lo pone** (`player_equip_held`). Si esa ranura ya tenía algo, lo de antes pasa a la mano.
  *(Primera versión: agarrar lo ponía al instante; el usuario prefirió poder llevarlo y lanzarlo.)*
- La cabeza tiene su **propia tabla por pose** (`player_head_table_init`: posición y ángulo), porque en el
  slide el mapache va acostado y la coronilla apunta hacia atrás; el hombro no alcanza para eso.
- **Puesto, deja de ser instancia**: se guarda una **ficha** `{ obj, sprite, frame, slot }` en
  `player.equipped[slot]`. Al caerse, `equip_spawn` la vuelve instancia (ÚNICO lugar).
- El jugador empieza cada ronda con el gorro elegido en el lobby (`player_equip_lobby_hat`).
- Al tirarse en ragdoll se cae **solo el gorro**; al morir, **todo**.
- La posición de cada ranura sale del hombro (que ya sigue el rebote de cada frame) o de los pies.

## Consecuencias
### Positivas
- Ningún sistema tiene que ignorar instancias "puestas": balas, plataformas y agarre no cambian.
- La ficha es lo que viajará por la red (datos simples, sin ids de instancia).
- Un equipo nuevo = un hijo de `obj_holdable` con `equip_slot` + su sprite. La Parte 5.3 suma a la ficha
  cuántas balas bloquea.

### Negativas / trade-offs aceptados
- Lo que no está en la ficha **se pierde** al ponérselo y volver a caer (hoy: nada; mañana, por ejemplo, el
  daño de un casco tendría que ir en la ficha).
- Robar un gorro dura solo la ronda: al empezar la siguiente cada uno vuelve a su gorro del lobby.
- `player_index` ahora se pasa en el struct de `instance_create_layer` para que exista en el Create.

## Actualización — Parte 5.3 (casco, chaleco, botas)
- **Zonas**: el casco protege **solo la cabeza** (una bala que pasa a `PLAYER_HEAD_ZONE_RADIUS` del centro de
  la cabeza, que sale de la tabla de poses, así funciona también en el slide); el chaleco (peto) protege
  **todo lo demás**. Una caja o un pisotón en la cabeza (`HIT_ZONE.TOP`) solo lo detiene el casco. En ragdoll
  el casco ya se cayó: toda bala al cuerpo es `BODY`.
- **Campos de la ficha en UNA tabla** (`equip_fields()`: `bullet_block`, `break_cols`, `stomps`, `spike_proof`,
  `worn_tint`). La usan `obj_holdable` (Create), `equip_spec_make`, `equip_spec_from` y `equip_spawn`: agregar
  una propiedad a todo el equipamiento es una línea.
- **Botas** (`obj_boots`, pies): pisar una cabeza cayendo la mata (`player_try_stomp`) y se puede caminar sobre
  pinchos (`obj_spikes`, `player_check_spikes`). Puestas se dibujan con **`spr_boots_worn`: un frame dibujado
  por cada frame del cuerpo** (correr 0-5, saltar 6-8, agachado 9, slide 10; mismo tamaño y origen que el
  cuerpo) y `spr_boots_worn_corpse` para la pieza inferior del ragdoll (`equip_draw_feet`, `feet_frame_base`).
  *(Primera versión: pintaba la región de los pies de un color plano; el usuario pidió botas dibujadas.)* En ragdoll, el cuerpo tirado sobre pinchos se pincha igual.
- **El casco no se rompe con lo que cae desde arriba** (caja, pisotón): se **abolla** (`dent_frame`, frame 1
  de `spr_helmet`) y lo sigue aguantando. Solo una bala lo rompe.
