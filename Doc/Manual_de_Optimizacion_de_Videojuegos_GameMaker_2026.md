# Manual de Optimización de Videojuegos en GameMaker (2026)

**Motor de referencia:** GameMaker LTS 2026 — IDE 2026.0.0.16 / Runtime 23 (GMS2 VM, GMS2 YYC y el nuevo GMRT en Beta)

**Índice**
1. [Introducción](#introducción)
2. [Arquitectura de un videojuego](#arquitectura-de-un-videojuego)
3. [Perfilado de rendimiento (Profiling)](#perfilado-de-rendimiento-profiling)
4. [Optimización de CPU](#optimización-de-cpu)
5. [Optimización de GPU](#optimización-de-gpu)
6. [Gestión de memoria](#gestión-de-memoria)
7. [GameMaker LTS 2026 (IDE 2026.0.0.16)](#gamemaker-lts-2026-ide-202600016)
8. [Patrones de optimización](#patrones-de-optimización)
9. [Casos prácticos](#casos-prácticos)
10. [Comparativa de runtimes: VM vs YYC vs GMRT](#comparativa-de-runtimes-vm-vs-yyc-vs-gmrt)
11. [Checklists](#checklists)
12. [Conclusiones](#conclusiones)
13. [Glosario](#glosario)
14. [Bibliografía y Referencias](#bibliografía-y-referencias)

## 1. Introducción

La **optimización moderna** de videojuegos busca maximizar el rendimiento de la aplicación en CPU, GPU y memoria, garantizando estabilidad de framerate y eficiencia energética. En lugar de fijarse únicamente en los FPS (fotogramas por segundo), se emplea el **tiempo de cuadro (frame time)** medido en milisegundos para fijar presupuestos temporales por fotograma. Por ejemplo, a 60 FPS el presupuesto es ~16.66 ms por frame. Un objetivo de optimización común es mantener cada frame por debajo de dicho límite para evitar *hitches* o caídas de rendimiento visibles.

- **Frame Time (tiempo de cuadro):** tiempo que tarda un fotograma completo en procesarse (Step + Draw). GameMaker desglosa esto en el Debug Overlay y en el Profiler; usar frame time en lugar de FPS es preferible, ya que FPS es un valor no lineal y engañoso.
- **FPS (fotogramas por segundo):** indica cuántos cuadros se dibujan por segundo. Es útil para el público, pero poco preciso para optimización detallada. Un aumento de FPS pequeño puede representar un gran cambio de tiempo por cuadro.
- **CPU-bound:** situación en la que el tiempo de CPU domina el tiempo de cuadro. En GameMaker esto suele significar que el evento **Step** (lógica, colisiones, GML) tarda más que el evento **Draw**. Si el cálculo de CPU excede el presupuesto, el juego es *CPU-bound* y debe optimizarse el código GML o migrarse a YYC.
- **GPU-bound:** cuando el procesamiento gráfico domina (Draw > Step). Suele deberse a demasiados *draw calls*/swaps de textura, shaders costosos o *overdraw* de superficies transparentes.
- **Memory-bound:** cuando el acceso a memoria (RAM o VRAM/texturas) limita el rendimiento. En GameMaker, esto se traduce típicamente en demasiadas texture pages activas a la vez o *surfaces* grandes sin liberar.
- **IO-bound:** relacionado con entrada/salida (carga desde disco, streaming de archivos, `buffer_load`/`sprite_add` en tiempo de ejecución). Si la lectura/escritura de datos masivos es el cuello de botella, ni CPU ni GPU lo están, sino la IO.

Una optimización integral debe considerar **cuándo aplicar** cada técnica (p.ej. desactivar instancias fuera de cámara cuando hay muchos objetos invisibles) y **cuándo no** (no forzar agrupación de texturas si el juego ya rinde bien). Se discutirá cada caso junto a sus **ventajas, desventajas y coste en CPU/GPU/memoria**. Donde sea útil, incluiremos ejemplos de código en **GML** (compatible con GMS2 VM y GMS2 YYC) para ilustrar los conceptos.

## 2. Arquitectura de un videojuego

Todo videojuego moderno gira en torno a bucles (loops) sincronizados con el hardware:

- **Main Loop (bucle principal):** ciclo base del juego. En GameMaker, el *runner* ejecuta, por cada instancia activa y en orden de *depth*/evento, los eventos **Begin Step → Step → End Step**, seguidos de colisiones y del evento **Draw**. No existe un `MainLoop` expuesto al usuario como en otros motores: el bucle es gestionado internamente por el runtime (VM o YYC) y solo se observa indirectamente a través del Profiler y el Debug Overlay.
- **Render Loop (bucle de renderizado):** se encarga de enviar comandos de dibujo al GPU. En GameMaker corresponde al evento **Draw** (y sus variantes Draw GUI, Draw Begin/End, Pre/Post Draw). La preparación (qué dibujar, en qué orden, con qué *blend mode*/textura) ocurre en CPU; la ejecución real la hace la API gráfica subyacente (Direct3D en Windows/Xbox, Vulkan/OpenGL en Linux/Android, Metal en macOS/iOS/consolas).
- **Physics Loop:** GameMaker no impone un paso de física fijo separado por defecto: el movimiento y las colisiones ocurren dentro del Step normal. Si un proyecto usa la extensión de física (Box2D integrado) o un motor de físicas propio, conviene fijar un *timestep* constante y sincronizarlo con el Step para evitar inestabilidad.
- **Pipeline gráfico moderno:** GameMaker abstrae casi todo el pipeline (ensamblado de vértices, shaders de vértice/fragmento, rasterización) detrás de funciones como `draw_sprite`, `draw_primitive_begin` o los *vertex buffers* personalizados. Solo cuando se trabaja con shaders (`shader_set`) o buffers de vértices propios se interactúa directamente con las etapas de *Vertex Processing* y *Fragment Processing*.
- **Sincronización CPU/GPU:** la CPU (evento Draw) prepara comandos de dibujo agrupados en **batches** y la GPU los ejecuta. GameMaker agrupa automáticamente llamadas consecutivas que comparten textura y estado de blend/dibujo en un solo *batch*; cada cambio de textura, *surface* o *blend mode* fuerza un **swap** que corta el batch. Este mecanismo (visible en el contador de *draw calls*/batches del Debug Overlay) es el equivalente práctico, en GameMaker, a la gestión de *fences* y *stalls* CPU/GPU de motores de más bajo nivel.

A nivel de hilos, la ejecución de GML en GMS2 VM y GMS2 YYC ocurre fundamentalmente en un **hilo principal**; GameMaker no expone un *Job System* genérico como Unity DOTS o el Task Graph de Unreal. El motor sí usa hilos internos para tareas concretas (carga de audio, ciertas operaciones de red y archivo mediante **eventos asíncronos**, y para la compilación/depuración de YYC), pero el código de juego del usuario se ejecuta de forma esencialmente secuencial. Esto hace que repartir trabajo pesado a lo largo de varios frames (en lugar de un solo Step) sea, en la práctica, la principal herramienta de "paralelismo" disponible en GML puro.

## 3. Perfilado de rendimiento (Profiling)

Antes de optimizar, es esencial **medir y diagnosticar**. Usar un profiler revela los cuellos de botella y evita el *optimizar por intuición*. Entre las herramientas clave:

- **El Profiler de GameMaker (Debugger → Profiler):** integrado en el IDE 2026. Muestra el tiempo por evento, script y función, tanto en modo **Top Down** (jerarquía de llamadas, similar al call stack) como **Bottom Up**. Puede filtrarse para mostrar solo **My Code** (tu GML), **Engine** (llamadas internas del runtime, incluyendo cuánto tiempo se pasa en `Finish_Frame`, es decir, "dormido" esperando al siguiente frame) o **Combined**. Un interruptor permite alternar entre **tiempo absoluto** (microsegundos totales) y **tiempo/llamadas promedio por step**. *Importante:* la comunidad de GameMaker señala que el porcentaje relativo que muestra el Profiler puede ser poco fiable en ciertos escenarios; es preferible fijarse en los tiempos absolutos en microsegundos antes que en el "%".
- **El Debug Overlay:** ventana en tiempo real (accesible durante la ejecución en modo debug) con una pestaña de **Memory** que grafica la memoria Allocated/Free del proceso y estadísticas del **Garbage Collector**, y otra de **Update** que muestra el tiempo invertido en el bucle de Step. Es la forma más rápida de detectar picos de memoria o de tiempo de frame sin necesidad de herramientas externas.
- **El Debugger (ventana de Buffers y Watches):** permite pausar la ejecución, inspeccionar structs, arrays y estructuras de datos en las variables observadas (*Watches*), y examinar el contenido crudo de un `buffer` como si fuera un editor hexadecimal. Útil para depurar *IO-bound* o serialización.
- **RenderDoc:** capturador de frames gráfico (open-source), utilizable contra el ejecutable exportado de GameMaker en plataformas Direct3D/Vulkan/OpenGL para inspeccionar el estado de GPU por draw call: geometrías, texturas, shaders y cuántas veces se invocan por píxel. Muy útil para depurar *overdraw* o ineficiencias de batching que el Debug Overlay no detalla.
- **Microsoft PIX:** (Windows/Xbox) para depurar builds YYC/GMRT en Direct3D12 cuando se necesita más detalle del que da el Profiler interno.
- **NVIDIA Nsight Graphics:** para D3D, Vulkan, OpenGL; permite depurar GPU frame por frame en exportaciones a PC.
- **Tracy:** profiler externo de código abierto y bajo overhead; puede integrarse mediante extensiones nativas/DLL en proyectos YYC que necesiten instrumentación fuera de lo que ofrece el Profiler de GameMaker.
- **Radeon GPU Profiler (RGP) / GPUView:** herramientas de bajo nivel (AMD/Windows SDK) para casos avanzados de builds nativas en PC.

### Cómo interpretar resultados en GameMaker

Se deben comparar los tiempos de **Step** y **Draw** por frame usando el Profiler o el Debug Overlay. Si el tiempo de Step es alto y el de Draw es bajo, el problema es de CPU (lógica GML, colisiones, IA); optimizar shaders o texturas no ayudará. Si, en cambio, Draw domina, hay que revisar cuántos *swaps de textura* y *batches* se están generando, el coste de shaders o el uso de *surfaces*. Si el tiempo restante lo consume "esperar" (visible como tiempo alto en `Finish_Frame` dentro del Profiler en modo Engine), el juego va sobrado y probablemente está limitado por VSync, no por CPU/GPU.

### Errores comunes de perfilado en GameMaker

- **Perfilar solo en el editor / con GMS2 VM:** los tiempos en VM (usado durante el desarrollo porque soporta el Debugger y el Profiler completos) pueden diferir mucho de los tiempos reales en YYC o en un dispositivo móvil/consola. Siempre valida el rendimiento final en una build YYC (o GMRT) en el hardware objetivo.
- **Confiar en el porcentaje del Profiler en vez del tiempo absoluto:** como se indicó arriba, el cálculo de "%" puede distorsionar la lectura; compara microsegundos.
- **No desactivar VSync al medir:** el ajuste de sincronización vertical (en las opciones del juego/room) puede ocultar el rendimiento real; para medir con precisión, desactívalo temporalmente.
- **No aislar variables:** cambiar múltiples cosas a la vez (texturas, colisiones, shaders) sin aislar, hace difícil saber qué optimización surtió efecto.
- **Olvidar limpiar la caché de YYC:** el módulo YYC a veces no detecta todos los archivos cambiados; si los tiempos de una build no coinciden con lo esperado tras editar código, usa el botón "Clean Cache" del IDE para forzar una recompilación completa antes de sacar conclusiones.

En resumen, el flujo típico es medir escenario base (con el Debug Overlay o el Profiler), identificar "hot spots" y luego optimizar una parte a la vez, volviendo a medir —idealmente en una build YYC representativa del producto final.

## 4. Optimización de CPU

La CPU (evento Step) realiza lógica de juego, colisiones, IA, y preparación de la escena antes de que la GPU la dibuje. Técnicas importantes:

- **Localidad de datos y caché:** organizar la memoria para reducir *cache misses*. En GML esto se traduce en preferir **arrays** (contiguos en memoria) sobre estructuras de datos legacy con punteros/índices dispersos como `ds_list`. *Data-Oriented Design* (DoD) enfatiza almacenar datos relacionados juntos; en GameMaker un array de structs (o, mejor aún, arrays paralelos con un valor por atributo) suele iterar más rápido que muchas instancias u objetos individuales.
- **Branch Prediction:** las ramas condicionales impredecibles penalizan porque desbaratan el pipeline del procesador. Siempre que sea posible, sustituye cadenas largas de `if`/`switch` sobre datos frecuentes por tablas precomputadas (arrays indexados) o expresiones matemáticas.
- **Variables locales en YYC:** si un script o bloque de código referencia variables globales o de instancia varias veces, asígnalas primero a una **variable local** al inicio del bloque y usa esa copia local en el resto del código. En GMS2 YYC esto mejora notablemente el rendimiento, ya que el acceso a variables locales es más barato que resolver variables globales/de instancia repetidamente.
- **Arrays: reservar tamaño desde el inicio:** al crear un array, usa `array_create(n)` para reservar de una vez el tamaño máximo esperado, en lugar de ir haciéndolo crecer elemento a elemento. Cada crecimiento incremental obliga a GameMaker a reasignar toda la memoria del array de nuevo; reservarlo en un solo bloque (con valores por defecto en 0) es mucho más rápido.
  ```gml
  // Mal: crece el array en cada iteración
  var lista = [];
  for (var i = 0; i < 100; i++) {
      array_push(lista, 0);
  }

  // Bien: reserva de una vez el tamaño máximo conocido
  var lista = array_create(100, 0);
  ```
- **Structs y arrays vs `ds_list`/`ds_map`:** el manual de GameMaker recomienda usar **structs y arrays** por encima de las estructuras de datos "ds_*" heredadas, ya que ofrecen funcionalidad similar, son más fáciles de usar y **se recogen automáticamente por el recolector de basura (GC)**. Las `ds_*` requieren destrucción manual (`ds_list_destroy`, `ds_map_destroy`, etc.) y, si se olvida, provocan fugas de memoria; además, en comparativas de comunidad, las operaciones sobre arrays suelen superar a las equivalentes en `ds_list` por un margen notable. Reserva las estructuras `ds_*` para los casos donde de verdad necesites su API específica (p.ej. `ds_grid` para colisiones en cuadrícula, ver más abajo).
- **Cuidado con las funciones funcionales de arrays (`array_reduce`, `array_map`, `array_filter`, `array_foreach`) en YYC:** en **GMS2 VM** estas funciones suelen ser más rápidas que un bucle `for` manual equivalente. En **GMS2 YYC**, sin embargo, la relación se invierte: un bucle `for` puro compila a código nativo muy eficiente, mientras que las funciones de array tienen el coste añadido de invocar un callback en cada elemento. Si el proyecto se exporta en YYC (lo habitual para release), perfila ambos enfoques en el runtime final antes de asumir cuál es más rápido.
- **Object Pooling en GML:** evita crear (`instance_create_layer`) y destruir (`instance_destroy`) constantemente objetos de vida corta (balas, partículas de gameplay, enemigos reciclables). En su lugar, reutiliza instancias existentes desactivándolas con `instance_deactivate_object`/`instance_activate_object`, o mantén un array/struct-pool propio:
  ```gml
  // Pool sencillo de "balas" reutilizando instancias
  function obtener_bala() {
      var _bala = instance_find(obj_bala_inactiva, 0);
      if (_bala != noone) {
          instance_change(_bala, obj_bala, false);
          return _bala;
      }
      return instance_create_layer(x, y, "Balas", obj_bala);
  }
  ```
- **Colisiones y desactivación por distancia:** para rooms grandes, desactiva instancias fuera del área relevante (p.ej. fuera de la vista de cámara) con `instance_deactivate_region`/`instance_activate_region`, o usa el ajuste **"Use Fast Collision System"** de las opciones del juego, que aplica una estructura tipo *spatial hash* internamente para reducir el número de comparaciones de colisión frente al método por fuerza bruta.
- **Sin Job System nativo:** al no existir un sistema de hilos de trabajo general en GML (ver sección 2), la forma habitual de "paralelizar" trabajo pesado en GameMaker es **repartirlo en varios steps** (procesar, por ejemplo, solo una fracción de la IA de enemigos por frame usando un contador rotatorio), delegar tareas de IO/red a los **eventos asíncronos** (que sí corren en segundo plano) o, en casos extremos, recurrir a extensiones nativas (DLL/GML extension) escritas en C/C++ para cómputo paralelo real.
- **Alineación y layout de datos:** en GML no se controla la alineación de memoria a bajo nivel como en C++, pero el mismo principio aplica a nivel de diseño: agrupa en un struct o array los datos que se leen/escriben juntos con frecuencia (por ejemplo, posición y velocidad de un proyectil) en lugar de dispersarlos en variables de instancia sueltas o en múltiples `ds_map` distintos.

En conjunto, la teoría (localidad de caché, evitar reasignaciones, minimizar el uso de `ds_*`) siempre debe aplicarse con experimentación en cada proyecto y, sobre todo, **medirse en YYC**, ya que el comportamiento relativo de ciertas técnicas (como las funciones de array) puede invertirse entre GMS2 VM y GMS2 YYC.

## 5. Optimización de GPU

En GameMaker, el GPU ejecuta lo que se envía desde el evento Draw: sprites, primitivas, superficies (*surfaces*) y shaders. Los puntos clave:

- **Texture Pages (páginas de textura) y batches:** GameMaker empaqueta los sprites y fuentes del proyecto en **texture pages** (atlas de texturas) en tiempo de compilación. Dibujar varios sprites que comparten la misma texture page permite que GameMaker los agrupe en un solo **batch**; cambiar a un sprite de otra página, a una *surface*, o cambiar el modo de mezcla (`blend mode`) corta el batch y genera un **swap** (cambio de textura activa), que tiene coste real de CPU/GPU. El objetivo práctico es minimizar swaps, no eliminarlos del todo.
- **Texture Groups:** desde el editor de assets, se pueden agrupar manualmente sprites y fondos en **grupos de texturas** personalizados (en vez de dejar que GameMaker los reparta automáticamente), de forma que todos los gráficos usados en una room concreta terminen en la misma página. Esto reduce drásticamente los swaps de textura en esa room. Los grupos no usados se pueden liberar de la VRAM con `texturegroup_unload` y recargarse (para evitar parpadeos al primer uso) con las funciones de *prefetch* correspondientes en el Create Event de la primera instancia de la room.
- **Cuidado con crear sprites en tiempo de ejecución:** cargar assets externos o crear sprites dinámicamente con `sprite_add()` genera, cada vez, **una nueva texture page individual**. Si se hace con muchos assets (p.ej. 10 sprites cargados dinámicamente) se crean 10 páginas nuevas, disparando el número de swaps. Prefiere empaquetar los sprites en el proyecto (con su grupo de textura asignado) siempre que sea posible; reserva `sprite_add()` para contenido verdaderamente dinámico (mods, avatares de usuario, etc.).
- **Partículas y overlays "ocultos":** el sistema de partículas por defecto de GameMaker usa sus propios sprites, almacenados en una página de textura separada, lo que añade swaps adicionales si se combinan con gráficos de gameplay. El propio Debug Overlay, al estar activo, también añade un par de swaps/batches a los contadores — algo a tener en cuenta al comparar mediciones con overlay activo y sin él.
- **Funciones de dibujo "poligonal":** usar `draw_rectangle`, `draw_circle`, `draw_line` u otras primitivas sin sprite, o cambiar color/alpha mediante `draw_set_color`/`draw_text_color`, también puede forzar un cambio de contexto de dibujo y cortar el batch en curso; agrúpalas cuando sea posible.
- **Culling básico:** GameMaker no aplica frustum/occlusion culling automático más allá de no dibujar lo que está claramente fuera de la vista de la cámara si el código lo comprueba explícitamente. Comprobar manualmente si una instancia está dentro del rectángulo de la `view`/cámara actual antes de dibujarla (o desactivarla, ver sección 4) es la técnica estándar para reducir tanto Step como Draw en rooms grandes.
- **Surfaces:** dibujar a una `surface` (por ejemplo, para efectos de post-procesado o iluminación 2D) es potente pero costoso: consume VRAM adicional y cada cambio de "superficie activa" corta el batch en curso. Libera las superficies que ya no se usan con `surface_free` (especialmente al cambiar de room) para evitar fugas de VRAM; el motor puede recrearlas automáticamente si se pierden (p.ej. al minimizar la ventana), pero no cuentes con ello para gestionar memoria de forma proactiva.
- **Shaders y vertex buffers:** los shaders en GameMaker se escriben en **GLSL ES** (el lenguaje por defecto, multiplataforma) y GameMaker los traduce internamente a HLSL cuando el target es Windows/Xbox. Un shader es tan rápido como su versión GLSL ES lo permita: evita cálculos redundantes en el fragment shader y aprovecha el vertex shader para trabajo que solo necesita hacerse por vértice. Los **vertex buffers** personalizados (formatos de vértice a medida) solo aportan una mejora de rendimiento significativa cuando el número de vértices es alto (miles) y se reconstruyen pocas veces; para un puñado de sprites, `draw_sprite_ext`/`draw_primitive` son perfectamente adecuados y añadir un vertex buffer manual sería una optimización prematura.
- **No hay LOD, HLOD ni geometría virtual nativos:** a diferencia de motores 3D AAA, GameMaker no ofrece sistemas automáticos de *Level of Detail*, *Hierarchical LOD* ni *virtual texturing*. Si un proyecto necesita LOD (por ejemplo, un juego 3D con modelos importados), debe implementarse manualmente intercambiando el mesh/sprite dibujado según la distancia a la cámara.

En general, las optimizaciones de GPU en GameMaker giran casi siempre alrededor de **reducir swaps de textura** (agrupar assets en texture groups), **reducir el número de draw calls efectivos** (menos objetos individuales, más *surfaces*/tilesets reutilizados cuando tenga sentido) y **evitar overdraw** con capas transparentes innecesarias. Mide el impacto real con el contador de batches/swaps del Debug Overlay o con RenderDoc para verificar mejoras.

## 6. Gestión de memoria

Gestionar eficientemente RAM (y VRAM) es vital:

- **RAM vs VRAM:** en GameMaker, la VRAM está dominada por las **texture pages** cargadas y las *surfaces* activas; la RAM la ocupan structs, arrays, buffers y las estructuras `ds_*` que sigas usando. El Debug Overlay muestra la memoria "Allocated"/"Free" del proceso, pero no separa RAM de VRAM de forma explícita, así que conviene razonar por separado sobre ambas.
- **Recolector de basura (GC) automático:** structs y arrays se liberan automáticamente cuando ya no hay referencias a ellos, gracias al recolector de basura de GameMaker. Esto simplifica mucho la gestión de memoria frente a otros lenguajes, pero significa que crear y descartar muchos structs/arrays por frame genera presión sobre el GC; para código muy frecuente (cada Step, con cientos de instancias), prefiere reutilizar structs existentes (pooling) en vez de crearlos de nuevo cada vez.
- **Fugas por `ds_*` sin destruir:** si el proyecto todavía usa `ds_list`, `ds_map`, `ds_grid`, etc. (necesarios en algunos casos, como `ds_grid` para colisiones en cuadrícula), recuerda **destruirlos explícitamente** con su función `_destroy` correspondiente cuando ya no se necesiten, especialmente si viven dentro de un struct: al no ser recogidos por el GC, una instancia de struct destruida puede dejar "huérfana" una `ds_*` en memoria si no se limpia a mano en un método de limpieza propio.
- **Streaming de assets y Texture Groups:** en vez de cargar todo en memoria de golpe, organiza los assets en **Texture Groups** por room o por zona del juego, y libera con `texturegroup_unload` los grupos que ya no hacen falta al salir de una zona, recargando (prefetch) los del área nueva. Esto reduce picos de VRAM en juegos con muchas rooms/zonas distintas.
- **Compresión de assets (novedad LTS 2026):** desde la versión 2026.0, los paquetes de juego usan una variante del formato **QOI con compresión BZ2**, más pequeña que PNG — en las pruebas de YoYo Games, los paquetes resultantes ocupan alrededor del **80% del tamaño** que tendrían en 2023.7 (LTS 2022) — y de descompresión más rápida en tiempo de carga. Esto reduce tanto el tamaño de descarga como parte del coste de IO al arrancar el juego, sin que el desarrollador tenga que hacer nada adicional.
- **Gestión de assets y monitoreo:** GameMaker no incluye un "Memory Profiler" dedicado como Unity o Unreal; el monitoreo se apoya en la pestaña **Memory** del Debug Overlay (memoria asignada/libre y estadísticas del GC) durante pruebas, complementado si hace falta con herramientas externas de sistema operativo para medir el consumo total del proceso en el dispositivo objetivo.
- **IO y disco:** las operaciones de carga (`buffer_load`, `sprite_add`, `audio_create_stream`, peticiones de red) que puedan tardar deben lanzarse mediante los **eventos asíncronos** de GameMaker en lugar de bloquear el Step; así el resto del juego sigue respondiendo mientras la IO ocurre en segundo plano. Agrupar muchos archivos pequeños en un único paquete de datos (por ejemplo, un `buffer` serializado o un `.zip` leído con las funciones de archivo) también reduce el número de operaciones de disco individuales frente a cientos de archivos sueltos.

Una regla general: optimizar con datos reales de profiling. Por ejemplo, revisa cuántas texture pages están activas simultáneamente en la escena más pesada del juego y ajusta los Texture Groups para que el consumo de VRAM se mantenga por debajo del límite razonable para la plataforma objetivo (los presupuestos son especialmente estrictos en móviles y en el target HTML5/GX.games).

## 7. GameMaker LTS 2026 (IDE 2026.0.0.16)

> *Sección dedicada específicamente a la versión que estás usando: GameMaker LTS 2026, IDE 2026.0.0.16.*

LTS 2026.0 es, según YoYo Games, la versión que concentra el desarrollo principal del motor de aquí en adelante (sustituyendo a la antigua LTS 22.3 como rama estable de referencia). Es una instalación completamente nueva y separada de instalaciones anteriores, por lo que conviene respaldar/usar control de versiones antes de migrar un proyecto existente.

### VM, YYC y el nuevo GMRT

Con esta versión, YoYo Games renombró los runtimes existentes para diferenciarlos del nuevo runtime en desarrollo:

- **GMS2 VM:** la Máquina Virtual clásica. Es el runtime que usas normalmente durante el desarrollo porque soporta el **Debugger** y el **Profiler** completos (pausar ejecución, inspeccionar variables, ver el call stack). Es más lenta en ejecución que YYC, pero el ciclo de iteración (compilar → probar) es mucho más rápido.
- **GMS2 YYC (YoYo Compiler):** compila el proyecto a un ejecutable nativo (C++ generado y compilado). Es el runtime recomendado para builds de rendimiento y para el release final. Compilar en YYC tarda más, y su soporte de depuración es más limitado que en VM (aunque se puede, en casos avanzados, generar el proyecto C++ y depurarlo con Visual Studio u otro IDE nativo).
- **GMRT (GameMaker Runtime) — Beta:** el nuevo runtime en desarrollo que eventualmente reemplazará a los targets "GMS2" actuales. LTS 2026.0 permite probarlo, pero al estar en beta puede no tener paridad de funciones ni la misma estabilidad; no se recomienda para producción todavía, aunque vale la pena vigilar su evolución si el proyecto tiene un ciclo de desarrollo largo.

Como referencia de rendimiento relativo entre VM y YYC: en la mayoría del código de gameplay, YYC suele ser entre **2 y 3 veces más rápido** que VM, aunque ambos siguen estando, en general, varias veces por detrás de una aplicación nativa en C++ equivalente (debido al sistema de tipos dinámico de GML y al overhead inherente incluso en operaciones simples como aritmética con variables). Existen además algunos casos concretos, poco frecuentes, donde YYC resulta más lento que VM (por ejemplo con ciertas funciones de array, como se explicó en la sección 4) — de ahí la importancia de perfilar en el runtime final antes de dar por buena una optimización.

### Cambio del compilador en 2026.0 (atención al migrar proyectos)

El compilador de 2026.0 ahora **optimiza las llamadas a función cuando el script puede resolverse directamente**, evitando el overhead de la resolución dinámica habitual de GML. Esto es una mejora de rendimiento, pero introduce un cambio de comportamiento importante si tu código depende de **herencia con sobrescritura de funciones entre objeto padre e hijo** (por ejemplo, `funcionA` en el padre llama a `funcionB`, y un objeto hijo sobrescribe `funcionB` antes de llamar a `funcionA`). Si tu proyecto usa este patrón, la función padre debe declararse como **método** (`funcionA = function() {}`) en vez de como función tradicional (`function funcionA() {}`) para seguir comportándose como antes. Si migras un proyecto grande desde una LTS anterior, revisa este punto explícitamente antes de dar por válidos los resultados de tus mediciones de rendimiento.

### Otras novedades relevantes para rendimiento y flujo de trabajo

- **Compatibilidad nativa con Mac Apple Silicon:** tanto las builds VM como YYC pueden ejecutarse de forma nativa en simuladores/Macs con chips M-series (antes solo Intel funcionaba sin capas de traducción), lo que mejora el rendimiento de pruebas en ese hardware.
- **Compresión de paquetes QOI + BZ2:** ver sección 6 — paquetes más pequeños y de descompresión más rápida por defecto.
- **GX.games actualizado:** el target GX.games ahora soporta exportar *Game Strips* y *fondos de pantalla interactivos (Live Wallpapers)*, además de exportar la build WASM como ZIP.
- **Guías de SDK centralizadas:** las guías de configuración por plataforma se movieron a la GameMaker Wiki (también accesibles desde `Help > Required SDKs` en el IDE); revísalas tras instalar 2026.0, ya que los requisitos de algunos targets cambiaron respecto a LTS 22.3.
- **Runtime Modules:** un nuevo diálogo permite elegir qué runtimes (VM/YYC/GMRT, por plataforma) se descargan al instalar, y el Target Manager muestra íconos de estado para saber qué runtimes ya tienes instalados — útil para no descargar módulos de plataformas que no vas a exportar.

### Resumen de buenas prácticas oficiales para GML

- Cachea variables globales/de instancia usadas varias veces en un bloque en una variable **local**, especialmente pensando en YYC.
- Reserva arrays a su tamaño máximo con `array_create()` en vez de dejarlos crecer elemento a elemento.
- Prefiere **structs y arrays** sobre `ds_list`/`ds_map` salvo que necesites una API específica de estructuras de datos.
- No sobre-optimices código que ya rinde bien: mide primero, y trata estas recomendaciones como guías, no como reglas absolutas — la legibilidad y mantenibilidad del código siguen importando.

## 8. Patrones de optimización

Algunos **patrones de diseño** clásicos, adaptados a GML, ayudan a optimizar:

- **Object Pool (Pool de Objetos):** reutilizar instancias en lugar de crear (`instance_create_layer`) y destruir (`instance_destroy`) continuamente. Sirve para balas, partículas de gameplay, enemigos reciclables. En GameMaker se implementa reactivando instancias desactivadas (`instance_activate_object`) o gestionando un array/struct-pool propio, como se mostró en la sección 4.
- **Flyweight:** compartir datos inmutables entre objetos — por ejemplo, muchas instancias que usan el mismo sprite (y por tanto la misma texture page) en vez de sprites duplicados por instancia. Agrupar visuales compartidos en el mismo Texture Group es la forma más directa de aplicar este patrón en GameMaker.
- **"ECS" ligero en GML:** GameMaker no incluye un Entity-Component-System nativo como Unity DOTS. Si un proyecto necesita procesar miles de entidades de forma muy eficiente, la aproximación habitual en la comunidad es simular un enfoque orientado a datos con **arrays paralelos de structs** (posiciones, velocidades, estados en arrays separados) en lugar de una instancia de objeto GameMaker por entidad, reservando las instancias de objeto para elementos que realmente necesiten eventos individuales (Step/Draw/colisión propios).
- **Spatial Hash / Grid:** dividir el espacio en celdas para consultas rápidas de vecinos (colisiones, IA). En GameMaker puede implementarse con `ds_grid` (almacenando qué hay en cada celda) o con un spatial hash propio sobre un `ds_map`/struct; es la base, de hecho, del ajuste **"Use Fast Collision System"** de las opciones del juego. Muy recomendable en juegos con cuadrículas de bloques densas (tipo Terraria), donde comprobar colisión bloque a bloque con cientos de instancias individuales cae fácilmente a un dígito bajo de FPS.
- **Octree/Quadtree/BVH mediante extensiones:** GameMaker no trae estas estructuras integradas, pero existen bibliotecas de la comunidad (por ejemplo, sistemas de colisión 3D basados en octrees, quadtrees y spatial hashes, o incluso usando las propias instancias de GameMaker como "broadphase" de colisión — un enfoque que, según pruebas de terceros, ha llegado a medirse hasta 10 veces más rápido que un octree/quadtree propio en ciertos escenarios). Vale la pena evaluar extensiones existentes antes de reimplementar estas estructuras desde cero.
- **Diseño Orientado a Datos (Data-Oriented Design):** en GML, prioriza arrays de datos primitivos/structs simples sobre jerarquías profundas de objetos con muchas variables de instancia dispersas, especialmente en los sistemas que iteran cientos o miles de elementos cada Step.
- **LOD manual:** GameMaker no ofrece LOD automático (ver sección 5); si es necesario, intercambia manualmente el sprite/mesh dibujado según distancia a cámara desde el propio evento Draw.

Cada patrón se aplica según necesidad: un juego tipo *bullet hell* se beneficia enormemente de Object Pool, mientras que un juego de bloques/mundo tipo Terraria necesita, casi obligatoriamente, algún tipo de Spatial Hash/Grid para colisiones.

## 9. Casos prácticos

A continuación se analizan géneros habituales en GameMaker, indicando técnicas típicas de optimización:

- **Bullet Hell:** miles de proyectiles en pantalla. Foco principal: **Object Pool** para las balas, todos los sprites de proyectiles en el mismo Texture Group para minimizar swaps, colisiones simplificadas (círculos/`place_meeting` con máscaras pequeñas) y arrays/structs (no `ds_list`) para llevar el estado de cada proyectil activo. Evitar crear structs nuevos cada Step reutilizando los del pool.
- **Plataformero/RPG 2D:** resolución de píxel fijo, sprites 2D. Optimización: Texture Groups por zona para reducir swaps, *tilesets* (capas de Tile Layer) en vez de una instancia de objeto por bloque decorativo, desactivar instancias fuera de la vista de cámara con `instance_deactivate_region`, y colisiones simplificadas con `place_meeting`/`move_and_collide` en vez de física compleja si no hace falta.
- **Juego basado en cuadrícula/mundo destructible (tipo Terraria):** el caso clásico que satura el motor si cada bloque es una instancia individual. Solución: almacenar el mundo en un `ds_grid` o array 2D con el tipo de bloque, dibujar por bloques agrupados en superficies/capas reutilizadas en lugar de una instancia por celda, y usar Spatial Hash/`ds_grid` para las consultas de colisión del jugador contra el terreno cercano en vez de comprobar contra todas las instancias del mundo.
- **Roguelike / niveles procedurales en tiles:** foco en generación rápida de mapas con presupuesto de memoria bajo. Los mapas tile-based permiten usar Spatial Hash/`ds_grid` y arrays para colisiones, y cargar/generar assets por demanda entre pisos/niveles, liberando Texture Groups del piso anterior si el arte cambia mucho entre niveles.
- **Juego 3D en GameMaker:** el soporte 3D de GameMaker es de bajo nivel (matrices, primitivas y vertex buffers manuales; no hay un renderer 3D "completo" con iluminación, sombras o LOD automáticos de fábrica). Proyectos 3D dependen mucho de shaders propios y, a menudo, de extensiones/bibliotecas de la comunidad para colisiones 3D, iluminación o gestión de mallas. Al optimizar, el cuello de botella suele estar en el número de `draw_primitive`/vertex buffers distintos por frame más que en técnicas avanzadas de motor (no hay Nanite/Lumen equivalentes disponibles).
- **Mobile:** presupuestos estrictos de CPU/GPU y batería. Claves: Texture Groups ajustados para minimizar VRAM y swaps, reducir *overdraw* (transparencias apiladas), evitar crear sprites en tiempo de ejecución, y perfilar en el dispositivo real (con una build YYC exportada, no en el editor con VM) ya que el rendimiento entre ambos puede diferir mucho.
- **Networking:** GameMaker ofrece funciones de red y buffers propios (`network_*`, `buffer_*`) para sockets TCP/UDP. Minimiza el tamaño de los paquetes serializando con buffers binarios en vez de strings/JSON cuando el volumen de tráfico sea alto, y limita la frecuencia de envío de actualizaciones de estado a lo estrictamente necesario en vez de enviar cada Step.
- **Multiplataforma (PC / Móvil / Consolas / Web-GX.games):** cada target de exportación de GameMaker tiene presupuestos distintos de VRAM y CPU. Ajusta el tamaño y compresión de los Texture Groups por plataforma desde las opciones de exportación, prueba builds YYC específicas de cada plataforma antes de publicar, y ten en cuenta que HTML5/GX.games añade restricciones adicionales de tamaño de descarga inicial (donde la nueva compresión QOI+BZ2 de 2026 ayuda directamente).

Cada caso práctico tiene soluciones comunes, pero deben adaptarse al juego concreto. La idea, como siempre, es identificar el principal limitador (Step vs Draw, CPU vs VRAM) con el Profiler/Debug Overlay y aplicar la técnica pertinente.

## 10. Comparativa de runtimes: VM vs YYC vs GMRT

En lugar de comparar GameMaker contra otros motores, esta sección compara los tres runtimes disponibles dentro de GameMaker LTS 2026, ya que la elección entre ellos es, en la práctica, la decisión de "motor de ejecución" más relevante para un proyecto en GameMaker:

- **Velocidad de ejecución:**
  - *GMS2 VM:* la más lenta de las tres opciones; adecuada para desarrollo e iteración, no para medir rendimiento final.
  - *GMS2 YYC:* entre 2x y 3x más rápida que VM en la mayoría del código GML típico; sigue siendo notablemente más lenta que C++ nativo equivalente debido al tipado dinámico de GML, pero es el estándar para builds de release.
  - *GMRT (Beta):* en desarrollo activo; su objetivo a futuro es sustituir tanto a VM como a YYC, pero en 2026.0 su rendimiento y cobertura de funciones todavía están madurando, por lo que no debe usarse como referencia de rendimiento de producción.
- **Velocidad de compilación/iteración:**
  - *VM:* compila casi instantáneamente; ideal para el ciclo editar-probar.
  - *YYC:* compila un proyecto C++ completo, por lo que tarda considerablemente más, sobre todo en proyectos grandes (aunque el sistema de caché evita recompilar todo si solo cambiaron unos pocos archivos).
  - *GMRT:* aún variable según el estado de la beta.
- **Herramientas de depuración:**
  - *VM:* soporte completo del Debugger y el Profiler del IDE (pausar, inspeccionar variables, call stack).
  - *YYC:* depuración más limitada dentro del IDE; para casos avanzados se puede generar el proyecto C++ y depurarlo con un IDE nativo (p.ej. Visual Studio) o con el propio Debug Overlay en tiempo de ejecución.
  - *GMRT:* herramientas de depuración todavía en desarrollo junto con el resto del runtime.
- **Soporte de plataformas:** VM y YYC cubren el conjunto completo de targets estables de GameMaker (Windows, macOS incluyendo M-series, Linux, iOS, Android, HTML5/GX.games y consolas bajo NDA). GMRT, al ser beta, puede no tener paridad de plataformas todavía.
- **Recomendación práctica:** desarrolla e itera en **VM** aprovechando el Debugger/Profiler completos; valida rendimiento y compila builds de release en **YYC**; evalúa **GMRT** en un entorno de pruebas aparte si el calendario del proyecto lo permite, pero sin depender de él para el lanzamiento mientras siga en beta.

## 11. Checklists

### Antes de optimizar
- **Definir objetivos claros:** FPS o latencia esperada, plataforma meta (móvil 30-60 fps vs PC 60 fps vs consola según requisitos del programa de certificación).
- **Instrumentación habilitada:** ejecutar en modo debug para tener acceso al Profiler y al Debug Overlay; para casos avanzados, tener RenderDoc/PIX/Nsight listos contra la build exportada.
- **Recopilar baseline:** medir el rendimiento actual (Step/Draw, memoria) en las rooms más exigentes del juego con el Debug Overlay. Establecer un *benchmark* de referencia.
- **Revisar código crítico:** identificar bucles sin límite claro, iteraciones sobre todas las instancias del juego, o `ds_*` sin destruir. Confirmar validación de datos de entrada (índices de array dentro de rango, división por cero, etc.).

### Antes de publicar
- **Pruebas en dispositivo/build real:** validar rendimiento en una build **YYC** (no en VM/editor) en cada plataforma final, observando caídas de frame y el contador de batches/swaps.
- **Presupuesto de memoria:** revisar VRAM (Texture Groups activos) y RAM (Debug Overlay) contra los límites de la plataforma; confirmar que no quedan `surface`/`ds_*` sin liberar entre rooms.
- **Texture Groups revisados:** confirmar que los assets de cada room/zona están agrupados para minimizar swaps, y que no se están creando texturas dinámicamente con `sprite_add()` de forma innecesaria.
- **Configuración por plataforma:** ajustar compresión y calidad de Texture Groups por target de exportación; en móvil, habilitar las arquitecturas estrictamente necesarias para no inflar el tamaño del paquete.

### Antes de perfilar
- **Desactivar VSync (si es posible):** para evitar que oculte el rendimiento real; recuerda reactivarlo después.
- **Limpiar la caché de YYC:** usa el botón "Clean Cache" del IDE antes de una medición importante en YYC, para asegurar que estás midiendo el código actual y no una build parcialmente desactualizada.
- **Cargar la room "peor caso":** la que tenga más instancias activas, más partículas o más texturas simultáneas.
- **Tener las herramientas listas:** proyecto en modo debug para acceso al Profiler/Debug Overlay; conectar el debugger remoto si se prueba en dispositivo móvil/consola.

### Antes de lanzar el juego
- **Pruebas de estrés:** dejar el juego corriendo un tiempo extendido en la plataforma más limitada (móvil) para detectar fugas de memoria progresivas (vigilar la gráfica de memoria del Debug Overlay) o *thermal throttling*.
- **Verificar objetivos de frame rate:** usar `game_set_speed`/los ajustes de FPS objetivo del proyecto para confirmar que el juego no excede innecesariamente los FPS deseados (lo contrario indica margen de CPU/GPU sin aprovechar o mal aprovechado).
- **Perfilar post-optimización:** medir de nuevo con el Profiler/Debug Overlay tras cada tanda de optimizaciones y comparar con el baseline original.
- **Checklist de requisitos de plataforma:** revisar las guías de SDK actualizadas en la GameMaker Wiki (`Help > Required SDKs`) para el target final, ya que los requisitos pueden cambiar entre versiones del IDE.

## Conclusiones

La optimización de videojuegos en GameMaker requiere el mismo enfoque holístico que en cualquier motor: **maximizar el rendimiento sujeto a los recursos disponibles**, manteniendo la calidad visual y jugable. Este manual ha recorrido las bases teóricas (frame time, Step vs Draw, CPU-bound vs GPU-bound), la arquitectura del bucle de GameMaker, el uso del Profiler y el Debug Overlay, técnicas específicas de CPU (locales en YYC, presizing de arrays, structs sobre `ds_*`) y de GPU (Texture Groups, swaps y batches, shaders GLSL ES), gestión de memoria (GC automático, compresión QOI+BZ2 de 2026), las particularidades de **GameMaker LTS 2026 (IDE 2026.0.0.16)** — incluyendo la diferencia entre GMS2 VM, GMS2 YYC y el nuevo GMRT en beta —, patrones de diseño adaptados a GML, casos prácticos por género, y checklists de buenas prácticas.

Lo más importante sigue siendo medir antes de asumir: **"lo que no se mide no se mejora"**. Cada optimización debe basarse en evidencia del Profiler o el Debug Overlay, y validarse en una build **YYC** representativa del producto final, ya que el comportamiento relativo de ciertas técnicas puede diferir entre VM y YYC. Con el conocimiento de este manual, podrás identificar cuellos de botella reales en tu proyecto de GameMaker y aplicar la técnica adecuada (agrupación de texturas, pooling de instancias, colisiones por cuadrícula, etc.) con criterio profesional.

## Glosario

- **Frame Time:** Tiempo (ms) que tarda un fotograma (Step + Draw) en procesarse.
- **FPS (Frames Per Second):** Cuadros por segundo. Métrica no lineal, mejor reemplazada por tiempo de cuadro.
- **CPU-bound/GPU-bound:** Términos que indican si el Step (CPU) o el Draw (GPU) está limitando el rendimiento actual.
- **GMS2 VM:** Máquina Virtual de GameMaker; runtime de desarrollo con Debugger/Profiler completos.
- **GMS2 YYC (YoYo Compiler):** Compila el proyecto a un ejecutable nativo; runtime recomendado para release.
- **GMRT (GameMaker Runtime):** Runtime de nueva generación en Beta desde LTS 2026, destinado a reemplazar a VM y YYC.
- **Texture Page:** Atlas de texturas donde GameMaker empaqueta sprites y fuentes.
- **Texture Group:** Agrupación manual de assets en una o varias texture pages específicas, para controlar swaps y VRAM.
- **Batch / Swap:** Un *batch* es un grupo de dibujos consecutivos que comparten textura/estado enviados juntos a la GPU; un *swap* es el corte de ese batch al cambiar de textura, surface o modo de mezcla.
- **Struct:** Tipo de dato de GML para agrupar variables relacionadas; se libera automáticamente por el recolector de basura.
- **Data Structures (`ds_*`):** Estructuras heredadas (`ds_list`, `ds_map`, `ds_grid`, etc.) que requieren destrucción manual; GameMaker recomienda structs/arrays salvo necesidad específica.
- **Debug Overlay:** Panel en tiempo de ejecución con información de memoria, GC y tiempo de Step.
- **LOD (Level of Detail):** Variantes simplificadas de un sprite/mesh según distancia; en GameMaker debe implementarse manualmente.
- **Occlusion Culling / Culling por cámara:** Técnica para no dibujar/actualizar objetos fuera de la vista; en GameMaker se implementa comprobando la `view` activa o desactivando instancias por región.
- **Data-Oriented Design (DoD):** Enfoque donde los datos se organizan en estructuras planas (arrays) optimizadas para acceso secuencial.
- **RenderDoc/PIX/Nsight:** Herramientas externas de perfilado gráfico de bajo nivel, usables contra builds exportadas de GameMaker en la API gráfica correspondiente.

## Bibliografía y Referencias

- GameMaker (YoYo Games) — *9 Essential Best-Practise Tips For Coding With GameMaker*.
- GameMaker (YoYo Games) — *How to optimise your games in GameMaker* (Texture Groups, swaps y batches).
- GameMaker Manual — *The Profiler* (IDE Tools / The Debugger).
- GameMaker Manual — *The Debug Overlay* (GML Reference / Debugging).
- GameMaker Manual — *The Debugger* y *Watches*.
- GameMaker Manual — *Data Structures* (recomendación de structs/arrays sobre `ds_*`).
- GameMaker Manual — *Shaders* y *Guide To Primitives And Vertex Building*.
- GameMaker Releases — *2026.0.0 Release Notes* (IDE 2026.0.0.16 / Runtime 23; renombrado VM/YYC; cambios del compilador; compresión QOI+BZ2).
- GameMaker (YoYo Games) — *GameMaker LTS 2026.0: New Features, GMRT and Much More* (blog oficial).
- JujuAdams — *painfully-learned-lessons* (GitHub): notas de rendimiento comparando VM y YYC, incluyendo el caso de las funciones de array.
- GM Shaders — *Tutoriales de shaders para GameMaker* (texturas, vertex/fragment shaders).
- Comunidad GameMaker (foro oficial) — hilos sobre optimización de texture swaps/batches y sobre el "Fast Collision System".
- Dragonite (itch.io) — devlogs de bibliotecas de colisión 3D para GameMaker (comparativa de instancias como broadphase vs octree/quadtree/spatial hash).

*Nota:* Este manual sustituye, respecto a versiones anteriores centradas en Godot/Unity/Unreal, las secciones específicas de motor por una cobertura dedicada a **GameMaker LTS 2026 (IDE 2026.0.0.16)**, manteniendo la teoría general de optimización (frame time, CPU/GPU/memory-bound, patrones de diseño) que es aplicable a cualquier motor.
