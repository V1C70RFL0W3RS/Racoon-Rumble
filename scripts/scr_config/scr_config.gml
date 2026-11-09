/// @description Constantes globales del juego. Único lugar donde viven los "números mágicos".
/// Organizado por sistema. Al agregar una macro, ponla en su sección (no al final del archivo).

// Activa los afinadores y la depuración temporal (hombro, cadáver). Poner en false para publicar.
#macro DEBUG_TOOLS true
#macro Release:DEBUG_TOOLS false
#macro DEBUG_DOT_HALF 1   // puntos de depuración: cuadro de (2 × esto + 1) px; 1 = 3x3, 2 = 5x5

// =============================================================================
// JUGADORES
// =============================================================================
#macro MAX_PLAYERS 4
#macro PLAYER_MAX_HP 1                  // 1 = un golpe mata (pilar de diseño)
enum PLAYER_STATE { IDLE, RUN, JUMP, FALL, CROUCH, SLIDE, HURT, DEAD }

// --- Movimiento horizontal (Duck Game, biblia 4.3 y 4.3.1) ---
#macro PLAYER_MOVE_SPEED  3.1
#macro PLAYER_ACCEL       0.55     // igual en suelo y aire
#macro PLAYER_FRICTION    0.25     // igual en suelo y aire, se aplica CADA frame

// --- Salto, gravedad y flap ---
#macro PLAYER_GRAVITY         0.2
#macro PLAYER_JUMP_FORCE     -4.9
#macro PLAYER_JUMP_CUT_MULT   0.5
#macro PLAYER_MAX_FALL_SPEED  8
#macro PLAYER_FLAP_MAX_FALL   1
#macro PLAYER_FLAP_LIFT       0.15

// --- Agacharse y deslizarse (biblia 4.4.2) ---
#macro PLAYER_SLIDE_MIN_SPEED      1.0    // velocidad mínima para que "abajo" inicie un slide
#macro PLAYER_SLIDE_STOP_SPEED     0.3    // por debajo de esto el slide se considera detenido y pasa a agachado
#macro PLAYER_CROUCH_FRICTION_MULT 0.28   // fricción × esto en slide y crouch (0.25 × 0.28 = 0.07)

// --- Feel del salto ---
#macro PLAYER_COYOTE_FRAMES       7
#macro PLAYER_JUMP_BUFFER_FRAMES  4
#macro PLAYER_CORNER_CORRECT_PX   4     // NO es de Duck Game: ayuda extra, se puede quitar

// --- Animación ---
#macro PLAYER_RUN_ANIM_RATE     0.08    // frames de animación avanzados por cada píxel/step de velocidad
#macro PLAYER_JUMP_START_FRAMES 4       // steps que se muestra la pose de despegue

// --- Brazo ---
// Posición del hombro respecto al origin del jugador (pies, centro). Y negativa = hacia arriba.
#macro PLAYER_SHOULDER_X -2
#macro PLAYER_SHOULDER_Y -12
#macro PLAYER_ARM_LENGTH  4             // distancia del hombro a la mano (donde se agarra), en px. Antes 9; el sprite del brazo mide ~6 px
#macro PLAYER_HAND_OFFSET -1             // desvío de la mano perpendicular al brazo, en px: + = más abajo, - = más arriba (con el brazo al frente)
#macro PLAYER_ARM_WALL_MARGIN  4        // px extra al probar si lo sostenido toca una pared
#macro PLAYER_ARM_RAISE_SPEED  0.2      // qué tan rápido sube el brazo (0-1 por frame): 0.2 = ~5 frames

// --- Brazo al deslizar ---
#macro PLAYER_SLIDE_AIM_DEG       0     // ángulo del brazo CON arma al deslizar, relativo a hacia dónde mira (0 = de frente, + = arriba)
#macro PLAYER_SLIDE_ARM_FREE_DEG  0     // ángulo del brazo SIN arma al deslizar, mirando a la derecha (0 = adelante, 90 = arriba, 270 = colgando)

// =============================================================================
// INPUT
// =============================================================================
#macro INPUT_STICK_DEADZONE 0.25   // el stick debe pasar de esto para contar como movimiento

// =============================================================================
// OBJETOS AGARRABLES (todo lo que hereda de obj_holdable: armas, piezas de cadáver...)
// =============================================================================
// --- Físicas sueltos en el mundo ---
#macro HOLDABLE_GRAVITY           0.2     // igual que la del jugador (biblia P10)
#macro HOLDABLE_MAX_HSP           12      // tope de velocidad horizontal (biblia 4.3)
#macro HOLDABLE_MAX_VSP           8       // tope de velocidad vertical
#macro HOLDABLE_GROUND_FRICTION   0.25    // fricción en el suelo
#macro HOLDABLE_AIR_FRICTION      0.175   // fricción en el aire (0.25 × 0.7)
#macro HOLDABLE_WALL_BOUNCE       0.4     // fracción de velocidad que conserva al rebotar en una pared
#macro HOLDABLE_BOUNCE_MIN_SPEED  1.5     // por debajo de esto no rebota: se posa
#macro HOLDABLE_SETTLE_RATE       0.25    // qué rápido se endereza al aterrizar (0 a 1)

