// Tubo por donde LLEGAN los jugadores al lobby: los escupe en ragdoll, de a uno (ver scr_lobby,
// LLEGADA POR EL TUBO). El origen es la boca; escupe hacia image_xscale (1 = derecha; espejarlo en
// el editor de rooms para que escupa a la izquierda). El caño sube solo hasta el techo (Draw).
queue = [];   // player_index que esperan su turno para salir
timer = 0;    // frames hasta poder escupir al siguiente
