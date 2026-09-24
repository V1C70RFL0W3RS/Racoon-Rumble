/// @file scr_match
/// Flujo de la partida: rondas, mapas y puntaje. Todo el estado vive en
/// global.match, dentro del obj_game_manager (persistente).

enum MATCH_STATE {
    LOBBY,
    COUNTDOWN,
    PLAYING,
    ROUND_OVER,
    INTERMISSION,
    MATCH_OVER
    // DECISIÓN: no hay estado TIEBREAK propio. Un desempate es una ronda normal
    // (mismo COUNTDOWN/PLAYING/ROUND_OVER); lo único distinto es quién participa
    // (round_participants) y qué hace ROUND_OVER después (is_tiebreak). Evita
    // duplicar la lógica de cuenta regresiva + partida para un caso que es
    // idéntico salvo por eso.
}

/// @desc Empieza (o reinicia) la partida: primer mapa, con cuenta regresiva.
function match_start() {
    global.match.is_tiebreak = false;
    global.match.round_participants = match_all_participants();
    global.match.map_bag = [];
    match_begin_round();
}
/// @desc Actualiza el flujo de la partida. Se llama cada frame desde obj_game_manager.
function match_update() {
    var _m = global.match;

    switch (_m.state) {
		
		case MATCH_STATE.COUNTDOWN:
		    if (--_m.timer <= 0) {
		        _m.state = MATCH_STATE.PLAYING;
		    }
		break;
		
		case MATCH_STATE.PLAYING:
		    if (instance_number(obj_player) == 0) break;

		    var _alive = 0;
		    var _last  = -1;
		    with (obj_player) {
		        if (state != PLAYER_STATE.DEAD) { _alive++; _last = player_index; }
		    }

		    if (_alive <= 1) {
		        _m.winner = (_alive == 1) ? _last : -1;
		        if (_m.winner >= 0 && !_m.is_tiebreak) _m.scores[_m.winner]++;
		        _m.state = MATCH_STATE.ROUND_OVER;
		        _m.timer = MATCH_ROUND_END_FRAMES;
		    }
		break;

		case MATCH_STATE.ROUND_OVER:
		    if (--_m.timer > 0) break;

		    if (_m.is_tiebreak) {
		        if (_m.winner >= 0) {
		            _m.state = MATCH_STATE.MATCH_OVER; // ganó el desempate, es el ganador final
		        } else {
		            match_begin_round(); // volvió a empatar: se repite (ADR-001)
		        }
		        break;
		    }

		    _m.rounds_played_in_block++;

		    if (_m.rounds_played_in_block >= _m.settings.rounds_per_block) {
		        _m.state = MATCH_STATE.INTERMISSION;
		        _m.timer = MATCH_INTERMISSION_FRAMES;
		    } else {
		        match_begin_round();
		    }
		break;
		
		case MATCH_STATE.INTERMISSION:
		    if (--_m.timer > 0) break;

		    var _max_score = 0;
		    for (var i = 0; i < array_length(_m.scores); i++) {
		        _max_score = max(_max_score, _m.scores[i]);
		    }

		    if (_max_score < _m.settings.score_to_win) {
		        // Nadie llegó todavía: otro bloque de rondas, con todos jugando.
		        _m.rounds_played_in_block = 0;
		        _m.round_participants = match_all_participants();
		        match_begin_round();
		        break;
		    }

		    var _leaders = [];
		    for (var i = 0; i < array_length(_m.scores); i++) {
		        if (_m.scores[i] == _max_score) array_push(_leaders, i);
		    }

		    if (array_length(_leaders) == 1) {
		        _m.winner = _leaders[0];
		        _m.state = MATCH_STATE.MATCH_OVER;
		    } else {
		        _m.is_tiebreak = true;
		        _m.round_participants = _leaders; // solo juegan los empatados
		        match_begin_round();
		    }
		break;
		
		case MATCH_STATE.MATCH_OVER:
		    var _joined_count = array_length(global.match.players_joined);
		    for (var _i = 0; _i < _joined_count; _i++) {
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
    if (_m.state == MATCH_STATE.COUNTDOWN) {
        draw_text(_cx, 40, string(ceil(_m.timer / room_speed)));
    } else if (_m.state == MATCH_STATE.ROUND_OVER) {
        draw_text(_cx, 40, (_m.winner >= 0) ? "Gana J" + string(_m.winner + 1) : "Empate");
    } else if (_m.state == MATCH_STATE.INTERMISSION) {
        draw_text(_cx, 40, "PUNTAJES");
        for (var _i = 0; _i < array_length(_m.scores); _i++) {
            draw_text(_cx, 70 + _i * 24, "J" + string(_i + 1) + ": " + string(_m.scores[_i]));
        }
    } else if (_m.state == MATCH_STATE.MATCH_OVER) {
        draw_text(_cx, 40, "GANADOR: J" + string(_m.winner + 1));
        for (var _i = 0; _i < array_length(_m.scores); _i++) {
            draw_text(_cx, 80 + _i * 24, "J" + string(_i + 1) + ": " + string(_m.scores[_i]));
        }
        draw_text(_cx, 80 + array_length(_m.scores) * 24 + 16, "Salto para reiniciar");
    }
    draw_set_halign(fa_left);
}
/// <summary>
/// Crea global.match con la configuración de una partida nueva. Se llama al salir
/// del lobby (Paso 2c), no al entrar — en LOBBY todavía no hace falta esta info.
/// </summary>
/// <param name="_score_to_win">Puntos necesarios para ganar la partida.</param>
/// <param name="_rounds_per_block">Rondas jugadas entre una intermission y la siguiente.</param>
/// <param name="_map_pool">Array de rooms candidatas al bag shuffle.</param>
function match_settings_init(_score_to_win, _rounds_per_block, _map_pool) {
    global.match.settings = {
        score_to_win: _score_to_win,
        rounds_per_block: _rounds_per_block,
        map_pool: _map_pool
    };
    global.match.scores = array_create(array_length(global.match.players_joined), 0);
    global.match.rounds_played_in_block = 0;
}


/// <summary>
/// Devuelve el próximo mapa a jugar usando bag shuffle: si la bolsa está vacía,
/// la rellena con una copia barajada del pool completo. Saca y devuelve el
/// primer elemento de la bolsa (ya barajada, así que "primero" = aleatorio).
/// </summary>
function match_bag_next_map() {
    var _m = global.match;

    if (!variable_struct_exists(_m, "map_bag") || array_length(_m.map_bag) == 0) {
        _m.map_bag = variable_clone(_m.settings.map_pool);
        array_shuffle_ext(_m.map_bag); // baraja in-place, no devuelve nada
    }

    return array_pop(_m.map_bag);
}

/// <summary>Todos los jugadores unidos, como lista de player_index (0..N-1).</summary>
function match_all_participants() {
    var _count = array_length(global.match.players_joined);
    var _arr = array_create(_count);
    for (var i = 0; i < _count; i++) _arr[i] = i;
    return _arr;
}

/// <summary>
/// Quiénes deben spawnear en la room actual: round_participants si ya existe
/// (durante una partida), o todos los unidos si todavía no (ej. en rm_lobby).
/// </summary>
function match_current_participants() {
    if (variable_struct_exists(global.match, "round_participants")) {
        return global.match.round_participants;
    }
    if (variable_struct_exists(global.match, "players_joined")) {
        return match_all_participants();
    }
    return [];
}

/// <summary>Arranca una ronda nueva: mapa random (bag shuffle) y pasa a COUNTDOWN.</summary>
function match_begin_round() {
    global.match.state = MATCH_STATE.COUNTDOWN;
    global.match.timer = MATCH_COUNTDOWN_SECONDS * room_speed;
    global.match.winner = -1;
    room_goto(match_bag_next_map());
}