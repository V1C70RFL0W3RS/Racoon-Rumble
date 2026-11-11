/// @description Lógica de "quién juega": une dispositivos al lobby.
/// No sabe nada de UI ni de scr_match — solo mantiene global.match.players_joined.

/// <summary>
/// Reinicia la lista de jugadores unidos. Se llama al entrar a rm_menu (partida nueva).
/// </summary>
function lobby_reset() {
    global.match.players_joined = [];
    // Ajustes de la partida que elige el host en su PC (se leen al empezar, ver obj_lobby_controller).
    global.match.lobby_settings = {
        score_to_win:     MATCH_DEFAULT_SCORE_TO_WIN,
        rounds_per_block: MATCH_DEFAULT_ROUNDS_PER_BLOCK,
        max_players:      LOBBY_MAX_PLAYERS_DEFAULT,   // el host puede cambiarlo (1-8)
    };
}

/// @desc ¿Es el host? En local, el primero que se unió. En LAN/online será quien creó la sala:
///       se cambia AQUÍ y todo lo que pide permiso de host lo respeta.
function lobby_is_host(_player_index) {
    return _player_index == LOBBY_HOST_INDEX;
}

/// <summary>
/// ¿Ese dispositivo puntual ya está en la lista de unidos?
/// </summary>
function lobby_device_joined(_device_type, _device_index) {
    var _list = global.match.players_joined;
    for (var i = 0; i < array_length(_list); i++) {
        if (_list[i].device_type == _device_type && _list[i].device_index == _device_index) {
            return true;
        }
    }
    return false;
}

/// @desc Máximo de jugadores actual (el que el host tiene configurado).
function lobby_get_max_players() {
    return global.match.lobby_settings.max_players;
}

/// <summary>
/// ÚNICO lugar donde se crea la entrada de un jugador unido. Le asigna el primer
/// color libre de la paleta. Devuelve true si lo agregó, false si no hay lugar.
/// Respeta el límite ACTIVO (lobby_settings.max_players).
/// </summary>
function lobby_add_player(_device_type, _device_index) {
    var _max = lobby_get_max_players();
    if (array_length(global.match.players_joined) >= _max) return false;

    array_push(global.match.players_joined, {
        device_type:  _device_type,
        device_index: _device_index,
        color_index:  palette_first_free_index(),
        hat_index:    0,   // sin gorro
        ready:        false
    });
    return true;
}

/// <summary>
/// Escanea teclado y gamepads buscando el botón de unirse. Si un dispositivo nuevo lo
/// presiona y hay lugar (respetando max_players), lo agrega.
/// Se llama una vez por Step desde el controlador del menú/lobby.
/// </summary>
function lobby_scan_join() {
    if (array_length(global.match.players_joined) >= lobby_get_max_players()) return;

    // Jugador teclado normal (WASD + espacio): uno solo posible.
    if (!lobby_device_joined("keyboard", 0) && keyboard_check_pressed(LOBBY_JOIN_KEY)) {
        lobby_add_player("keyboard", 0);
    }

    // TEMPORAL: segundo teclado de testeo (flechas + numpad).
    if (!lobby_device_joined("keyboard2", 0) && keyboard_check_pressed(LOBBY_JOIN_KEY_TEST)) {
        lobby_add_player("keyboard2", 0);
    }

    // Gamepads conectados (mismo botón que el salto: gp_face1).
    for (var g = 0; g < 12; g++) {
        if (!gamepad_is_connected(g)) continue;
        if (lobby_device_joined("gamepad", g)) continue;
        if (gamepad_button_check_pressed(g, gp_face1)) lobby_add_player("gamepad", g);
    }
}

// =============================================================================
// CAMBIOS DESDE LAS PCs DEL LOBBY
// DECISIÓN: todo cambio pasa por estas funciones, que revisan los permisos. En LAN/online
// serán lo que viaje por la red (el cliente pide, el host aplica).
// =============================================================================

/// @desc Cambia el color de un jugador al siguiente (o anterior) que nadie más use.
function lobby_set_color(_player_index, _dir) {
    var _p = global.match.players_joined[_player_index];
    var _n = array_length(global.player_palette);
    var _c = _p.color_index;
    repeat (_n - 1) {
        _c = (_c + _dir + _n) mod _n;
        if (!palette_is_taken(_c, _player_index)) { _p.color_index = _c; return; }
    }
}

/// @desc Cambia el gorro de un jugador (los gorros sí se pueden repetir).
function lobby_set_hat(_player_index, _dir) {
    var _p = global.match.players_joined[_player_index];
    var _n = hat_count();
    _p.hat_index = (_p.hat_index + _dir + _n) mod _n;
}

/// @desc Cambia un ajuste de la partida. Solo el host; el valor queda dentro de su rango.
function lobby_set_setting(_requester, _key, _dir) {
    if (!lobby_is_host(_requester)) return;
    var _r = lobby_setting_range(_key);
    var _s = global.match.lobby_settings;
    _s[$ _key] = clamp(_s[$ _key] + _dir, _r[0], _r[1]);
}

/// @desc [mínimo, máximo] de cada ajuste. Agregar un ajuste = un case aquí + una opción en la PC.
function lobby_setting_range(_key) {
    switch (_key) {
        case "score_to_win":     return [LOBBY_SCORE_MIN,         LOBBY_SCORE_MAX];
        case "rounds_per_block": return [LOBBY_ROUNDS_MIN,        LOBBY_ROUNDS_MAX];
        case "max_players":      return [LOBBY_MAX_PLAYERS_MIN,   LOBBY_MAX_PLAYERS_MAX];
    }
    return [0, 0];
}

// --- Adaptadores para menu_option: (ctx) → texto y (ctx, dir, requester) → cambio ---
function lobby_color_text(_slot) {
    return global.player_palette[global.match.players_joined[_slot].color_index].name;
}
function lobby_color_step(_slot, _dir, _requester) {
    if (_requester == _slot) lobby_set_color(_slot, _dir);   // cada uno cambia SOLO lo suyo
}
function lobby_hat_text(_slot) {
    return hat_get_name(global.match.players_joined[_slot].hat_index);
}
function lobby_hat_step(_slot, _dir, _requester) {
    if (_requester == _slot) lobby_set_hat(_slot, _dir);
}
function lobby_setting_text(_key) {
    return string(global.match.lobby_settings[$ _key]);
}
function lobby_setting_step(_key, _dir, _requester) {
    lobby_set_setting(_requester, _key, _dir);
}
