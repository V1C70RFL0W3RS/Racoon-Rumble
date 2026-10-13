/// @description Lógica de "quién juega": une dispositivos al lobby.
/// No sabe nada de UI ni de scr_match — solo mantiene global.match.players_joined.

/// <summary>
/// Reinicia la lista de jugadores unidos. Se llama al entrar a rm_menu (partida nueva).
/// </summary>
function lobby_reset() {
    global.match.players_joined = [];
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

/// <summary>
/// ÚNICO lugar donde se crea la entrada de un jugador unido. Le asigna el primer
/// color libre de la paleta. Devuelve true si lo agregó, false si no hay lugar.
/// </summary>
function lobby_add_player(_device_type, _device_index) {
    // Defensa extra: dos dispositivos pueden unirse en el mismo Step.
    if (array_length(global.match.players_joined) >= MAX_PLAYERS) return false;

    array_push(global.match.players_joined, {
        device_type:  _device_type,
        device_index: _device_index,
        color_index:  palette_first_free_index(),
        ready:        false
    });
    return true;
}

/// <summary>
/// Escanea teclado y gamepads buscando el botón de unirse. Si un dispositivo nuevo lo
/// presiona y hay lugar, lo agrega. Se llama una vez por Step desde el controlador
/// del menú/lobby.
/// </summary>
function lobby_scan_join() {
    if (array_length(global.match.players_joined) >= MAX_PLAYERS) return;

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