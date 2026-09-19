// --- obj_player → Draw Event ---
var _spr = player_get_sprite(state);
if (sprite_index != _spr) { sprite_index = _spr; image_index = 0; }

draw_sprite_ext(sprite_index, image_index, x, y, facing, 1, 0, c_white, 1);

// Arma dibujada aparte, en la mano — independiente de la pose del cuerpo
if (held_weapon != noone) {
    var _wx = x + (HAND_OFFSET_X * facing);
    var _wy = y + HAND_OFFSET_Y;
    draw_sprite_ext(held_weapon.sprite, 0, _wx, _wy, facing, 1, 0, c_white, 1);
}