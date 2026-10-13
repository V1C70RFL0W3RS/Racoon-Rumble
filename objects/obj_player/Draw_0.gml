// --- obj_player → Draw Event ---
var _color = player_get_color_index(player_index);
var _ang   = player_get_arm_angle(); // un solo ángulo para brazo y arma

// 1. Cuerpo (con color)
palette_apply(_color);
draw_sprite_ext(sprite_index, image_index, x, y, facing, 1, 0, c_white, 1);
palette_reset();

// 2. Arma (sin color), en la mano
if (held_weapon != noone) {
    weapon_draw_held(held_weapon, player_hand_x(_ang), player_hand_y(_ang), facing, _ang);
}

// 3. Brazo (con color), encima del arma
palette_apply(_color);
player_draw_arm(_ang);
palette_reset();

player_debug_arm(_ang); // TEMPORAL