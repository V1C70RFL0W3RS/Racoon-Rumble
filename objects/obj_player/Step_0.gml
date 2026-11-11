// --- obj_player → Step Event ---

if (state == PLAYER_STATE.DEAD) exit;
if (variable_struct_exists(global.match, "state") && global.match.state == MATCH_STATE.COUNTDOWN) exit;

var _in = get_player_input(player_index);
if (using != noone) {
    // Usando una PC: los controles manejan su menú y el cuerpo se queda quieto (la gravedad sigue).
    interact_handle_input(using, _in);
    _in = input_empty();
}
player_update_item(_in);
aim_up = _in.up_held;
player_update_arm_raise();   
player_try_fire(_in);
if (ammo_pips_timer > 0) ammo_pips_timer--;

player_update_movement(_in);
player_update_state(id);
player_update_animation();
player_update_held_position();
if (DEBUG_TOOLS) player_debug_tune_shoulder();   // TEMPORAL
if (DEBUG_TOOLS) corpse_debug_tune_joint();      // TEMPORAL

if (y > room_height + ROOM_FALL_KILL_MARGIN) {
    player_die();
}


