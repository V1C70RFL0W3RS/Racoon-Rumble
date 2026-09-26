// Cada room tiene su propia cámara nueva; hay que volver a tomarla.
cam = view_camera[0];

view_w = CAMERA_VIEW_W;
view_h = CAMERA_VIEW_H;

// Arranca centrada en el mapa, no en la esquina (0,0), mientras el Step
// todavía no tuvo un frame para calcular el centro real de los jugadores.
camera_set_view_size(cam, view_w, view_h);
camera_set_view_pos(cam, room_width / 2 - view_w / 2, room_height / 2 - view_h / 2);

cam = view_camera[0];
view_w = CAMERA_VIEW_W;
view_h = CAMERA_VIEW_H;
snap_next = true;

// Posición provisoria, se pisa en el primer Step; evita un frame en (0,0).
camera_set_view_size(cam, view_w, view_h);
camera_set_view_pos(cam, room_width / 2 - view_w / 2, room_height / 2 - view_h / 2);