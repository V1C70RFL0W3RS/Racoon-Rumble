/// @file scr_match
/// Flujo de la partida: rondas, mapas y puntaje. Todo el estado vive en
/// global.match, dentro del obj_game_manager (persistente).

enum MATCH_STATE { PLAYING, ROUND_OVER, MATCH_OVER }

/// @desc Empieza (o reinicia) una partida completa desde el primer mapa.
function match_start() {
    global.match = {
        state:     MATCH_STATE.PLAYING,
        scores:    array_create(MAX_PLAYERS, 0),
        // ÚNICO lugar donde se define el orden de los mapas.
        maps:      [rm_sandbox, rm_sandbox_2],
        map_index: 0,
        timer:     0,
        winner:    -1     // índice del ganador de la última ronda (-1 = empate)
    };
    room_goto(global.match.maps[0]);
}

/// @desc Actualiza el flujo de la partida. Se llama cada frame desde obj_game_manager.
function match_update() {
    var _m = global.match;

    switch (_m.state) {
        case MATCH_STATE.PLAYING:
            // Sin jugadores en la room (ej. rm_boot) no hay ronda que evaluar.
            if (instance_number(obj_player) == 0) break;

            var _alive = 0;
            var _last  = -1;
            with (obj_player) {
                if (state != PLAYER_STATE.DEAD) { _alive++; _last = player_index; }
            }

            if (_alive <= 1) {
                _m.winner = (_alive == 1) ? _last : -1;   // 0 vivos = empate
                if (_m.winner >= 0) _m.scores[_m.winner]++;
                _m.state = MATCH_STATE.ROUND_OVER;
                _m.timer = MATCH_ROUND_END_FRAMES;
            }
        break;

        case MATCH_STATE.ROUND_OVER:
            if (--_m.timer > 0) break;

            _m.map_index++;
            if (_m.map_index >= array_length(_m.maps)) {
                _m.state = MATCH_STATE.MATCH_OVER;         // era el último mapa
            } else {
                _m.state = MATCH_STATE.PLAYING;
                room_goto(_m.maps[_m.map_index]);
            }
        break;

        case MATCH_STATE.MATCH_OVER:
            // Cualquier jugador puede reiniciar con su botón de salto.
            for (var _i = 0; _i < MAX_PLAYERS; _i++) {
                if (get_player_input(_i).jump_pressed) { match_start(); break; }
            }
        break;
    }
}

/// @desc TEMPORAL: mensajes de texto simples. Se reemplaza cuando exista la UI real.
function match_draw_debug() {
    var _m = global.match;
    var _cx = display_get_gui_width() * 0.5;

    draw_set_halign(fa_center);
    if (_m.state == MATCH_STATE.ROUND_OVER) {
        draw_text(_cx, 40, (_m.winner >= 0) ? "Gana J" + string(_m.winner + 1) : "Empate");
    } else if (_m.state == MATCH_STATE.MATCH_OVER) {
        draw_text(_cx, 40, "PUNTAJE FINAL");
        for (var _i = 0; _i < MAX_PLAYERS; _i++) {
            draw_text(_cx, 80 + _i * 24, "J" + string(_i + 1) + ": " + string(_m.scores[_i]));
        }
        draw_text(_cx, 80 + MAX_PLAYERS * 24 + 16, "Salto para reiniciar");
    }
    draw_set_halign(fa_left);
}