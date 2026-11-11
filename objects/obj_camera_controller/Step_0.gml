if (fixed) exit;   // cámara fija (lobby): la ubicó Room Start y no se mueve

// --- Caja de los jugadores VIVOS (cuerpo entero, no solo los pies). Los muertos no cuentan.
var _left = infinity, _right = -infinity, _top = infinity, _bottom = -infinity, _n = 0;

with (obj_player) {
    if (state != PLAYER_STATE.DEAD) {
        _left   = min(_left,   bbox_left);
        _right  = max(_right,  bbox_right);
        _top    = min(_top,    bbox_top);
        _bottom = max(_bottom, bbox_bottom);
        _n++;
    }
}

if (_n == 0) exit;

// Se recorta a los límites del nivel. Un jugador cayendo fuera del mapa deja de alejar la cámara.
_left   = clamp(_left,   0, room_width);
_right  = clamp(_right,  0, room_width);
_top    = clamp(_top,    -CAMERA_TOP_MARGIN, room_height);
_bottom = clamp(_bottom, -CAMERA_TOP_MARGIN, room_height);

// Borde dinámico: crece con el ancho actual de la vista (biblia 11.6).
var _border = clamp(min(view_w, CAMERA_BORDER_REF_W) / CAMERA_BORDER_REF_W * CAMERA_BORDER_MAX,
                    CAMERA_BORDER_MIN, CAMERA_BORDER_MAX);

// Altura que hace entrar a todos. Nunca más que la room entera ni más ancha que ella.
var _max_h = max(min(room_height + CAMERA_TOP_MARGIN, room_width / CAMERA_ASPECT), CAMERA_MIN_HEIGHT);
var _target_h = clamp(max((_bottom - _top) + _border * 2,
                          ((_right - _left) + _border * 2) / CAMERA_ASPECT),
                      CAMERA_MIN_HEIGHT, _max_h);

var _target_x = (_left + _right) / 2;
var _target_y = (_top + _bottom) / 2;

if (snap_next) {
    // Arranque de ronda: sin viaje de cámara (biblia: lerpSpeed arranca en 1.0).
    view_h = _target_h;
    center_x = _target_x;
    center_y = _target_y;
    snap_next = false;
} else {
    view_h = lerp(view_h, _target_h, CAMERA_ZOOM_LERP);
    // lerp nunca toca el objetivo: sin este ajuste el zoom quedaría fraccionario para siempre.
    if (abs(view_h - _target_h) < CAMERA_SNAP_DIST) view_h = _target_h;

    center_x = lerp(center_x, _target_x, CAMERA_POS_LERP);
    center_y = lerp(center_y, _target_y, CAMERA_POS_LERP);
}
view_w = view_h * CAMERA_ASPECT;   // el ancho SIEMPRE sale de la altura

// NO es de Duck Game: garantía dura. Si el lerp va atrasado (caída rápida, aleteo), se agranda
// la vista y se corre el centro lo justo para que nadie quede a menos de CAMERA_HARD_MARGIN del
// borde. Borra todo este bloque si prefieres el comportamiento puro de Duck Game.
var _need_h = max((_bottom - _top) + CAMERA_HARD_MARGIN * 2,
                  ((_right - _left) + CAMERA_HARD_MARGIN * 2) / CAMERA_ASPECT);
if (view_h < _need_h) {
    view_h = min(_need_h, _max_h);
    view_w = view_h * CAMERA_ASPECT;
}
var _cx_min = _right  + CAMERA_HARD_MARGIN - view_w / 2;
var _cx_max = _left   - CAMERA_HARD_MARGIN + view_w / 2;
center_x = (_cx_min <= _cx_max) ? clamp(center_x, _cx_min, _cx_max) : (_left + _right) / 2;
var _cy_min = _bottom + CAMERA_HARD_MARGIN - view_h / 2;
var _cy_max = _top    - CAMERA_HARD_MARGIN + view_h / 2;
center_y = (_cy_min <= _cy_max) ? clamp(center_y, _cy_min, _cy_max) : (_top + _bottom) / 2;

// Dentro de los bordes de la room (arriba, con el permiso de CAMERA_TOP_MARGIN).
center_x = (room_width < view_w) ? room_width / 2
         : clamp(center_x, view_w / 2, room_width - view_w / 2);
center_y = clamp(center_y, view_h / 2 - CAMERA_TOP_MARGIN, room_height - view_h / 2);

// El redondeo va SOLO al aplicar: la posición cae en la grilla de píxeles y no tiembla.
camera_set_view_size(cam, view_w, view_h);
camera_set_view_pos(cam, round(center_x - view_w / 2), round(center_y - view_h / 2));