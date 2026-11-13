// Solo se dibuja la pieza suelta; la que está en la mano la dibuja el jugador.
if (holder != noone) exit;

// Salvaguarda visual (biblia 4.4.5 C: la pieza nunca se pinta a más de 8 px de la
// articulación). Si en un golpe fuerte la varilla se estira, la pieza se dibuja recortada
// hacia la cintura, que vive en la parte superior (rig).
var _px = x;
var _py = y;
var _top = (piece_frame == 1) ? partner : id;
if (_top != noone && instance_exists(_top) && is_struct(_top.rig)) {
    var _jx  = _top.rig.jx;
    var _jy  = _top.rig.jy;
    var _max = corpse_rod_length(piece_frame) + CORPSE_DRAW_SLACK;
    var _d   = point_distance(_jx, _jy, x, y);
    if (_d > _max) {
        var _k = _max / _d;
        _px = _jx + (x - _jx) * _k;
        _py = _jy + (y - _jy) * _k;
    }
}
holdable_draw(id, _px, _py, image_xscale, image_yscale, angle);
