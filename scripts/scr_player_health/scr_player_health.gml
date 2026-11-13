/// @desc Aplica daño a un jugador. Al llegar a 0 de vida, muere.
/// @param {Id.Instance} _player Instancia de obj_player.
/// @param {Real} _damage
/// @param {Real} [_dir] Dirección del golpe en grados (la de la bala). Opcional.
/// @param {Real} [_power] Empujón del golpe (AmmoDef.impact). 0 = sin empujón.
/// @param {Real} [_zone] HIT_ZONE donde pegó (decide qué equipo lo puede detener).
function player_take_hit(_player, _damage, _dir = 0, _power = 0, _zone = HIT_ZONE.BODY) {
    with (_player) {
        if (state == PLAYER_STATE.DEAD) return; // no se puede matar dos veces
        if (player_equip_try_block(_zone, _dir)) return;   // un casco o un chaleco lo detuvo
        hp -= _damage;
        if (hp <= 0) player_die(_dir, _power);
    }
}

/// @desc Mata al jugador. Ejecutar como el propio jugador (lo llama player_take_hit).
///       Suelta el arma, deja las dos piezas del cadáver y se oculta. No hay
///       respawn: vuelve a aparecer en la ronda siguiente, cuando el manager
///       recrea a los jugadores.
/// @param {Real} [_dir] Dirección del golpe que lo mató (grados).
/// @param {Real} [_power] Empujón de ese golpe. 0 (por defecto) = muerte sin golpe (caída).
function player_die(_dir = 0, _power = 0) {
    // DECISIÓN: la velocidad se lee ANTES de ponerla en cero, para que las
    // piezas del cadáver hereden la inercia del jugador.
    var _hsp = hsp;
    var _vsp = vsp;
    var _was_ragdoll = (state == PLAYER_STATE.RAGDOLL);

    // El arma que llevaba salta por los aires en vez de desaparecer. Va ANTES de cambiar el
    // estado: player_drop_item calcula la mano con la pose actual.
    player_drop_item(random_range(-2, 2), -4, random_range(-10, 10));
    // Gorro y demás salen volando (con la pose y la velocidad actuales). Si cayó fuera del mapa,
    // no: caerían para siempre (igual que el cadáver).
    if (y < room_height) player_unequip_drop_all();

    state = PLAYER_STATE.DEAD;
    if (using != noone) interact_end(using, id);   // deja de usar la PC o el ropero
    audio_play_sfx(snd_player_death, 0.04, SFX_PRIORITY_HIGH);
    hsp = 0;
    vsp = 0;
    visible = false;   // con visible = false, GameMaker no ejecuta el Draw

    // En ragdoll el cuerpo ya existe: no se crea otro, el que hay pasa a estar muerto.
    if (_was_ragdoll) {
        player_ragdoll_die(_dir, _power);
        return;
    }

    // Si murió cayendo fuera del mapa no se crean piezas: no habría nada que ver
    // y caerían para siempre.
    if (y < room_height) {
        // Pelo: hacia donde iba la bala; sin golpe (no debería pasar hoy), en todas direcciones.
        var _spread = (_power > 0) ? FX_FUR_DEATH_SPREAD : 180;
        fx_fur(x, y + FX_FUR_BODY_Y, _dir, _spread, player_get_color_index(player_index), FX_FUR_DEATH_COUNT);
        // Velocidad del cadáver: parte de la inercia del jugador, un saltito y el empujón del golpe
        // (misma fórmula que un disparo a un cadáver ya caído: impact × CORPSE_IMPACT_MULT).
        var _kx = lengthdir_x(_power * CORPSE_IMPACT_MULT, _dir);
        var _ky = lengthdir_y(_power * CORPSE_IMPACT_MULT, _dir);
        corpse_spawn(x, y, facing, _hsp * CORPSE_INERTIA + _kx, _vsp + CORPSE_POP_SPEED + _ky,
                     player_get_color_index(player_index), _kx * CORPSE_HIT_TUMBLE);
    }
}

/// @desc Zona del cuerpo (HIT_ZONE) que cruza una bala que va de (_x1,_y1) a (_x2,_y2).
///       Jugador de pie: si la bala pasa cerca del centro de su cabeza, es la cabeza; si no, el
///       cuerpo. Pieza de un ragdoll: siempre el cuerpo (el casco se cae al tirarse).
/// @param {Id.Instance} _target El jugador, o la pieza de su cuerpo (body_of).
function hit_zone_of(_target, _x1, _y1, _x2, _y2) {
    if (_target.object_index != obj_player) return HIT_ZONE.BODY;

    var _cx, _cy;
    with (_target) { _cx = player_head_center_x(); _cy = player_head_center_y(); }
    // Punto del segmento más cercano al centro de la cabeza.
    var _dx = _x2 - _x1;
    var _dy = _y2 - _y1;
    var _l2 = _dx * _dx + _dy * _dy;
    var _t  = (_l2 > 0) ? clamp(((_cx - _x1) * _dx + (_cy - _y1) * _dy) / _l2, 0, 1) : 0;
    var _d  = point_distance(_x1 + _dx * _t, _y1 + _dy * _t, _cx, _cy);
    return (_d <= PLAYER_HEAD_ZONE_RADIUS) ? HIT_ZONE.HEAD : HIT_ZONE.BODY;
}

/// @desc ¿Está vivo y de pie (ni muerto ni en ragdoll)? Solo así su máscara representa su
///       cuerpo: en ragdoll el cuerpo son las piezas (ver scr_player_ragdoll). Ejecutar como el jugador.
function player_is_upright() {
    return state != PLAYER_STATE.DEAD && state != PLAYER_STATE.RAGDOLL;
}
