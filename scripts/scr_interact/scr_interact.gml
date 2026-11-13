/// @file scr_interact
/// Objetos que se USAN (obj_interactable y sus hijos: PC del host, ropero; a futuro máquinas,
/// botones...). El jugador se acerca con las manos vacías y presiona agarrar. Mientras lo usa, su
/// input maneja el menú del objeto y su cuerpo se queda quieto.
///
/// DECISIÓN: varios jugadores pueden usar el mismo objeto a la vez (max_users; el ropero, todos).
/// Por eso el objeto guarda la lista de quién lo usa (users) y el CURSOR del menú (opción elegida,
/// repetición) vive en cada jugador (menu_cursor), no en el objeto.
///
/// Quién puede usarlo lo dice la bandera use_slot del objeto:
///   INTERACT_ANYONE = cualquiera, INTERACT_HOST = solo el host, 0..7 = solo ese jugador.

/// @desc ¿Puede este jugador usar este objeto? (no mira si hay lugar ni la distancia)
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

/// @desc ¿Le queda lugar para otro usuario?
function interact_has_room(_it) {
    return array_length(_it.users) < _it.max_users;
}

/// @desc Objeto con lugar más cercano que este jugador puede usar, o noone.
function interact_find(_player) {
    var _best   = noone;
    var _best_d = infinity;
    with (obj_interactable) {
        // Guard: si el hijo olvidó event_inherited(), 'users' puede no existir todavía.
        if (!variable_instance_exists(id, "users")) continue;
        if (!interact_has_room(id) || !interact_can_use(id, _player) || !interact_in_range(id, _player)) continue;
        var _d = point_distance(x, y, _player.x, _player.y);
        if (_d < _best_d) { _best_d = _d; _best = id; }
    }
    return _best;
}

/// @desc ¿Hay alguien cerca que podría usar este objeto ahora? (para el aviso "Agarrar: usar")
function interact_someone_near(_it) {
    if (!interact_has_room(_it)) return false;
    var _near = false;
    with (obj_player) {
        if (player_is_upright() && using == noone && held_item == noone
            && interact_can_use(_it, id) && interact_in_range(_it, id)) { _near = true; break; }
    }
    return _near;
}

/// @desc ÚNICO lugar donde un jugador empieza a usar un objeto.
function interact_begin(_it, _player) {
    array_push(_it.users, _player);
    _it.image_index = 1;   // frame 1 = en uso (pantalla encendida, puerta abierta...)
    _player.using = _it;
    _player.hsp   = 0;
    menu_cursor_reset(_player.menu_cursor);
}

/// @desc ÚNICO lugar donde un jugador deja de usar un objeto.
function interact_end(_it, _player) {
    var _i = array_get_index(_it.users, _player);
    if (_i >= 0) array_delete(_it.users, _i, 1);
    if (instance_exists(_player)) _player.using = noone;
    if (array_length(_it.users) == 0) _it.image_index = 0;
}

/// @desc Un jugador que usa el objeto maneja SU menú. Agarrar o saltar = salir.
///       Lo llama el Step de obj_player (como el jugador) en vez de su movimiento normal.
function interact_handle_input(_it, _in) {
    if (_in.grab_pressed || _in.jump_pressed) { interact_end(_it, id); return; }
    menu_options_navigate(_it, menu_cursor, _in, player_index);
}

/// @desc Dibuja en la GUI el menú de cada usuario sobre su cabeza, y el aviso "Agarrar: usar" si
///       alguien podría usarlo. Lo llama el Draw GUI de obj_interactable (todos los hijos).
function interact_draw_gui(_it) {
    for (var _i = 0; _i < array_length(_it.users); _i++) {
        var _p = _it.users[_i];
        if (!instance_exists(_p)) continue;
        menu_options_draw(_it, _p.menu_cursor, _p.player_index,
                          world_to_gui_x(_p.x), world_to_gui_y(_p.y + INTERACT_MENU_DY));
    }
    if (interact_someone_near(_it)) {
        ui_draw_hint_at("Agarrar: usar", world_to_gui_x(_it.x), world_to_gui_y(_it.bbox_top - 2));
    }
}
