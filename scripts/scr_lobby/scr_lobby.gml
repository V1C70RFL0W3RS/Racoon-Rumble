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
/// Escanea teclado y gamepads buscando el botón de unirse. Si un dispositivo nuevo lo
/// presiona y hay lugar, lo agrega. Se llama una vez por Step desde el controlador
/// del menú/lobby (todavía no existe ese objeto — lo armamos más abajo).
/// </summary>
function lobby_scan_join() {
    if (array_length(global.match.players_joined) >= MAX_PLAYERS) return;

    // "Jugador teclado": uno solo posible, comparte botón con el salto (como DuckGame).
	// Jugador teclado normal (WASD + espacio).
	if (!lobby_device_joined("keyboard", 0) && keyboard_check_pressed(LOBBY_JOIN_KEY)) {
	    array_push(global.match.players_joined, {
	        device_type: "keyboard",
	        device_index: 0,
	        ready: false
	    });
	}

	// TEMPORAL: segundo teclado de testeo (flechas + numpad).
	if (!lobby_device_joined("keyboard2", 0) && keyboard_check_pressed(LOBBY_JOIN_KEY_TEST)) {
	    array_push(global.match.players_joined, {
	        device_type: "keyboard2",
	        device_index: 0,
	        ready: false
	    });
	}

    // Gamepads conectados (mismo botón que el salto: gp_face1).
    for (var g = 0; g < 12; g++) {
        if (!gamepad_is_connected(g)) continue;
        if (lobby_device_joined("gamepad", g)) continue;
        if (gamepad_button_check_pressed(g, gp_face1)) {
            array_push(global.match.players_joined, {
                device_type: "gamepad",
                device_index: g,
                ready: false
            });
        }
        if (array_length(global.match.players_joined) >= MAX_PLAYERS) break;
    }
}