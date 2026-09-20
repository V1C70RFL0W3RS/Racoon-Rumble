// --- obj_player → Draw Event ---
var _spr = player_get_sprite(state);
if (sprite_index != _spr) { sprite_index = _spr; image_index = 0; }

draw_sprite_ext(sprite_index, image_index, x, y, facing, 1, 0, c_white, 1);

// Arma dibujada aparte, en la mano — independiente de la pose del cuerpo
// Arma dibujada aparte, en la mano — independiente de la pose del cuerpo
if (held_weapon != noone) weapon_draw_held(held_weapon, x, y, facing, aim_up);