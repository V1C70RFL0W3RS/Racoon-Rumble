// El tramo vertical del caño (filas 0..5 del sprite) se repite hacia arriba hasta el techo de la
// room, así el tubo se puede poner a cualquier altura en el editor sin estirar el sprite.
var _xo  = sprite_get_xoffset(sprite_index);
var _top = y - sprite_get_yoffset(sprite_index);
var _px  = x + (LOBBY_TUBE_PIPE_X - _xo) * image_xscale;
for (var _py = _top - LOBBY_TUBE_PIPE_H; _py > -LOBBY_TUBE_PIPE_H; _py -= LOBBY_TUBE_PIPE_H) {
    draw_sprite_part_ext(sprite_index, 0, LOBBY_TUBE_PIPE_X, 0, LOBBY_TUBE_PIPE_W, LOBBY_TUBE_PIPE_H,
                         _px, _py, image_xscale, 1, c_white, 1);
}
draw_self();
