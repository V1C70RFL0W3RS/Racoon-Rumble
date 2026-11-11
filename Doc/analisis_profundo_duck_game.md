# 🦆 Análisis Profundo: Duck Game
> Documento de referencia técnica para desarrollo de juego inspirado en Duck Game con GameMaker.
> Investigado directamente desde los archivos del juego instalado en `/Duck Game/Content/` + fuentes online.

---

## 1. Motor y Arquitectura Técnica

Duck Game fue desarrollado en **MonoGame** (C#), reimplementación open-source del framework XNA de Microsoft.

| Aspecto | Detalle |
|---|---|
| **Motor** | MonoGame (XNA 4.0 API) |
| **Lenguaje** | C# |
| **Renderizado** | DirectX 9 (`D3DX9_41.dll`, `d3d9.dll`) |
| **Audio** | NAudio + NVorbis |
| **Input** | DGInput.dll (librería personalizada) |
| **Redes** | DGSteam.dll + código de red propio |
| **Formato de niveles** | `.lev` (binario propietario) |
| **Formato de sprites** | `.xnb` (XNA Binary — textura compilada) |
| **Shaders** | HLSL compilados a `.xnb` |

### Clase Base del Mundo: `Thing`
Del XML de documentación oficial del juego (`DuckGame.XML`) se extrae que **todo** en Duck Game hereda de la clase `Thing`:
```
"The base class for everything in Duck Game. Things can be added to
 the world with Level.Add and they will be drawn and updated automatically."
```
Equivalente a usar un **objeto padre** en GameMaker del que heredan todos los demás objetos.

---

## 2. El Jugador (El Pato) — Análisis Detallado

### 2.1 Sprites del Pato (Confirmados por archivos reales)

| Archivo `.xnb` | Descripción |
|---|---|
| `duck.xnb` | Sprite sheet principal del pato (148 KB — animación completa) |
| `duck_m.xnb` | Versión mirror/espejo del pato |
| `duckArms.xnb` | Sprite sheet de brazos (independiente del cuerpo) |
| `duckArms_m.xnb` | Brazos en mirror |
| `quackduck.xnb` | Animación de Quack (590 KB — la más pesada del personaje) |
| `quackduckOverlay.xnb` | Overlay adicional del quack |
| `controlledDuck.xnb` | Estado de control mental (con el casco) |
| `cookedDuck.xnb` | Sprite de pato muerto/quemado |
| `corpseLeft.xnb` | Cadáver mirando a la izquierda |
| `corpseRight.xnb` | Cadáver mirando a la derecha |
| `feather.xnb` / `feather_m.xnb` | Plumas al morir |
| `jimduck.xnb` | NPC pato presentador |
| `seatDuck.xnb` | Pato sentado (para la audiencia/crowd) |

> **Clave de diseño:** Los brazos (`duckArms.xnb`) son un sprite **completamente separado** del cuerpo. Permite rotar los brazos de forma independiente para apuntar armas en cualquier ángulo sin redibujar el cuerpo.

### 2.2 Modularidad del Pato — Capas de Renderizado

```
[Cape/Capa]  →  [Body/Cuerpo]  →  [Arms/Brazos]  →  [Hat/Sombrero]  →  [Held Weapon/Arma]
```

Capas confirmadas por sprites encontrados:
- **Capas:** `gereCape.xnb`, `plainCape.xnb`, `rainbowCape.xnb`, `moonCape.xnb`, `royalCape.xnb`, `waffleCape.xnb`, `devCape.xnb`
- **Posiciones de dedos:** `fingerPositions.xnb` y `fingerPositions_m.xnb` — la posición de los dedos en el arma es animada por separado

### 2.3 Estados del Jugador — State Machine Completa

```
IDLE
 ├─ WALK / RUN
 │    └─ SLIDE (agacharse en movimiento)
 ├─ JUMP
 │    ├─ FALL
 │    └─ FLAP (flotar/planeo en aire)
 ├─ CROUCH (agachado estático)
 ├─ RAGDOLL (hacerse el muerto — físicas libres)
 ├─ DEAD (muerto — sprite quemado, separado del ragdoll)
 └─ CONTROLLED (bajo control mental del Mind Control Gun)
```

### 2.4 Sistema de Sombreros — 93 Hats Confirmados

Se encontraron **93 archivos `.xnb`** en `/Content/hats/`:

`cowboys`, `dinos`, `divers`, `dapper`, `cyborgs`, `astrobud`, `katanaman`, `royalty`, `pilots`, `skelly`, `werewolves`, `wizbiz`, `moonwalker`, `sombrero`, `tricorne`, `frogs`, `eggy`, `jazzducks`, `master`, `FunnyMan`, `Dumplin`, `WELDER`, `agents`, `angrys`, `b52s`, `ballhead`, `bawb`, `bigearls`, `brick`, `broduck`, `burgers`, `caps`, `chancee`, `chancy`, `clams`, `cluehat`, `cyclops`, `dapper`, `dicks`, `divers`, `drunks`, `frank`, `fridge`, `frogs`, `funhat`, `gents`, `gross`, `guac`, `handy`, `hearts`, `highfives`, `joey`, `johnnys`, `kerchief`, `log`, `mailbox`, `mobby`, `motherduck`, `newrobo`, `noHat`, `officemen`, `oldrobo`, `pompadour`, `ponycap`, `pots`, `pulpy`, `reallife`, `retros`, `sailors`, `scurvies`, `senpaiStar`, `sensei`, `ski`, `suit`, `super`, `toeboys`, `toomany`, `tube`, `turing`, `twintail`, `ufos`, `uglies`, `valet`, `wahhs`, `witchtime` y más.

**Especiales:** `katanaman_lightmap.xnb` y `master_glow.xnb` — algunos sombreros tienen **su propio lightmap**, indicando que el juego renderiza luces adicionales encima de ciertos accesorios.

---

## 3. Físicas y Movimiento — Análisis Profundo

### 3.1 Sistema de Físicas Dual

Duck Game utiliza **dos sistemas de físicas simultáneos**:

1. **Físicas manuales (código custom):** Para el movimiento del jugador. Control total sobre aceleración, fricción, salto y colisiones. Garantiza sensación precisa y responsiva.

2. **Físicas de motor:** Para objetos sueltos — armas tiradas, casquillos de bala, fragmentos de madera, cuerpos en ragdoll.

Confirmado con la clase `PhysicsMaterial` del XML del juego:
```
"Represents a material type given to physics objects, and changes how they
 interact with the world (metal objects become too hot to hold under heat,
 paper/wood burns, etc)."
```

### 3.2 Materiales Físicos (PhysicsMaterial)

| Material | Propiedad especial |
|---|---|
| Metal | Se calienta bajo calor/fuego — quema al sostenerlo |
| Madera/Papel | Se quema con fuego o laser |
| Hielo | Fricción reducida, se rompe al impactar |
| Lava | Mata instantáneamente al contacto |

Evidenciado por sprites: `lava.xnb`, `iceBlock.xnb`, `burn.xnb`, `frozen.xnb`, `redHot.xnb`.

### 3.3 Valores Estimados de Movimiento

| Variable | Valor estimado | Nota |
|---|---|---|
| Velocidad máxima X | ~5–7 px/frame | Alta para plataformero |
| Aceleración en suelo | ~1.5 px/frame² | Sensación de "arranque" |
| Fricción en suelo | ~0.85 (multiplicador) | Pequeño deslizamiento |
| Velocidad de salto Y | ~10–11 px/frame | Salto alto |
| Gravedad | ~0.5–0.6 px/frame² | Caída arcade y rápida |
| Flotar (flap) | Reduce gravedad ~50% | No elimina la gravedad |

### 3.4 Técnicas Avanzadas de Movimiento

Emergen de las físicas del juego y son usadas por jugadores avanzados:

- **Gun Jumping:** Disparar armas de alto retroceso hacia abajo genera impulso vertical. Confirmado con `blunderbuss.xnb`.
- **Ragdoll Momentum:** Entrar en ragdoll durante un salto conserva la inercia horizontal para cruzar huecos a ras del suelo.
- **Slide Cancel:** Cancelar el deslizamiento con un salto para mantener la velocidad máxima con hitbox de pie.
- **Wall Angle Jumping:** Usar el Energy Scimitar (`energyScimiHilt.xnb`) para escalar paredes.

---

## 4. Sistema de Armas — Catálogo Completo por Archivos

Basado en los **860 archivos** encontrados en `/Content/`.

### 4.1 Armas de Fuego

| Arma | Archivo(s) | Mecánica |
|---|---|---|
| Pistola | `pistol.xnb` + `pistolShell.xnb` | 1 bala, recarga manual |
| Magnum | `magnum.xnb` + `magnumShell.xnb` | Potente, expulsa casquillo |
| Revólver Cowboy | `cowboyPistol.xnb` | Estética vaquera |
| Pistola Suicida | `suicidePistol.xnb` | Dispara *hacia atrás* al agacharse |
| SMG | `smg.xnb` | Ráfagas automáticas |
| AK-47 | `ak47.xnb` | Alta cadencia, retroceso notable |
| Escopeta | `shotgun.xnb` + `shotgunLoader.xnb` | Múltiples pellets, reload visual |
| Escopeta de Combate | `combatShotgun.xnb` + `combatShotgunAmmo.xnb` | Más rápida, 6 balas |
| Escopeta Virtual | `virtualShotgun.xnb` + `virtualShotgunLoader.xnb` | Variante especial |
| Rifle Francotirador | `sniper.xnb` + `sniperShell.xnb` | Larga distancia, penetra puertas |
| Rifle Alto Poder | `highPowerRifle.xnb` | Versión más potente |
| Blunderbuss | `blunderbuss.xnb` | Enorme retroceso, shot disperso |
| Trabuco | `musket.xnb` | Recarga lenta, un disparo |
| Pistola Pellet | `pelletGun.xnb` + `pellet.xnb` | Baja letalidad, muchos proyectiles |
| Pistola de Agua | `waterGun.xnb` | Resbala al pato en el suelo |
| Pistola de Dardos | `dartgun.xnb` + `dart.xnb` | Paraliza temporalmente |
| Pistola de Corcho | `corkGun.xnb` + `cork.xnb` | Aturde sin matar |
| G18 | `g18.xnb` | Pistola semiautomática |
| Snubnose | `snubby.xnb` | Revólver compacto |
| Pistola Mística | `mysteryGun.xnb` | Efecto aleatorio al disparar |

### 4.2 Armas de Energía y Futuristas

| Arma | Archivo(s) | Mecánica |
|---|---|---|
| Rifle Láser | `laserRifle.xnb` | Rayo continuo |
| Quad Láser | `quadLaser.xnb` | Dispara en 4 direcciones |
| Pew-Pew Láser | `pewpewLaser.xnb` | Bolas de energía rápidas |
| Láser Grande | `hugeLaser.xnb` | Rayo masivo, lento |
| Plasma Blaster | `plasmaBlaster.xnb` | Bola de plasma con splash |
| Pistola de Fase | `phaser.xnb` + `phaserCharge.xnb` | Se carga antes de disparar |
| Disparo Positrón | `positronShooter.xnb` + `positronWinder.xnb` | Proyectil especial |
| Coil Gun | `coilGun.xnb` | Dispara objetos metálicos |
| Mag Blaster | `magBlaster.xnb` | Magnético, atrae objetos |
| Warp Gun | `warpgun.xnb` | Teletransporta al jugador |
| Mind Control Gun | `mindControlGun.xnb` + `mindControlHelmet.xnb` | Controla al pato enemigo |
| Net Gun | `netGun.xnb` + `net.xnb` + `netGunGuage.xnb` | Inmoviliza al objetivo |
| Fun Beamer | `funBeamer.xnb` + `funBeam.xnb` | Rayo de diversión |

### 4.3 Explosivos y Granadas

| Arma | Archivo(s) | Mecánica |
|---|---|---|
| Granada | `grenade.xnb` + `grenadePin.xnb` | Mecha visible, cuenta regresiva |
| Lanzagranadas | `grenadeLauncher.xnb` + `launcherGrenade.xnb` | Arco de tiro |
| Bazooka | `bazooka.xnb` + `missile.xnb` | Misil directo |
| Cañón Granada | `grenadecannon.xnb` | Versión grande |
| Roman Candle | `romanCandle.xnb` | Fuegos artificiales como proyectil |
| Petardos | `fireCracker.xnb` / `fireCrackers.xnb` | Stun al explotar |
| Lanzallamas | `flamethrower.xnb` + `flamethrowerCan.xnb` | Fuego continuo, quema materiales |
| Cañón del nivel | `cannon.xnb` + `cannonTimer.xnb` | Hazard del nivel — dispara patos |

### 4.4 Armas Cuerpo a Cuerpo

| Arma | Archivo(s) | Mecánica |
|---|---|---|
| Espada | `sword.xnb` + `swordSwipe.xnb` | Golpe en arco |
| Espada con Cinta | `tapedSword.xnb` | Versión improvisada |
| Energy Scimitar | `energyScimiHilt.xnb` + `energyScimiaBlade.xnb` + `energyScimiBladeTrail.xnb` | Permite subir paredes |
| Sledgehammer | `sledgeHammer.xnb` + `sledgeSwing.xnb` + `sledgeForce.xnb` | Gran knockback |
| Chainsaw | `chainsaw.xnb` | Daño continuo al contacto |
| Turbo Chainsaw | `turbochainsaw.xnb` | Versión más rápida |
| Chain Mace | `maceBall.xnb` + `chain.xnb` + `chainLink.xnb` | Arma a distancia CaC |
| Boxing Glove | `boxingGlove.xnb` | Empuja al enemigo |
| Dart Chain | `dartchain.xnb` + `dartchain_tip.xnb` | Se extiende al lanzar |

### 4.5 Instrumentos Musicales (Armas Secundarias)

| Instrumento | Archivo | Efecto |
|---|---|---|
| Saxofón | `saxaphone.xnb` | Ataca con ondas de sonido |
| Trompeta | `trumpet.xnb` | Golpe/stun |
| Trombón | `tromboneBody.xnb` + `tromboneSlide.xnb` | El slide lo extiende como arma |
| Keytar | `keytar.xnb` + `keytarKeybed.xnb` | Arma/instrumento combinado |

### 4.6 Equipo y Gadgets

| Item | Archivo(s) | Función |
|---|---|---|
| Harpoon Gun | `harpoonGun.xnb` + `harpoon.xnb` | Grapple hook para traversal |
| Jetpack | `jetpack.xnb` + `jet.xnb` | Vuelo con combustible |
| Boots | `boots.xnb` + `bootsPickup.xnb` | Mayor altura de salto |
| Walljump Boots | `walljumpBoots.xnb` | Permite subir por paredes |
| Helmet | `helmet.xnb` | Absorbe un impacto |
| Knight Helmet | `knightHelmet.xnb` | Absorbe más impactos |
| Chest Plate | `chestPlate.xnb` + `chestPlateAnim.xnb` | Protección adicional |
| Holster | `holster.xnb` + `holster_over.xnb` + `holster_under.xnb` | 2 armas simultáneas |
| Power Holster | `powerHolster.xnb` | Holster mejorado |
| Fire Extinguisher | `extinguisher.xnb` | Apaga fuego, genera empuje |
| RC Controller | `rcController.xnb` + `rcBody.xnb` + `rcWheel.xnb` | Controla vehículo RC |
| Bionic Arm | `bionicArm.xnb` + `bionicArmHook.xnb` | Brazo biónico con gancho |
| Grapple Arm | `grappleArm.xnb` + `grappleWire.xnb` | Brazo garra |
| Shield | `sheeld.xnb` | Escudo reflector |

### 4.7 Mecánica de Unir Armas con Cinta (Tape System)
Confirmado en `DuckGame.XML`:
```
"Override this to define a special taped object that two taped objects
 should turn into (two swords = long sword for example)"
— Holdable.BecomeTapedMonster(TapedGun)
```
Archivos: `tape.xnb`, `tapePiece.xnb`, `cheapTape.xnb`

Cada arma puede implementar `BecomeTapedMonster()` para definir una combinación especial.

---

## 5. Shaders y Efectos Visuales — Los 50 Shaders

Encontrados en `/Content/Shaders/`. Revelan el pipeline de renderizado completo:

### 5.1 Shaders de Estado de Personaje/Objetos

| Shader | Efecto |
|---|---|
| `recolor.xnb` | Reemplaza colores en el sprite (personalización del pato) |
| `recolor_duo.xnb` | Recolorado de 2 canales de color simultáneos |
| `charred.xnb` | Aspecto carbonizado/quemado |
| `frozen.xnb` | Pato u objeto congelado |
| `ghost.xnb` | Transparencia/invisibilidad parcial |
| `gold.xnb` | Efecto dorado metálico brillante |
| `rainbow.xnb` | Ciclo animado de colores arcoíris |
| `redhot.xnb` | Metal al rojo vivo por calor |
| `greyscale.xnb` | Sin color (muerte, pausa) |
| `energyBlade.xnb` | Efecto de filo de energía del Scimitar |
| `plasma.xnb` | Efecto de plasma animado |
| `dustsparkle.xnb` | Partículas de polvo brillante |
| `katanaman.xnb` | Shader exclusivo del personaje secreto Katana Man |

### 5.2 Shaders de Iluminación

| Shader | Efecto |
|---|---|
| `basicAdd.xnb` | **Additive Blending** — base de toda la iluminación dinámica |
| `basicFade.xnb` | Fundido con transparencia |
| `basicFadeAdd.xnb` | Fundido + additive combinado |
| `fieldFadeAdd.xnb` | Additive para campos de energía |
| `lowlighting.xnb` | Oscurecimiento de ambiente (niveles oscuros) |
| `sunshine.xnb` / `baresunshine.xnb` | Rayos de sol / God rays |
| `lightBar.xnb` | Barra de luz |

### 5.3 Shaders de Post-Proceso (Pantalla Completa)

| Shader | Efecto |
|---|---|
| `blur.xnb` | Desenfoque gaussiano (pausa, transiciones) |
| `pause.xnb` | Efecto de pausa |
| `lcd.xnb` / `lcdBlur.xnb` / `lcdNoBlur.xnb` | Efecto LCD/pixelado estilo retro |
| `glitch.xnb` | Glitch visual para niveles especiales |
| `wiggle.xnb` | Distorsión ondulatoria |
| `glass.xnb` | Refracción de cristal |
| `wireframe.xnb` / `wireframeTex.xnb` | Modo wireframe |
| `selection.xnb` | Highlight de selección en editor |
| `burn.xnb` | Marcas de quemado en superficies |
| `bullet.xnb` | Renderizado especial de proyectiles |
| `album.xnb` | Efecto para pantalla de álbum |

### 5.4 Implementación de Iluminación en GameMaker

```gml
// Sistema de iluminación tipo Duck Game en GameMaker
// Paso 1: Dibujar el mundo normalmente
// Paso 2: Dibujar capa de oscuridad
draw_set_blend_mode(bm_normal);
draw_set_alpha(0.85);
draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

// Paso 3: Dibujar luces con Additive Blending encima
draw_set_blend_mode(bm_add);
// Por cada fuente de luz:
draw_sprite_ext(spr_light_blob, 0, light_x, light_y, light_radius, light_radius, 0, light_color, light_alpha);
draw_set_blend_mode(bm_normal);
```

---

## 6. Diseño de Niveles — Análisis Profundo

### 6.1 Biomas Confirmados (147 niveles de deathmatch)

| Bioma | Cantidad de Niveles | Tileset Principal |
|---|---|---|
| **Bunker** | 8 | `backgroundTiles01.xnb`, `wireTileset.xnb` |
| **City (Ciudad)** | 13 | `cityTileset.xnb`, `cityBackground.xnb` |
| **Forest (Bosque)** | 20 | `natureTileset.xnb`, `treeTileset.xnb` |
| **Industrial** | 6 | `industrialTileset.xnb` |
| **Office (Oficina)** | 21 | `officeTileset2.xnb` |
| **Snow (Nieve)** | 15 | `snowTileset.xnb`, `snowIceTileset.xnb` |
| **Space (Espacio)** | 18 | `spaceTileset.xnb` |
| **Generic** | 9 | Varios |

Adicionales: `pyramid/`, `challenge/`, `special/`, `online_only/`, `rare/` con tilesets exclusivos.

### 6.2 Variantes por Cantidad de Jugadores

Muchos niveles tienen una variante `_8`:
- `bunker01.lev` → versión 4 jugadores
- `bunker01_8.lev` → versión 8 jugadores (más espacio, más spawns)

### 6.3 Tilesets Especiales

| Tileset | Temática |
|---|---|
| `cloudTileset.xnb` | Plataformas de nube |
| `wireTileset.xnb` | Ambientes industriales/eléctricos |
| `pyramidTileset.xnb` | Pirámide egipcia |
| `donutTileset.xnb` | Rosquillas cómicas |
| `blueprintTileset.xnb` | Editor/wireframe |
| `undergroundTileset.xnb` | Subterráneo/cueva |
| `spookyTileset.xnb` | Terror/Halloween |
| `caveTileset.xnb` | Cueva natural |
| `castle.xnb` | Castillo medieval |
| `pineTileset.xnb` / `pineTilesetSnow.xnb` | Pinos normales y nevados |

### 6.4 Sistema de Wiring (Circuitos Eléctricos del Nivel)

Duck Game tiene un sistema de cableado para crear **trampas y mecanismos**:

| Componente | Archivo | Función |
|---|---|---|
| Botón | `wireButton.xnb` | Activador presionable |
| Trampilla Pequeña | `wireTrapDoorArm.xnb` | Trampilla activada por cable |
| Trampilla Grande | `wireTrapDoorArmBig.xnb` | Versión mayor |
| Palanca | `wireFlipper.xnb` | Interruptor flip-flop |
| Bloque Activado | `wireBlock.xnb` | Bloque que aparece/desaparece |
| Activador | `activatorBlock.xnb` | Bloque que activa otros |
| Punto de Montaje | `wireMount.xnb` | Ancla del cable en pared |
| Curvatura | `wireBulge.xnb` | Visual de curva del cable |

Los cables conectan visualmente botones → puertas → trampillas → cañones.

### 6.5 Objetos Interactivos del Nivel

| Objeto | Archivo(s) | Función |
|---|---|---|
| Caja | `crate.xnb` / `itemCrate.xnb` / `bigItemCrate.xnb` | Contiene arma al romperla |
| Barril Rojo | `explosiveBarrel.xnb` | Explota con daño |
| Barril Azul | `blueBarrel.xnb` + `blueBarrelMelting.xnb` | Derrama ácido |
| Barril Amarillo | `yellowBarrel.xnb` | Derrama líquido resbaladizo |
| Barril de Lava | `lavaBarrel.xnb` | Derrama lava |
| Pinchos | `spikes.xnb` / `movingSpikes.xnb` | Muerte instantánea |
| Trampolín | `spring.xnb` / `springAngle.xnb` / `springAnglePurple.xnb` | Lanza al aire |
| Puerta Normal | `door.xnb` / `doorFucked.xnb` | Destructible |
| Puerta Endeble | `flimsyDoor.xnb` + `flimsyDoorDamaged.xnb` | Se rompe rápido |
| Puerta con Cerrojo | `lockDoor.xnb` | Requiere llave (`key.xnb`) |
| Puerta Vertical | `verticalDoor.xnb` | Variante vertical |
| Teleportador | `teleporterTop.xnb` + `teleporterBottom.xnb` | Par de teleports |
| Teleportador Mini | `littleTeleTop.xnb` + `littleTeleBottom.xnb` | Versión pequeña |
| Ascensor | `elevator.xnb` | Plataforma móvil |
| Tuberías | `travelPipes.xnb` (verde, azul, verde oscuro) | Teletransporte por tubería |
| Cañón del nivel | `cannon.xnb` + `cannonTimer.xnb` | Dispara patos |
| Lava | `lava.xnb` + `lavaSplash.xnb` + `lavaGlowEdge.xnb` | Mata al contacto |
| Agua | `water.xnb` + `waterFall.xnb` | Ralentiza movimiento |
| Banana | `banana.xnb` | Resbala al pato |
| Mina | `mine.xnb` + `mineFlash.xnb` | Explota al pisarla |
| Sierras | `saws.xnb` | Hazard giratorio |
| Turret | `turretBase.xnb` + `turretHead.xnb` | Torreta automática |
| Pico de hielo | `icicles.xnb` + `icicleBig.xnb` | Cae al pasar debajo |

### 6.6 Fondos con Parallax

| Fondo | Archivo |
|---|---|
| Arcade | `arcadeBackground.xnb` |
| Castillo | `castleBackground.xnb` |
| Ciudad | `cityBackground.xnb` |
| Espacio | `spaceBackground.xnb` |
| Naturaleza | `natureBackground.xnb` |
| Industrial | `industrialBackground.xnb` |
| Pyramide | `pyramidBackground.xnb` |
| Oficina | `officeBackground.xnb` |
| Sub-oficina | `officeSubBackground.xnb` |

---

## 7. Audio y Música

### 7.1 Sistema de Audio
- Motor: **NAudio** + **NVorbis** (decodificador OGG)
- Formato: `.ogg` (Vorbis) — calidad alta, tamaño reducido

### 7.2 Filosofía de Diseño de Sonido

- **Capas por acción:** Una escopeta tiene: sonido de la explosión + sonido de la cámara + casquillo cayendo.
- **Quack como comunicación:** El `QUACK` es exagerado y cómico — funciona como lenguaje no verbal.
- **Silencio dramático:** Entre rondas el volumen baja para que el inicio de la siguiente sea más impactante.
- **Música por bioma:** Cada bioma tiene su pista musical (confirmado por la estructura de carpetas de Audio).

---

## 8. Sistema de Red y Multijugador

Extraído directamente de `DuckGame.XML`:

### 8.1 GhostObjects — Sincronización de Estado
```
"Fills a bit buffer with this objects network state data"
— GhostObject.FillStateData(GhostConnectionData, bool pForceFull)
```
Duck Game usa **GhostObjects** — objetos fantasma que representan el estado de jugadores remotos. Se sincronizan via `BitBuffer` (datos comprimidos bit a bit).

### 8.2 Local vs Red
```
"If true, this object's Update function is run via Level.UpdateThings.
 Otherwise, it's run via GhostManager.UpdateGhostLerp"
— Thing.shouldRunUpdateLocally
```

### 8.3 Sincronización de Input
```
"DON'T set this variable in realtime! It's used to determine how many
 input states to synchronize."
— NetworkConnection.packetsEvery
```
El juego sincroniza **múltiples estados de input** por paquete para precisión en redes lentas.

---

## 9. Sistema de Personalización del Pato

### 9.1 Partes Personalizables Confirmadas

| Parte | Opciones |
|---|---|
| Sombrero | 93 sombreros base + Steam Workshop |
| Capa | 8 capas (gereCape, plainCape, rainbowCape, moonCape, royalCape, waffleCape, devCape) |
| Color primario | Número arbitrario de colores |
| Color secundario | Recolor_duo (2 canales) |

### 9.2 Sistema de Color
Los shaders `recolor.xnb` y `recolor_duo.xnb` reemplazan colores específicos del sprite base por los colores elegidos por el jugador. El pato tiene 2 "slots" de color.

---

## 10. Sistema de Holster (Pistolera)

Permite llevar **2 armas simultáneas**:

| Componente | Archivo | Función |
|---|---|---|
| Pistolera | `holster.xnb` | Accesorio visual principal |
| Cadena | `holsterChain.xnb` | Decoración |
| Cerrojo | `holsterLock.xnb` | Seguro |
| Capa encima | `holster_over.xnb` | Se dibuja sobre el pato |
| Capa debajo | `holster_under.xnb` | Se dibuja debajo del pato |
| Holster Pro | `powerHolster.xnb` + `powerHolsterOver.xnb` + `powerHolsterUnder.xnb` | Versión mejorada |

**Mecánica:** Con holster equipada, el pato puede guardar el arma activa y desenfundar la secundaria en un botón, sin tirarla al suelo.

---

## 11. UI y Presentación

### 11.1 Fuentes

| Archivo | Uso |
|---|---|
| `biosFont.xnb` | Fuente principal (estilo BIOS retro) |
| `duckFont.xnb` | Fuente secundaria |
| `smallFont.xnb` | Texto pequeño en UI |
| `ornateFont.xnb` | Decorativa |
| `intermissionFont.xnb` | Pantallas entre rondas (grande) |
| `moneyFont.xnb` | Puntos/moneda |
| `thickBiosNum.xnb` | Números grandes y gruesos |

### 11.2 Pantallas de Ronda

| Asset | Uso |
|---|---|
| `countdown.xnb` | Cuenta regresiva inicio de ronda |
| `ready.xnb` | Pantalla "READY" |
| `deathFrame.xnb` | Marco al morir |
| `ginormoScore.xnb` | Puntuación enorme al ganar ronda |
| `gettingXP.xnb` | Animación de XP al final |

### 11.3 Metáfora de Programa de TV

Duck Game enmarca las partidas como un programa de televisión:

| Asset | Función |
|---|---|
| `bigTV.xnb` / `teevee.xnb` / `tvnoise.xnb` | Televisores en la UI |
| `hostChair.xnb` + `hostCrown.xnb` + `hostTable.xnb` | Mesa del presentador |
| `interviewDuck.xnb` + `interviewBox.xnb` | Pato entrevistador |
| `newsDuck.xnb` + `newsTable.xnb` | Presentación de noticias |
| `newsCaster.gal` | Animación del noticiero |

---

## 12. Implementación en GameMaker — Código Completo

### 12.1 Arquitectura de Objetos

```
obj_thing (padre de todo)
 ├── obj_physics_object (físicas manuales)
 │    ├── obj_player (el pato)
 │    └── obj_weapon_base (armas sueltas)
 │         ├── obj_gun_pistol
 │         ├── obj_gun_shotgun
 │         └── obj_melee_sword
 ├── obj_level_element (elementos del nivel)
 │    ├── obj_crate
 │    ├── obj_barrel_explosive
 │    └── obj_door
 └── obj_hazard (peligros)
      ├── obj_spikes
      ├── obj_lava
      └── obj_spring
```

### 12.2 Física del Jugador en GML

```gml
// --- obj_player → Create Event ---
hsp = 0;
vsp = 0;
grv = 0.5;
max_hsp = 6;
accel = 1.5;
friction_ground = 0.85;
jump_force = -11;
is_grounded = false;
is_sliding = false;
is_ragdoll = false;

// --- obj_player → Step Event ---
var move = keyboard_check(vk_right) - keyboard_check(vk_left);

// Física horizontal
if (move != 0 && !is_ragdoll) {
    hsp += move * accel;
    hsp = clamp(hsp, -max_hsp, max_hsp);
} else if (is_grounded) {
    hsp *= friction_ground;
}

// Gravedad
vsp += grv;

// Flap en el aire (aletear)
if (!is_grounded && keyboard_check(vk_up)) {
    vsp -= grv * 0.5; // Ralentiza caída sin eliminar gravedad
}

// Colisión horizontal
if (place_meeting(x + hsp, y, obj_solid)) {
    while (!place_meeting(x + sign(hsp), y, obj_solid)) x += sign(hsp);
    hsp = 0;
}
x += hsp;

// Colisión vertical
if (place_meeting(x, y + vsp, obj_solid)) {
    while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);
    vsp = 0;
    is_grounded = true;
} else {
    is_grounded = false;
}
y += vsp;

// Salto
if (keyboard_check_pressed(vk_up) && is_grounded) {
    vsp = jump_force;
    is_grounded = false;
}
```

### 12.3 Recoil de Armas en GML

```gml
// --- En obj_weapon_base → función fire() ---
function fire() {
    var bullet = instance_create_layer(x, y, "layer_bullets", obj_bullet);
    bullet.direction = point_direction(x, y, target_x, target_y);
    bullet.speed = 15;

    // Aplicar recoil al portador
    if (holder != noone) {
        var recoil_force = 3; // Ajustar por arma
        var recoil_angle = bullet.direction + 180;
        holder.hsp += lengthdir_x(recoil_force, recoil_angle);
        holder.vsp += lengthdir_y(recoil_force, recoil_angle);
    }
}
```

### 12.4 Cámara Dinámica con Zoom

```gml
// --- obj_camera → Step Event ---
var left = infinity, right = -infinity;
var top = infinity, bottom = -infinity;
var num_players = 0;

with (obj_player) {
    if (!dead) {
        left   = min(left, x);
        right  = max(right, x);
        top    = min(top, y);
        bottom = max(bottom, y);
        num_players++;
    }
}
if (num_players == 0) exit;

var target_x = (left + right) / 2;
var target_y = (top + bottom) / 2;
var width_needed  = (right - left) + 200;
var height_needed = (bottom - top) + 150;

var zoom_x = room_width / max(width_needed, 1);
var zoom_y = room_height / max(height_needed, 1);
var target_zoom = clamp(min(zoom_x, zoom_y), 0.5, 2.0);

camera_x    = lerp(camera_x, target_x, 0.08);
camera_y    = lerp(camera_y, target_y, 0.08);
camera_zoom = lerp(camera_zoom, target_zoom, 0.05);

var vw = room_width  / camera_zoom;
var vh = room_height / camera_zoom;
camera_set_view_pos(view_camera[0], camera_x - vw/2, camera_y - vh/2);
camera_set_view_size(view_camera[0], vw, vh);
```

### 12.5 Wraparound de Pantalla

```gml
// --- obj_player → Step Event ---
if (x > room_width + 16)  x = -16;
if (x < -16)              x = room_width + 16;
if (y > room_height + 16) y = -16;  // Opcional, activar por bioma
if (y < -16)              y = room_height + 16;
```

### 12.6 Plataformas One-Way (Jump-Through)

```gml
// --- obj_player → Step Event ---
// Solo colisiona si el jugador va hacia abajo y está encima de la plataforma
var can_collide = (vsp >= 0) && (bbox_bottom <= (obj_platform_oneway.bbox_top + 4));

if (can_collide && place_meeting(x, y + vsp, obj_platform_oneway)) {
    while (!place_meeting(x, y + 1, obj_platform_oneway)) y++;
    vsp = 0;
    is_grounded = true;
}

// Caer a través presionando abajo
if (keyboard_check(vk_down) && is_grounded) {
    drop_through_timer = 18; // 18 frames @ 60fps
}
if (drop_through_timer > 0) {
    drop_through_timer--;
    // Ignorar colisión con plataformas one-way durante este tiempo
}
```

---

## 13. Pilares de Diseño de Duck Game

| Pilar | Implementación concreta |
|---|---|
| **Frenético** | Rondas de 3–10 segundos, one-hit kill, respawn inmediato |
| **Legible** | Pixel art claro, colores contrastados, hitboxes simples y consistentes |
| **Físico** | Todo es un objeto físico: armas, casquillos, cuerpos, fragmentos, bananas |
| **Emergente** | Interacciones entre objetos crean situaciones no programadas |
| **Social** | El Quack, los sombreros y las reacciones del pato crean momentos compartidos |
| **Justo** | Si mueres, fue tu error — las físicas son completamente predecibles |

---

*Documento creado: Septiembre 2026*
*Fuentes primarias: Archivos del juego en `/Duck Game/Content/` (860 archivos catalogados), `/Duck Game/DuckGame.XML` (documentación oficial de la API), investigación online.*
