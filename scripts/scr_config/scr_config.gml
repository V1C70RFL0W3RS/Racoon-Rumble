/// @description Constantes globales del juego. Único lugar donde viven los "números mágicos".
/// Organizado por sistema. Al agregar una macro, ponla en su sección (no al final del archivo).

#macro DEBUG_TOOLS true

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
#macro PLAYER_CROUCH_FRICTION_MULT 0.28   // fricción × esto en slide y crouch (0.25 × 0.28 = 0.07)

// --- Feel del salto ---
#macro PLAYER_COYOTE_FRAMES       7
#macro PLAYER_JUMP_BUFFER_FRAMES  4
#macro PLAYER_CORNER_CORRECT_PX   4     // NO es de Duck Game: ayuda extra, se puede quitar

// --- Animación y brazo ---
#macro PLAYER_RUN_ANIM_RATE     0.08    // frames de animación avanzados por cada píxel/step de velocidad
#macro PLAYER_JUMP_START_FRAMES 4       // steps que se muestra la pose de despegue
// Posición del hombro respecto al origin del jugador (pies, centro). Y negativa = hacia arriba.
#macro PLAYER_SHOULDER_X -2
#macro PLAYER_SHOULDER_Y -12
// Distancia del hombro a la mano (donde se agarra el arma), en píxeles.
#macro PLAYER_ARM_LENGTH  9
// --- Brazo al deslizar ---
#macro PLAYER_SLIDE_AIM_DEG    0     // ángulo del brazo y arma al deslizar, relativo a hacia dónde mira: 0 = de frente, + = hacia arriba
#macro PLAYER_ARM_WALL_MARGIN  4      // px extra al probar si el arma toca una pared
#macro PLAYER_ARM_RAISE_SPEED  0.2    // qué tan rápido sube el brazo (0-1 por frame): 0.2 = ~5 frames
#macro PLAYER_SLIDE_ARM_FREE_DEG  0   // ángulo del brazo al deslizar SIN arma, mirando a la derecha (0 = adelante, 90 = arriba, 270 = colgando)
// =============================================================================
// INPUT
// =============================================================================
#macro INPUT_STICK_DEADZONE 0.25   // el stick debe pasar de esto para contar como movimiento

// =============================================================================
// FÍSICA GENERAL (armas y objetos sueltos, NO el jugador)
// =============================================================================
#macro GRAVITY 0.2



// =============================================================================
// Cadáver
// =============================================================================
#macro CORPSE_INERTIA         0.5   // fracción de la velocidad del jugador que heredan (biblia 4.4.5)
#macro CORPSE_POP_SPEED       -2    // saltito hacia arriba al morir
#macro CORPSE_LINK_MIN        10    // distancia mínima entre centros: debajo de esto se empujan (no se encimen)
#macro CORPSE_LINK_MAX        14    // distancia máxima: arriba de esto la cuerda las jala
#macro CORPSE_SPAWN_JOINT_Y   0   // altura del punto de unión sobre los pies al morir (a ojo: la cintura)
#macro CORPSE_SNAP_FACTOR  5     // si las piezas se separan más de 5 veces su distancia, se reencuentran
#macro HOLDABLE_MAX_HSP    12    // tope de velocidad horizontal de todo objeto agarrable (biblia 4.3)
#macro HOLDABLE_MAX_VSP    8     // tope de velocidad vertical


#macro CORPSE_AIR_FRICTION_MULT  0.3    // biblia 4.4.5 E: 70 % menos resistencia al aire
#macro CORPSE_BOUNCE             0.6    // rebota con el 60 % de su velocidad
#macro CORPSE_DRAW_SLACK         2      // px que puede estirarse el dibujo antes de recortarlo
#macro HOLDABLE_BOUNCE_MIN_SPEED 1.5    // por debajo de esto no rebota: se posa
#macro HOLDABLE_MAX_PUSHOUT   32   // máximo que se mueve un holdable incrustado para salir del mapa
#macro CORPSE_SPAWN_PUSHOUT   24   // máximo que se mueve el cadáver entero al nacer
// =============================================================================
// ARMAS
// =============================================================================
// --- Agarrar y soltar ---
#macro HOLDABLE_GRAB_RADIUS     24        // distancia máxima para agarrar un arma
#macro HOLDABLE_OVERLAP_PUSHOUT     96        // máximo de px que se busca un lugar libre si nace solapada

