/// @description Constantes globales del juego. Único lugar donde viven los "números mágicos".

// --- Física del jugador ---
#macro GRAVITY           0.55
#macro PLAYER_MOVE_SPEED 6
#macro PLAYER_ACCEL      1.5
#macro PLAYER_FRICTION   0.85
#macro PLAYER_JUMP_FORCE -11
#macro WEAPON_GROUND_FRICTION 0.3  // cuánto frena por frame al deslizar en el piso
#macro WEAPON_WALL_BOUNCE     0.4  // fracción de velocidad que conserva al rebotar en una pared
#macro WEAPON_GRAB_RADIUS      24   // distancia máxima para agarrar un arma
#macro WEAPON_THROW_MIN_SPEED  0.5  // si abs(hsp) supera esto, "se está moviendo" → lanza
#macro WEAPON_THROW_SPEED      9    // impulso horizontal extra del lanzamiento
#macro WEAPON_THROW_LIFT      -3    // impulso vertical del lanzamiento (arco hacia arriba)
#macro HAND_OFFSET_X  8    // qué tan adelante del centro queda la mano
#macro HAND_OFFSET_Y -18   // altura de la mano; negativo = por encima de los pies (origin Bottom Center)
#macro WEAPON_THROW_UP_SPEED  9     // velocidad al lanzar hacia arriba
#macro WEAPON_THROW_SPIN      14    // grados por frame que gira al lanzarla
#macro WEAPON_DROP_SPIN       3     // giro suave al soltarla quieto
#macro WEAPON_SETTLE_RATE     0.25  // qué rápido se endereza al aterrizar (0 a 1)
#macro WEAPON_DROP_SPEED  3    // impulso horizontal al soltarla quieto (suave)
#macro WEAPON_DROP_LIFT  -2    // pequeño impulso hacia arriba, para que haga un arco corto
#macro WEAPON_MAX_PUSHOUT  96   // máximo de px que se busca un lugar libre si nace solapada
#macro PLAYER_MAX_HP           1     // 1 = un golpe mata (pilar de diseño)
#macro MATCH_ROUND_END_FRAMES  150   // pausa tras terminar la ronda (2.5 s a 60 FPS)
#macro LOBBY_JOIN_KEY vk_space
#macro MATCH_COUNTDOWN_SECONDS 5
#macro MATCH_INTERMISSION_FRAMES 300 // 5 s a 60 FPS, mostrando puntajes

// TEMPORAL: valores por defecto hasta que exista la UI de ajustes del lobby (Paso 4).
#macro MATCH_DEFAULT_SCORE_TO_WIN     3
#macro MATCH_DEFAULT_ROUNDS_PER_BLOCK 3

// TEMPORAL: segundo teclado de testeo, para probar multijugador sin mando físico.
#macro LOBBY_JOIN_KEY_TEST vk_shift

// --- Jugadores ---
#macro MAX_PLAYERS 4
enum PLAYER_STATE { IDLE, RUN, JUMP, FALL, SLIDE, HURT, DEAD }

// Spawners de armas
#macro WEAPON_SPAWNER_RESPAWN_FRAMES 300   // frames que espera un punto libre antes de generar otra arma (5 s a 60 fps)
#macro WEAPON_SPAWNER_CHECK_RADIUS   20    // px: si el arma se aleja más que esto, el punto cuenta como libre
/// Opción "arma al azar, decidida una sola vez por ronda" (weapon_choice del spawner).
#macro WEAPON_CHOICE_RANDOM_LOCKED "Aleatoria fija"

// Cámara dinámica
#macro CAMERA_VIEW_W        640   // resolución nativa: nunca hace zoom-in más allá de esto
#macro CAMERA_VIEW_H        360
#macro CAMERA_MAX_ZOOM_OUT  2     // hasta el doble de alejada (1280x720) antes de topar
#macro CAMERA_PADDING_X     64    // margen en px de mundo alrededor de los jugadores vivos
#macro CAMERA_PADDING_Y     64
#macro CAMERA_POS_LERP      0.1   // qué tan rápido sigue la posición (0-1, más alto = más rápido)
#macro CAMERA_ZOOM_LERP     0.05  // el zoom se mueve más despacio que la posición, se siente menos brusco
#macro ROOM_FALL_KILL_MARGIN 64

#macro MAP_NAME_PREFIX "rm_map_"   // toda room que empiece así se considera un mapa jugable