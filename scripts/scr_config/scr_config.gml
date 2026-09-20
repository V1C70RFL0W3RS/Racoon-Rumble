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

// --- Jugadores ---
#macro MAX_PLAYERS 4
enum PLAYER_STATE { IDLE, RUN, JUMP, FALL, SLIDE, HURT, DEAD }