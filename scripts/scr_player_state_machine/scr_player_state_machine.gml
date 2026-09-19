/// @description Actualiza el estado del jugador para este frame, según su física e input actual.
/// @param {Id.Instance} player  La instancia de obj_player a actualizar.
/// @param {Struct} input        El struct devuelto por get_player_input().
function player_update_state(player, input) {
    with (player) {
        switch (state) {
            case PLAYER_STATE.IDLE:
                if (!is_grounded)         { state = PLAYER_STATE.FALL; break; }
                if (abs(hsp) > 0.5)       { state = PLAYER_STATE.RUN;  break; }
                if (input.down_held)      { state = PLAYER_STATE.SLIDE; break; }
                break;

            case PLAYER_STATE.RUN:
                if (!is_grounded)         { state = PLAYER_STATE.FALL; break; }
                if (abs(hsp) <= 0.5)      { state = PLAYER_STATE.IDLE; break; }
                if (input.down_held)      { state = PLAYER_STATE.SLIDE; break; }
                break;

            case PLAYER_STATE.JUMP:
                if (vsp >= 0)             { state = PLAYER_STATE.FALL; break; } // llegó al punto más alto, empieza a caer
                break;

            case PLAYER_STATE.FALL:
                if (is_grounded) {
                    state = (abs(hsp) > 0.5) ? PLAYER_STATE.RUN : PLAYER_STATE.IDLE;
                    break;
                }
                break;

            case PLAYER_STATE.SLIDE:
                if (!is_grounded)                        { state = PLAYER_STATE.FALL; break; }
                if (!input.down_held || abs(hsp) <= 0.5) { state = PLAYER_STATE.IDLE; break; }
                break;

            case PLAYER_STATE.HURT:
                // PENDIENTE: se define cuando exista el sistema de daño/armas
                break;

            case PLAYER_STATE.DEAD:
                // PENDIENTE: se define cuando exista el sistema de rondas
                break;
        }
    }
}