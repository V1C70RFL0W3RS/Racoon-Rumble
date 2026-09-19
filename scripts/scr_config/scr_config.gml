/// @description Constantes globales del juego. Único lugar donde viven los "números mágicos".

// --- Física del jugador ---
#macro GRAVITY           0.55
#macro PLAYER_MOVE_SPEED 6
#macro PLAYER_ACCEL      1.5
#macro PLAYER_FRICTION   0.85
#macro PLAYER_JUMP_FORCE -11

// --- Jugadores ---
#macro MAX_PLAYERS 4
enum PLAYER_STATE { IDLE, RUN, JUMP, FALL, SLIDE, HURT, DEAD }