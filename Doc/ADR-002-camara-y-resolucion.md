# ADR-002: Cámara dinámica, resolución base y resolución de dibujo

## Estado
Aceptada

## Contexto
Racoon Rumble es multijugador local (hasta 4 jugadores, luego red), para PC y celular, con
pixel art y mapas de distinto tamaño. Hacen falta tres decisiones ligadas entre sí, porque
cambiar una obliga a rehacer las otras: cuánto mundo se ve (resolución base), cómo se
mueve la cámara cuando los jugadores se separan, y a qué resolución se dibuja antes de
ampliar a la ventana.

En la Fase 3 Parte 2 se probó una cámara con zoom limitado a 2x sobre una vista de 640x360.
En la Parte 3 el mapache se rehízo a 32x32 (más chico que el anterior), y en la Parte 4 se
adoptaron los valores de movimiento de Duck Game, que están calibrados para una vista de
320x180. Con una room de 1280x720 (4x la vista base) varios jugadores quedaban fuera de
la cámara, y con el zoom a escala no entera se veían píxeles desparejos.

## Alternativas consideradas
- **Mapas de una sola pantalla, cámara fija:** sin zoom y pixel perfect siempre, pero limita
  cada mapa a la resolución de la pantalla. Se descartó en la Parte 2.
- **Zoom con tope fijo (`CAMERA_MAX_ZOOM_OUT` 2x, luego 4x) y margen fijo de 64 px:**
  fácil de entender, pero cada mapa más grande que el tope deja jugadores fuera, y el
  número hay que mantenerlo a mano. Se implementó primero y se reemplazó.
- **Cámara continua estilo Duck Game (elegida):** el zoom lo decide el tamaño de la room y
  la separación de los jugadores, sin escalones. Más personajes pequeños en mapas grandes.
- **Resolución base 640x360:** más mundo visible y sprites más chicos; obliga a reescalar
  todos los valores de movimiento de Duck Game. **Resolución base 320x180 (elegida):** los
  valores de la biblia se usan sin convertir y el personaje se ve el doble de grande
  respecto a la pantalla, lo que ayuda a leerlo en un celular.
- **Resolución de dibujo igual a la vista (640x360):** más barata, pero con zoom no entero
  cada píxel del mundo ocupa 1 o 2 píxeles de la imagen (50 % de error). **1920x1080
  (elegida):** 6x la base, el error baja a ~17 %; cuesta unas 9 veces más píxeles dibujados.
  **1280x720:** 4x la base, exacta en 1x, 2x y 4x; es la opción de reserva si pesa en celular.

## Decisión
- **Vista base de 320x180** (16:9, `CAMERA_VIEW_W/H`). Todo valor de física y de arte se
  piensa para esa escala.
- **Cámara continua** (`obj_camera_controller`, persistente), con las reglas de Duck Game
  de la biblia (sección 11.6): se mide la caja del cuerpo de los jugadores vivos, recortada
  a la room (con `CAMERA_TOP_MARGIN` sobre el techo); borde dinámico entre 60 y 90 px; la
  altura se limita entre 60 px y la room entera; el ancho siempre sale de la altura;
  `lerp` de 0.05. **El zoom máximo lo fija la room, no una macro.**
- **Muerte por caída** al pasar `room_height + ROOM_FALL_KILL_MARGIN`; además, la caja que
  mide la cámara se recorta a la room, así un jugador cayendo no la aleja sin límite.
- **Resolución de dibujo de 1920x1080** (`CAMERA_RENDER_W/H`): `view_wport/hport` y
  `application_surface` se fijan en cada Room Start; el viewport del editor no manda.
- **La posición de la cámara se redondea solo al aplicarla**, nunca al guardar su estado.
- **La GUI se dibuja a la resolución real de la ventana** (`display_set_gui_size`), separada
  del mundo, para que el texto no se vea borroso.
- **Garantía dura de margen** (`CAMERA_HARD_MARGIN`): decisión propia, no de Duck Game, para
  que nadie salga de la vista cuando el `lerp` va atrasado. Es un bloque aislado y borrable.

## Consecuencias
### Positivas
- Los valores de movimiento y de armas de Duck Game se usan tal cual, sin escalar.
- Se pueden hacer mapas de cualquier tamaño sin tocar código; la cámara se adapta sola.
- El zoom en movimiento se ve parejo y en reposo queda estable.
- Nadie queda fuera de la vista, ni siquiera en caídas rápidas.

### Negativas / trade-offs aceptados
- **Regla de diseño de mapas:** el zoom máximo es la room entera, así que un mapa grande
  hace ver a los personajes pequeños. Hay que cuidar el tamaño de cada mapa, y un mapa
  más grande que ~4x la vista base (1280x720) empeora la lectura, sobre todo en celular.
- Se dibuja unas 9 veces más píxeles que con 640x360; en PC no se nota, pero **en celular
  no está medido**. Si pesa, se baja a 1280x720 cambiando solo dos macros.
- Con 1920x1080 solo son exactos los zoom de 1x, 2x, 3x y 6x; el resto queda en escala
  fraccionaria (suavizada por la resolución alta).
- La franja sobre el techo de la room muestra el color de fondo; hay que elegir uno que no
  se vea mal.
- Los números de la cámara (60, 90, 740, 0.05) vienen de la biblia y **no se verificaron
  contra el código fuente real** de Duck Game; si se encuentra una diferencia, se corrigen
  en `scr_config`.
- **Queda sin decidir el formato de pantalla en celular** (barras negras como Duck Game, o
  mostrar más mundo a los lados en pantallas alargadas), junto con la zona de los controles
  táctiles. Se tratará en un ADR aparte cuando se diseñen.