// --- Desincrustar y colocar ---
#macro HOLDABLE_MAX_PUSHOUT       32      // máximo que se mueve un holdable ya incrustado para salir del mapa
#macro HOLDABLE_OVERLAP_PUSHOUT   96      // máximo de px que se busca un lugar libre si nace solapado

// --- Agarrar ---
#macro HOLDABLE_GRAB_RADIUS       24      // distancia máxima para agarrar

// --- Lanzar (en movimiento o hacia arriba) ---
#macro HOLDABLE_THROW_MIN_SPEED   0.5     // si abs(hsp) supera esto, "se está moviendo" → lanza
#macro HOLDABLE_THROW_SPEED       7.5     // velocidad horizontal ABSOLUTA al lanzar corriendo
#macro HOLDABLE_THROW_LIFT       -2       // impulso vertical al lanzar
#macro HOLDABLE_THROW_UP_SPEED    5       // velocidad al lanzar hacia arriba
#macro HOLDABLE_THROW_SPIN        14      // grados por frame que gira al lanzarlo

// --- Soltar quieto ---
#macro HOLDABLE_DROP_SPEED        3       // impulso horizontal al soltarlo quieto (suave)
#macro HOLDABLE_DROP_LIFT        -2       // pequeño impulso hacia arriba, para un arco corto
#macro HOLDABLE_DROP_SPIN         3       // giro suave al soltarlo quieto

// =============================================================================
// ARMAS (lo que solo aplica a quien dispara)
// =============================================================================
// --- Retroceso (biblia P8) ---
#macro WEAPON_KICK_LIFT 0.333   // fracción del retroceso que empuja al jugador hacia arriba

// --- Disparo vacío (clic sin balas) ---
#macro WEAPON_DRY_FIRE_DELAY   18    // frames entre clics vacíos (también si es automática y se mantiene el botón)
#macro WEAPON_DRY_KICK         4     // grados que tironea el arma en cada clic vacío
#macro WEAPON_DRY_FLASH_FRAMES 5     // frames que se ve el destello gris en la boca del cañón

// --- Arma vacía: desaparece al quedar quieta (como Duck Game) ---
#macro WEAPON_EMPTY_DESPAWN_DELAY 60   // frames quieta en el piso, vacía y sin dueño, antes de empezar a desvanecerse
#macro WEAPON_DESPAWN_FADE_FRAMES 20   // frames del desvanecido; al terminar sale humo y se destruye
#macro FX_SMOKE_COUNT 8                 // partículas por bocanada de humo (fx_smoke_puff)
#macro FX_SPARK_COUNT 6                 // chispas por bala que choca con una pared
#macro FX_SPARK_SPREAD 55               // ± grados del abanico de chispas (alrededor del rebote)
// --- Humo del cañón (calor del arma) ---
#macro WEAPON_HEAT_DECAY   0.004  // calor (0 a 1) que pierde el arma por frame
#macro WEAPON_SMOKE_DELAY  10     // frames sin disparar antes de que empiece a humear
#macro WEAPON_SMOKE_MIN    0.05   // por debajo de este calor ya no humea
#macro WEAPON_SMOKE_RATE   0.35   // probabilidad por frame de soltar humo con el calor al máximo

// --- Casquillos (obj_fx_shells) ---
#macro SHELL_MAX         60     // tope en pantalla; al pasarlo se borra el más viejo
#macro SHELL_LIFE        600    // frames que dura cada casquillo (10 s a 60 fps)
#macro SHELL_FADE        60     // últimos frames en los que se desvanece
#macro SHELL_GRAVITY     0.2
#macro SHELL_MAX_FALL    6
#macro SHELL_BOUNCE      0.45   // fracción de velocidad que conserva al rebotar
#macro SHELL_REST_SPEED  1.0    // si cae más lento que esto, se queda acostado en el piso
#macro SHELL_FRICTION    0.6    // velocidad horizontal que conserva en cada rebote contra el piso
#macro SHELL_COL_BRASS   make_colour_rgb(214, 170, 60)   // latón (pistola, SMG)
#macro SHELL_COL_RED     make_colour_rgb(178, 40, 40)    // cartucho de escopeta
#macro FX_MUZZLE_SPREAD 25              // ± grados del cono del fogonazo
#macro PROJECTILE_CONTACT_SEARCH 12     // px máximos que se busca el punto de impacto delante de la bala (mayor que media máscara)

// --- Puntitos de munición (accesibilidad, ver global.settings.show_ammo_pips) ---
#macro AMMO_PIPS_SHOW_FRAMES 90   // frames visibles tras disparar o agarrar (1.5 s a 60 fps)
#macro AMMO_PIPS_FADE_FRAMES 20   // últimos frames en los que se desvanecen
#macro AMMO_PIPS_PER_ROW     10   // puntitos por fila (la SMG de 30 ocupa 3 filas)
#macro AMMO_PIPS_SIZE        2    // lado de cada puntito, en px
#macro AMMO_PIPS_GAP         1    // separación entre puntitos, en px
#macro AMMO_PIPS_MARGIN_Y    3    // px entre la cabeza y la fila de abajo

