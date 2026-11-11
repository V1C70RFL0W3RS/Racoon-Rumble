/// @file scr_interact
/// Objetos que se USAN (obj_interactable y sus hijos: PCs del lobby; a futuro botones,
/// máquinas...). El jugador se acerca con las manos vacías y presiona agarrar. Mientras lo usa,
/// su input maneja el menú del objeto y su cuerpo se queda quieto.
///
/// Quién puede usarlo lo dice la bandera use_slot del objeto:
///   INTERACT_ANYONE = cualquiera, INTERACT_HOST = solo el host, 0..3 = solo ese jugador.

/// @desc ¿Puede este jugador usar este objeto? (no mira si está ocupado ni la distancia)
function interact_can_use(_it, _player) {
    switch (_it.use_slot) {
        case INTERACT_ANYONE: return true;
        case INTERACT_HOST:   return lobby_is_host(_player.player_index);
        default:              return _it.use_slot == _player.player_index;
    }
}

/// @desc ¿Está el jugador al alcance del objeto? Se mide desde el pecho (el hombro).
function interact_in_range(_it, _player) {
    return point_distance(_it.x, _it.y, _player.x, _player.y + PLAYER_SHOULDER_Y) <= INTERACT_RADIUS;
}

/// @desc Objeto libre más cercano que este jugador puede usar, o noone.
function interact_find(_player) {
    var _best   = noone;
    var _best_d = infinity;
    with (obj_interactable) {
        // Guard: si el hijo olvidó event_inherited(), 'user' puede no existir todavía.
        if (!variable_instance_exists(id, "user")) continue;
        if (user != noone || !interact_can_use(id, _player) || !interact_in_range(id, _player)) continue;
        var _d = point_distance(x, y, _player.x, _player.y);
        if (_d < _best_d) { _best_d = _d; _best = id; }
    }
    return _best;
}

/// @desc ¿Hay alguien cerca que podría usar este objeto? (para mostrar el aviso "usar")
function interact_someone_near(_it) {
    var _near = false;
    with (obj_player) {
        if (state != PLAYER_STATE.DEAD && using == noone && held_item == noone
            && interact_can_use(_it, id) && interact_in_range(_it, id)) { _near = true; break; }
    }
    return _near;
}

/// @desc ÚNICO lugar donde un jugador empieza a usar un objeto.
function interact_begin(_it, _player) {
    _it.user       = _player;
    _it.menu_index = 0;
    _it.nav_dir    = 0;
    _it.image_index = 1;   // frame 1 = en uso (p. ej. pantalla encendida)
    _player.using  = _it;
    _player.hsp    = 0;
}

/// @desc ÚNICO lugar donde se deja de usar un objeto.
function interact_end(_it) {
    if (_it.user != noone && instance_exists(_it.user)) _it.user.using = noone;
    _it.user = noone;
    _it.image_index = 0;
}

/// @desc El jugador que usa el objeto maneja su menú. Agarrar o saltar = salir.
///       Lo llama el Step de obj_player en vez de su movimiento normal.
function interact_handle_input(_it, _in) {
    if (_in.grab_pressed || _in.jump_pressed) { interact_end(_it); return; }
    menu_options_navigate(_it, _in, _it.user.player_index);
}
