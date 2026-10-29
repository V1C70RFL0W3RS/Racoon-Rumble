// Solo se dibuja la pieza suelta; la que está en la mano la dibuja el jugador.
if (holder != noone) exit;

// Salvaguarda visual (biblia 4.4.5 C: la pieza nunca se pinta a más de 8 px de la
// articulación). Si en un golpe fuerte la varilla se estira, se dibuja recortada. Se recorta
// la pieza que cuelga de una mano o, si ambas están sueltas, la inferior (solo una, para
// que no se muevan las dos hacia la otra).
var _px = x;
var _py = y;
if (partner != noone && instance_exists(partner) && (partner.holder != noone || piece_frame == 1)) {
    var _max = corpse_rest_length() + CORPSE_DRAW_SLACK;
    var _d = point_distance(partner.x, partner.y, x, y);
    if (_d > _max) {
        var _k = _max / _d;
        _px = partner.x + (x - partner.x) * _k;
        _py = partner.y + (y - partner.y) * _k;
    }
}
holdable_draw(id, _px, _py, image_xscale, image_yscale, angle);