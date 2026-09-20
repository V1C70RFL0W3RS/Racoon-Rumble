/// @description scr_player_input — devuelve un struct con el input de ESTE frame para un jugador dado
/// @param {real} player_index

function get_player_input(player_index) {
	var _input = {
	    move_x: 0,
	    jump_pressed: false,
	    jump_held: false,
	    fire_pressed: false,
	    down_held: false,
	    grab_pressed: false,
		up_held: false,
		fire_held: false
	};

    if (player_index == 0) {
        // Jugador 1 → teclado (WASD + Espacio, por ejemplo)
        _input.move_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
        _input.jump_pressed = keyboard_check_pressed(vk_space);
        _input.jump_held    = keyboard_check(vk_space);
        _input.fire_pressed = mouse_check_button_pressed(mb_left);
        _input.down_held    = keyboard_check(ord("S"));
		_input.grab_pressed = keyboard_check_pressed(ord("E"));
		_input.up_held = keyboard_check(ord("W"));
		_input.fire_held = mouse_check_button(mb_left);
		
    } else {
        // Jugadores 2, 3, 4 → gamepad (player_index - 1 = índice del gamepad físico)
        var _gp = player_index - 1;
        if (gamepad_is_connected(_gp)) {
            _input.move_x = gamepad_axis_value(_gp, gp_axislh);
            _input.jump_pressed = gamepad_button_check_pressed(_gp, gp_face1);
            _input.jump_held    = gamepad_button_check(_gp, gp_face1);
            _input.fire_pressed = gamepad_button_check_pressed(_gp, gp_shoulderrb);
            _input.down_held    = gamepad_axis_value(_gp, gp_axislv) > 0.5;
			_input.grab_pressed = gamepad_button_check_pressed(_gp, gp_face3);
			_input.up_held = gamepad_axis_value(_gp, gp_axislv) < -0.5;
			_input.fire_held = gamepad_button_check(_gp, gp_shoulderrb);
        }
    }

    return _input;
}