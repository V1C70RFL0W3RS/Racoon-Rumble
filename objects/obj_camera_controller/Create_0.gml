// La cámara real la asigna GameMaker por room (Enable Viewports). Acá solo
// guardamos estado propio del controller; la referencia se toma en Room Start,
// igual que el tilemap en obj_player/obj_weapon (la instancia persiste, la
// room y su cámara cambian).
cam    = noone;
view_w = CAMERA_VIEW_W;
view_h = CAMERA_VIEW_H;
center_x = 0;      // centro de la cámara en el mundo, SIN redondear (se redondea solo al aplicarlo)
center_y = 0;
snap_next = true;  // fuerza que el próximo Step ubique la cámara sin interpolar
fixed = false;     // true = cámara fija que encuadra la room entera (lobby); ver CAMERA_FIXED_ROOMS