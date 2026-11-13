// --- obj_player → Step Event ---

if (state == PLAYER_STATE.DEAD) exit;
if (variable_struct_exists(global.match, "state") && global.match.state == MATCH_STATE.COUNTDOWN) exit;

if (ragdoll_cooldown > 0) ragdoll_cooldown--;

var _in = get_player_input(player_index);
if (state == PLAYER_STATE.RAGDOLL) {
    // El cuerpo lo mueve la física del cadáver; aquí solo se arrastra o se levanta.
    player_ragdoll_update(_in);
    exit;
}
if (using != noone) {
    // Usando una PC: los controles manejan su menú y el cuerpo se queda quieto (la gravedad sigue).
    interact_handle_input(using, _in);
    _in = input_empty();
}
if (_in.ragdoll_pressed && player_ragdoll_can_enter()) {
    player_ragdoll_enter();
    exit;
}
player_update_item(_in);
aim_up = _in.up_held;
player_update_arm_raise();   
player_try_fire(_in);
if (ammo_pips_timer > 0) ammo_pips_timer--;

var _b0   = bbox_bottom;   // antes de moverse: para pisar cabezas (botas)
var _fall = vsp;
player_update_movement(_in);
player_try_stomp(_b0, _fall);
if (player_check_spikes()) exit;
player_update_state(id);
player_update_animation();
player_update_held_position();
if (DEBUG_TOOLS) player_debug_tune_shoulder();   // TEMPORAL
if (DEBUG_TOOLS) corpse_debug_tune_joint();      // TEMPORAL

if (y > room_height + ROOM_FALL_KILL_MARGIN) {
    player_die();
}


