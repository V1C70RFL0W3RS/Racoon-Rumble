// Cada room tiene su propia cámara nueva; hay que volver a tomarla.
cam = view_camera[0];
view_w = CAMERA_VIEW_W;
view_h = CAMERA_VIEW_H;
snap_next = true;

// Posición provisoria, se pisa en el primer Step; evita un frame en (0,0).
center_x = room_width  / 2;
center_y = room_height / 2;
// Rooms con cámara FIJA (el lobby, como en Duck Game): encuadra la room entera y no se mueve.
// Si la room no es 16:9, se muestra un poco de fuera de la room en vez de recortarla.
fixed = array_contains(CAMERA_FIXED_ROOMS, room);
if (fixed) {
    view_h = max(room_height, room_width / CAMERA_ASPECT);
    view_w = view_h * CAMERA_ASPECT;
}

camera_set_view_size(cam, view_w, view_h);
camera_set_view_pos(cam, round(center_x - view_w / 2), round(center_y - view_h / 2));