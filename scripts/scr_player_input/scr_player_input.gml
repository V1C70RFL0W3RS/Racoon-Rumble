/// @description scr_player_input — devuelve un struct con el input de ESTE frame para un jugador dado.
/// Único lugar que conoce teclado y mando: el resto del juego solo lee este struct.
/// @param {real} player_index

function get_player_input(player_index) {
    var _input = {
        move_x:       0,
        jump_pressed: false,
        jump_held:    false,
        fire_pressed: false,
        fire_held:    false,
        grab_pressed: false,
        up_held:      false,
        down_held:    false
    };

    // El dispositivo no se deduce de player_index: se consulta en la lista
    // armada durante el lobby (ver scr_lobby).
    var _device = global.match.players_joined[player_index];

    if (_device.device_type == "keyboard") {
        // Teclado: A/D mover, Espacio saltar, E agarrar/tirar, W/S arriba/abajo, clic izquierdo disparar.
        _input.move_x       = keyboard_check(ord("D")) - keyboard_check(ord("A"));
        _input.jump_pressed = keyboard_check_pressed(vk_space);
        _input.jump_held    = keyboard_check(vk_space);
        _input.fire_pressed = mouse_check_button_pressed(mb_left);
        _input.fire_held    = mouse_check_button(mb_left);
        _input.grab_pressed = keyboard_check_pressed(ord("E"));
        _input.up_held      = keyboard_check(ord("W"));
        _input.down_held    = keyboard_check(ord("S"));

    } else if (_device.device_type == "keyboard2") {
        // TEMPORAL: segundo jugador de testeo, mismo teclado (flechas + numpad).
        _input.move_x       = keyboard_check(vk_right) - keyboard_check(vk_left);
        _input.jump_pressed = keyboard_check_pressed(vk_numpad0);
        _input.jump_held    = keyboard_check(vk_numpad0);
        _input.fire_pressed = keyboard_check_pressed(vk_numpad2);
        _input.fire_held    = keyboard_check(vk_numpad2);
        _input.grab_pressed = keyboard_check_pressed(vk_numpad1);
        _input.up_held      = keyboard_check(vk_up);
        _input.down_held    = keyboard_check(vk_down);

    } else { // "gamepad"
        var _gp = _device.device_index; // viene guardado directo, no es player_index - 1
        if (gamepad_is_connected(_gp)) {
            // Movimiento digital con zona muerta: un stick gastado no mueve al jugador solo.
            var _ax = gamepad_axis_value(_gp, gp_axislh);
            _input.move_x       = (abs(_ax) > INPUT_STICK_DEADZONE) ? sign(_ax) : 0;

            var _ay = gamepad_axis_value(_gp, gp_axislv);
            _input.up_held      = (_ay < -0.5);
            _input.down_held    = (_ay >  0.5);

            _input.jump_pressed = gamepad_button_check_pressed(_gp, gp_face1);
            _input.jump_held    = gamepad_button_check(_gp, gp_face1);
            _input.fire_pressed = gamepad_button_check_pressed(_gp, gp_shoulderrb);
            _input.fire_held    = gamepad_button_check(_gp, gp_shoulderrb);
            _input.grab_pressed = gamepad_button_check_pressed(_gp, gp_face3);
        }
    }

    return _input;
}