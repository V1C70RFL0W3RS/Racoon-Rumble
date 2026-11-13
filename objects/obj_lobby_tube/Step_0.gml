// De a uno, con una pausa entre cada jugador (si salen juntos se enredan en la boca).
if (timer > 0) { timer--; exit; }
if (array_length(queue) == 0) exit;
lobby_tube_launch(id, array_shift(queue));
timer = LOBBY_TUBE_INTERVAL;