// --- Spawners ---
#macro WEAPON_SPAWNER_RESPAWN_FRAMES 300   // frames que espera un punto libre antes de generar otra arma (5 s a 60 fps)
#macro WEAPON_SPAWNER_CHECK_RADIUS   20    // px: si el arma se aleja más que esto, el punto cuenta como libre
/// Opción "arma al azar, decidida una sola vez por ronda" (weapon_choice del spawner).
#macro WEAPON_CHOICE_RANDOM_LOCKED "Aleatoria fija"

// =============================================================================
// CADÁVER
// =============================================================================
#macro CORPSE_INERTIA            0.5    // fracción de la velocidad del jugador que heredan (biblia 4.4.5)
#macro CORPSE_POP_SPEED         -2      // saltito hacia arriba al morir
#macro CORPSE_SPAWN_JOINT_Y      0      // altura del punto de unión sobre los pies al morir (a ojo: la cintura)
#macro CORPSE_SPAWN_PUSHOUT      24     // máximo que se mueve el cadáver entero al nacer
#macro CORPSE_SNAP_FACTOR        5      // si las piezas se separan más de 5 veces su distancia, se reencuentran
#macro CORPSE_AIR_FRICTION_MULT  0.3    // biblia 4.4.5 E: 70 % menos resistencia al aire
#macro CORPSE_BOUNCE             0.6    // rebota con el 60 % de su velocidad
#macro CORPSE_DRAW_SLACK         2      // px que puede estirarse el dibujo antes de recortarlo
#macro CORPSE_IMPACT_MULT        1      // cuánto lo mueve una bala (× AmmoDef.impact)
#macro CORPSE_BLOCK_CHANCE       0.5    // probabilidad de que CADA pieza detenga una bala (las dos juntas: 75 %)

// =============================================================================
// PARTIDA (rondas, lobby, intermission)
// =============================================================================
#macro LOBBY_JOIN_KEY            vk_space
#macro MATCH_COUNTDOWN_SECONDS   5
#macro MATCH_ROUND_END_FRAMES    150    // pausa tras terminar la ronda (2.5 s a 60 FPS)
#macro MATCH_INTERMISSION_FRAMES 300    // 5 s a 60 FPS, mostrando puntajes
#macro MAP_NAME_PREFIX           "rm_map_" // toda room con este prefijo entra al pool de mapas

// TEMPORAL: valores por defecto hasta que exista la UI de ajustes del lobby (Fase E).
#macro MATCH_DEFAULT_SCORE_TO_WIN     3
#macro MATCH_DEFAULT_ROUNDS_PER_BLOCK 3

// TEMPORAL: segundo teclado de testeo, para probar multijugador sin mando físico.
#macro LOBBY_JOIN_KEY_TEST vk_shift

// =============================================================================
// CÁMARA
// =============================================================================
// --- Vista base (todo valor de física y arte se piensa para esta escala; ADR-002) ---
#macro CAMERA_VIEW_W         320
#macro CAMERA_VIEW_H         180
#macro CAMERA_ASPECT         (CAMERA_VIEW_W / CAMERA_VIEW_H)   // 16:9: el ancho siempre sale de la altura

// --- Zoom y bordes (biblia 11.6) ---
#macro CAMERA_MIN_HEIGHT     60      // alto mínimo de la vista = zoom máximo (biblia: minSize)
#macro CAMERA_TOP_MARGIN     0      // px que la cámara puede mostrar sobre el techo de la room
#macro CAMERA_BORDER_MIN     60      // borde mínimo alrededor de los jugadores
#macro CAMERA_BORDER_MAX     90      // borde máximo (se alcanza con la vista ancha)
#macro CAMERA_BORDER_REF_W   740     // ancho de vista con el que el borde llega a su máximo

// --- Movimiento ---
#macro CAMERA_POS_LERP       0.05    // biblia: 0.05 para posición y tamaño
#macro CAMERA_ZOOM_LERP      0.05
#macro CAMERA_SNAP_DIST      0.5     // si el tamaño de la vista está a menos de esto del objetivo, se fija exacto
#macro CAMERA_HARD_MARGIN    24      // NO es de Duck Game: garantía extra para que nadie salga de la vista (bloque borrable en el Step de obj_camera_controller)
#macro ROOM_FALL_KILL_MARGIN 64      // px bajo el borde inferior de la room donde el jugador muere

// --- Resolución de dibujo interna (application surface) ---
// Múltiplo entero de la vista base 320x180: 1920x1080 = 6x, 1280x720 = 4x. Más alta = zoom más
// parejo, pero más trabajo para la GPU (en celulares conviene probar 1280x720).
#macro CAMERA_RENDER_W 1920
#macro CAMERA_RENDER_H 1080