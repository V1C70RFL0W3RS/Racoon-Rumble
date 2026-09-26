// Centro y dispersión de los jugadores VIVOS. Los muertos no cuentan:
// si murieron todos a la vez la cámara se queda donde estaba (ver _n == 0).
var _left = infinity, _right = -infinity, _top = infinity, _bottom = -infinity, _n = 0;

with (obj_player) {
    if (state != PLAYER_STATE.DEAD) {
        _left   = min(_left, x);
        _right  = max(_right, x);
        _top    = min(_top, y);
        _bottom = max(_bottom, y);
        _n++;
    }
}

if (_n == 0) exit;

// Cuánto mundo hay que mostrar para que todos entren, con margen.
var _span_x = max(_right - _left + CAMERA_PADDING_X * 2, CAMERA_VIEW_W);
var _span_y = max(_bottom - _top + CAMERA_PADDING_Y * 2, CAMERA_VIEW_H);

// Se mantiene la proporción 16:9 siempre: el eje que pida más zoom-out manda.
var _scale = clamp(max(_span_x / CAMERA_VIEW_W, _span_y / CAMERA_VIEW_H), 1, CAMERA_MAX_ZOOM_OUT);
var _target_w = CAMERA_VIEW_W * _scale;
var _target_h = CAMERA_VIEW_H * _scale;

var _target_x = (_left + _right) / 2;
var _target_y = (_top + _bottom) / 2;

if (snap_next) {
    // Arranque de ronda: sin interpolar, directo a la posición real de los jugadores.
    view_w = _target_w;
    view_h = _target_h;
    var _new_x = _target_x;
    var _new_y = _target_y;
    snap_next = false;
} else {
    view_w = lerp(view_w, _target_w, CAMERA_ZOOM_LERP);
    view_h = lerp(view_h, _target_h, CAMERA_ZOOM_LERP);

    var _cur_x = camera_get_view_x(cam) + camera_get_view_width(cam) / 2;
    var _cur_y = camera_get_view_y(cam) + camera_get_view_height(cam) / 2;
    var _new_x = lerp(_cur_x, _target_x, CAMERA_POS_LERP);
    var _new_y = lerp(_cur_y, _target_y, CAMERA_POS_LERP);
}

_new_x = (room_width  < view_w) ? room_width  / 2 : clamp(_new_x, view_w / 2,  room_width  - view_w / 2);
_new_y = (room_height < view_h) ? room_height / 2 : clamp(_new_y, view_h / 2, room_height - view_h / 2);

camera_set_view_size(cam, view_w, view_h);
camera_set_view_pos(cam, _new_x - view_w / 2, _new_y - view_h / 2);