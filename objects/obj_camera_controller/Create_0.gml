// La cámara real la asigna GameMaker por room (Enable Viewports). Acá solo
// guardamos estado propio del controller; la referencia se toma en Room Start,
// igual que el tilemap en obj_player/obj_weapon (la instancia persiste, la
// room y su cámara cambian).
cam    = noone;
view_w = CAMERA_VIEW_W;
view_h = CAMERA_VIEW_H;
snap_next = true; // fuerza que el próximo Step ubique la cámara sin interpolar