// Solo se dibuja a sí misma cuando está suelta.
// image_xscale = hacia dónde mira; angle = rotación visual.
if (holder == noone) {
    draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, angle, c_white, 1);
}