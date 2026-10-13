/// @desc Aplica daño a un jugador. Al llegar a 0 de vida, muere.
/// @param {Id.Instance} _player Instancia de obj_player.
/// @param {Real} _damage
function player_take_hit(_player, _damage) {
    with (_player) {
        if (state == PLAYER_STATE.DEAD) return; // no se puede matar dos veces
        hp -= _damage;
        if (hp <= 0) player_die();
    }
}

/// @desc Mata al jugador. Ejecutar como el propio jugador (lo llama player_take_hit).
///       Suelta el arma y se oculta. No hay respawn: vuelve a aparecer en la
///       ronda siguiente, cuando el manager recrea a los jugadores.
function player_die() {
    // DECISIÓN: la mano se calcula ANTES de soltar el arma. Sin arma, el ángulo
    // del brazo pasa a ser el de "colgando" y el arma saltaría de lugar.
    var _ang = player_get_arm_angle();
    var _hx  = player_hand_x(_ang);
    var _hy  = player_hand_y(_ang);

    state = PLAYER_STATE.DEAD;
    hsp = 0;
    vsp = 0;
    visible = false;   // con visible = false, GameMaker no ejecuta el Draw

    // El arma que llevaba salta por los aires en vez de desaparecer.
    if (held_weapon != noone) {
        var _w = held_weapon;
        held_weapon = noone;
        weapon_eject(_w, _hx, _hy, facing, random_range(-2, 2), -4, random_range(-10, 10));
    }
}