// --- Lanzamiento ---
#macro HOLDABLE_THROW_MIN_SPEED 0.5       // si abs(hsp) supera esto, "se está moviendo" → lanza
#macro HOLDABLE_THROW_SPEED     7.5     // velocidad horizontal ABSOLUTA al lanzar corriendo
#macro HOLDABLE_THROW_LIFT     -2
#macro HOLDABLE_THROW_UP_SPEED  5       // lanzar hacia arriba
#macro HOLDABLE_THROW_SPIN      14        // grados por frame que gira al lanzarla

// --- Soltar quieto ---
#macro HOLDABLE_DROP_SPEED      3         // impulso horizontal al soltarla quieto (suave)
#macro HOLDABLE_DROP_LIFT      -2         // pequeño impulso hacia arriba, para que haga un arco corto
#macro HOLDABLE_DROP_SPIN       3         // giro suave al soltarla quieto

// --- Arma suelta en el mundo ---
#macro HOLDABLE_GROUND_FRICTION 0.25
#macro HOLDABLE_WALL_BOUNCE     0.4       // fracción de velocidad que conserva al rebotar en una pared
#macro HOLDABLE_SETTLE_RATE     0.25      // qué rápido se endereza al aterrizar (0 a 1)
#macro HOLDABLE_AIR_FRICTION    0.175   // 0.25 × 0.7

// --- Retroceso (biblia P8) ---
#macro WEAPON_KICK_LIFT       0.333   // fracción del retroceso que empuja al jugador hacia arriba

// --- Spawners ---
#macro WEAPON_SPAWNER_RESPAWN_FRAMES 300  // frames que espera un punto libre antes de generar otra arma (5 s a 60 fps)
#macro WEAPON_SPAWNER_CHECK_RADIUS   20   // px: si el arma se aleja más que esto, el punto cuenta como libre
/// Opción "arma al azar, decidida una sola vez por ronda" (weapon_choice del spawner).
#macro WEAPON_CHOICE_RANDOM_LOCKED "Aleatoria fija"

// =============================================================================
// PARTIDA (rondas, lobby, intermission)
// =============================================================================
#macro LOBBY_JOIN_KEY            vk_space
#macro MATCH_COUNTDOWN_SECONDS   5
#macro MATCH_ROUND_END_FRAMES    150    // pausa tras terminar la ronda (2.5 s a 60 FPS)
#macro MATCH_INTERMISSION_FRAMES 300    // 5 s a 60 FPS, mostrando puntajes
#macro MAP_NAME_PREFIX           "rm_map_" // toda room con este prefijo entra al pool de mapas

// TEMPORAL: valores por defecto hasta que exista la UI de ajustes del lobby (Paso 4).
#macro MATCH_DEFAULT_SCORE_TO_WIN     3
#macro MATCH_DEFAULT_ROUNDS_PER_BLOCK 3

// TEMPORAL: segundo teclado de testeo, para probar multijugador sin mando físico.
#macro LOBBY_JOIN_KEY_TEST vk_shift

// =============================================================================
// CÁMARA
// =============================================================================
#macro CAMERA_ASPECT         (CAMERA_VIEW_W / CAMERA_VIEW_H)   // 16:9: el ancho siempre sale de la altura
#macro CAMERA_MIN_HEIGHT     60      // alto mínimo de la vista = zoom máximo (biblia: minSize)
#macro CAMERA_TOP_MARGIN     64      // px que la cámara puede mostrar sobre el techo de la room
#macro CAMERA_BORDER_MIN     60      // borde mínimo alrededor de los jugadores
#macro CAMERA_BORDER_MAX     90      // borde máximo (se alcanza con la vista ancha)
#macro CAMERA_BORDER_REF_W   740     // ancho de vista con el que el borde llega a su máximo
#macro CAMERA_VIEW_W 320
#macro CAMERA_VIEW_H 180
#macro CAMERA_POS_LERP       0.05    // biblia: 0.05 para posición y tamaño
#macro CAMERA_ZOOM_LERP      0.05
#macro ROOM_FALL_KILL_MARGIN 64         // px bajo el borde inferior de la room donde el jugador muere
#macro CAMERA_SNAP_DIST      0.5    // si el tamaño de la vista está a menos de esto del objetivo, se fija exacto
#macro CAMERA_HARD_MARGIN    24      // NO es de Duck Game: garantía extra, ver más abajo

// Resolución de dibujo interna (application surface). Múltiplo entero de la vista base 320x180:
// 1920x1080 = 6x, 1280x720 = 4x. Más alta = zoom más parejo, pero más trabajo para la GPU
// (en celulares conviene probar 1280x720).
#macro CAMERA_RENDER_W 1920
#macro CAMERA_RENDER_H 1080

