// --- obj_player → Step Event (versión completa actualizada) ---

var _in = get_player_input(player_index);
player_update_weapon(_in);   // NUEVO
aim_up = _in.up_held;
player_try_fire(_in);
hsp = (_in.move_x != 0) ? approach(hsp, PLAYER_MOVE_SPEED * _in.move_x, PLAYER_ACCEL)
                          : approach(hsp, 0, PLAYER_ACCEL * 2);
if (_in.move_x != 0) facing = sign(_in.move_x);

vsp += GRAVITY;
if (_in.jump_pressed && is_grounded) {
    vsp = PLAYER_JUMP_FORCE;
    is_grounded = false;
    state = PLAYER_STATE.JUMP;
}

var col_h = move_and_collide(hsp, 0, tilemap);
if (array_length(col_h) > 0) hsp = 0;

var col_v = move_and_collide(0, vsp, tilemap);
if (array_length(col_v) > 0) {
    is_grounded = (vsp > 0);
    vsp = 0;
} else {
    is_grounded = false;
}

player_update_state(id, _in);