/// @description Devuelve el sprite correspondiente al estado actual del jugador.
/// @param {Real} state  Un valor de PLAYER_STATE.
function player_get_sprite(state) {
    switch (state) {
        case PLAYER_STATE.IDLE:  return spr_player_idle;
        case PLAYER_STATE.RUN:   return spr_player_run;
        case PLAYER_STATE.JUMP:  return spr_player_jump;
        case PLAYER_STATE.FALL:  return spr_player_jump;  // PENDIENTE: sprite de caída propio
        case PLAYER_STATE.SLIDE: return spr_player_idle;  // PENDIENTE: sprite de slide propio
        default:                 return spr_player_idle;
    }
}