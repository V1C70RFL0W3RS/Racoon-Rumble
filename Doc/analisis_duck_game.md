# Análisis de Diseño y Mecánicas: Duck Game

Este documento desglosa los elementos clave de **Duck Game** para servir como referencia en el desarrollo de un juego inspirado en él utilizando GameMaker.

## 1. Visión General
Duck Game es un juego de lucha de plataformas 2D (arena brawler) enfocado en el multijugador frenético. Su premisa se basa en rondas muy cortas, muertes de un solo golpe (one-hit kill) y una alta letalidad que fomenta la acción rápida, los reflejos y el caos divertido.

## 2. El Jugador (El Pato)
El personaje principal es extremadamente simple pero altamente expresivo, lo que ayuda a la legibilidad rápida en pantalla.
* **Hitbox:** Compacta y precisa. Cambia drásticamente dependiendo del estado (de pie, agachado, deslizando, o haciéndose el muerto/ragdoll).
* **Personalización:** Uso de "Sombreros" (Hats) que actúan como sprites superpuestos en la cabeza del pato. Esto no afecta el gameplay pero es crucial para la identidad del jugador.
* **Acciones "inútiles" pero sociales:** Graznar (Quack). Aunque no tiene utilidad real en combate, fomenta la interacción social y la provocación.

## 3. Movimiento y Físicas
El movimiento en Duck Game es fluido, con un fuerte componente de inercia, pero fácil de controlar.
* **Aceleración y Fricción:** Los patos tardan un poco en alcanzar su velocidad máxima y se deslizan levemente al frenar.
* **Salto y Aleteo:** Salto de altura variable dependiendo de cuánto tiempo se mantenga presionado el botón. En el aire, se puede "aletear" para planear ligeramente o ralentizar la caída.
* **Agacharse y Deslizarse:** Moverse mientras se está agachado. Si se corre y se pulsa abajo, el pato se desliza, reduciendo su hitbox, manteniendo la inercia y pasando por huecos pequeños.
* **Ragdoll (Hacerse el muerto):** Un botón permite que el pato pierda toda tensión muscular (ragdoll physics). Es útil para esquivar balas altas, pasar por espacios estrechos con inercia, o simplemente fingir la muerte.
* **Recoil (Retroceso):** Disparar armas potentes empuja al pato hacia atrás, lo cual se puede usar para movilidad (ej. disparar hacia abajo con un trabuco para volar).

## 4. Mecánicas de Combate y Armas
El combate es letal; cualquier daño resulta en la muerte instantánea.
* **Apuntado (Aiming):** El apuntado es principalmente horizontal. El ángulo cambia automáticamente dependiendo del arma (ej. las pistolas disparan recto, las granadas se lanzan en arco). Algunas armas (como el rifle de francotirador) permiten ajustar el ángulo de tiro preciso.
* **Munición Limitada y Recarga:** La mayoría de las armas tienen munición muy limitada. Algunas requieren "recarga" manual entre disparos (como la escopeta o el mosquete).
* **Desarme:** Si un pato es golpeado por un objeto contundente, lanzado, o pisa una cáscara de plátano, soltará el arma que lleva equipada.
* **Interacción Física:** Las armas también son objetos físicos. Se pueden lanzar a otros jugadores para desarmarlos o aturdirlos.

## 5. Sprites y Animación (Estilo Visual)
* **Resolución:** Estilo pixel art de baja resolución (usualmente reescalado), lo que permite que la acción sea clara incluso cuando la cámara se aleja para mostrar todo el mapa.
* **Animaciones Clave:** 
    * `Idle` (Respiración leve)
    * `Run` (Ciclo de correr exagerado, brazos moviéndose)
    * `Jump` / `Fall`
    * `Slide` (Deslizamiento en el suelo)
    * `Quack` (Abre el pico, usualmente emite partículas o sonido)
    * `Dead` (Sprite quemado, o ragdoll del cuerpo dividido en partes)
* **Modularidad (Componentes):** El cuerpo del pato suele ser la base. Las armas se renderizan como sprites independientes que se dibujan en las manos del pato. En GameMaker, esto se maneja dibujando el arma en las coordenadas exactas de las manos y ajustando la rotación (`image_angle`) según hacia dónde mire el jugador (`image_xscale`).

## 6. Iluminación y Efectos (VFX)
Aunque Duck Game parece simple, usa efectos visuales muy efectivos y responsivos:
* **Iluminación Dinámica Simple:** En ciertos mapas oscuros o con ciertas armas (ej. lásers, fuego), se utiliza un sistema de luces 2D básico (usando modos de mezcla o "blend modes" como `bm_add` en GameMaker sobre una capa oscura) para resaltar proyectiles o explosiones.
* **Partículas:** Uso intensivo de partículas simples: humo de los disparos, chispas, casquillos de bala que rebotan en el suelo, y plumas volando cuando un pato muere.
* **Interacción y Destrucción:** Cristales que se rompen en múltiples fragmentos físicos, puertas que se astillan, cajas y barriles que explotan dejando marcas de quemaduras en el fondo.

## 7. Diseño de Niveles
* **Pantalla Única (Cámara Dinámica):** La mayoría de los mapas están diseñados de forma que la cámara hace zoom in/out para mantener a todos los jugadores a la vista. 
* **Wraparound (Bucle de pantalla):** En muchos mapas, salir por el borde izquierdo te hace aparecer por el derecho, y caer por el límite inferior te hace aparecer cayendo desde arriba (efecto Pac-Man).
* **Plataformas "Jump-Through":** Plataformas sólidas desde arriba pero que se pueden atravesar desde abajo. Son absolutamente esenciales para la movilidad vertical fluida.

## 8. Recomendaciones para GameMaker
* **Máquina de Estados (State Machine):** Estructura el código del jugador usando una máquina de estados para separar la lógica de estar de pie, en el aire, deslizando, o en modo ragdoll.
* **Físicas y Colisiones:** Para el movimiento del jugador, es mejor programar tus propias físicas de colisión rectangulares (usando `place_meeting`) para tener un control estricto, en lugar de usar el motor Box2D integrado, que puede sentirse "resbaladizo". Sin embargo, el motor de físicas Box2D de GM es excelente para los objetos sueltos (armas tiradas) y el ragdoll.
* **Herencia de Objetos (Parenting):** Crea un objeto padre `obj_arma_parent` y hereda de él para cada tipo de arma (`obj_pistola`, `obj_escopeta`). Así puedes programar la recolección, lanzamiento y descarte de armas con un solo bloque de código en el jugador.
* **Optimizaciones de Sprites:** Divide los sprites del pato en cabeza (para los sombreros), cuerpo y armas para facilitar la animación procedural (cambiar el ángulo del brazo apuntando independientemente del cuerpo).
