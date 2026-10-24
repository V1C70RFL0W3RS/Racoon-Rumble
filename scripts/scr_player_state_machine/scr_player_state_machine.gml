/// @description Actualiza el estado del jugador para este frame, según su física actual.
/// @param {Id.Instance} player  La instancia de obj_player a actualizar.
/// @param {Struct} input        El struct devuelto por get_player_input() (hoy sin uso aquí).
function player_update_state(player, input) {
    with (player) {
        // Agachado y slide los deciden las banderas de física (player_update_crouch):
        // tienen prioridad mientras estén activas. Al soltarlas se vuelve a IDLE y el
        // switch de abajo afina (RUN, FALL...) en este mismo frame.
        if (state != PLAYER_STATE.HURT && state != PLAYER_STATE.DEAD) {
            if (sliding)        state = PLAYER_STATE.SLIDE;
            else if (crouching) state = PLAYER_STATE.CROUCH;
            else if (state == PLAYER_STATE.CROUCH || state == PLAYER_STATE.SLIDE) state = PLAYER_STATE.IDLE;
        }

        switch (state) {
            case PLAYER_STATE.IDLE:
                if (!is_grounded)    { state = PLAYER_STATE.FALL; break; }
                if (abs(hsp) > 0.5)  { state = PLAYER_STATE.RUN;  break; }
                break;

            case PLAYER_STATE.RUN:
                if (!is_grounded)    { state = PLAYER_STATE.FALL; break; }
                if (abs(hsp) <= 0.5) { state = PLAYER_STATE.IDLE; break; }
                break;

            case PLAYER_STATE.JUMP:
                if (vsp >= 0)        { state = PLAYER_STATE.FALL; break; } // llegó al punto más alto, empieza a caer
                break;

            case PLAYER_STATE.FALL:
                if (is_grounded) {
                    state = (abs(hsp) > 0.5) ? PLAYER_STATE.RUN : PLAYER_STATE.IDLE;
                    break;
                }
                break;

            case PLAYER_STATE.CROUCH:
            case PLAYER_STATE.SLIDE:
                // Decididos arriba por las banderas.
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