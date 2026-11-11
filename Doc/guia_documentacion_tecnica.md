# Guía de documentación técnica del proyecto

Este documento define **cómo se documenta este proyecto** (juego voxel en Godot 4.7 / C#). No es documentación del juego en sí — es la guía que la IA (y cualquier futuro desarrollador) debe seguir para producir y mantener la documentación de forma consistente. Basado en prácticas estándar de la industria (ADR, XML doc comments, documentación de arquitectura viva) adaptadas al flujo de trabajo que ya se viene usando en este proyecto.

---

## 1. Los 4 niveles de documentación de este proyecto

Cada tipo de documentación responde una pregunta distinta. No mezclar niveles: cada uno vive en su propio lugar.

| Nivel | Pregunta que responde | Dónde vive | Cuándo se escribe |
|---|---|---|---|
| **1. Comentarios inline** | "¿Por qué esta línea/bloque hace esto de esta forma no obvia?" | Dentro del `.cs`, pegado al código | Al escribir el código, si hace falta |
| **2. XML Doc Comments** | "¿Qué hace esta clase/método públicamente? ¿Qué recibe, qué devuelve?" | Dentro del `.cs`, sobre la firma | Al cerrar una clase/método público estable |
| **3. Documento de arquitectura** | "¿Cómo están organizados los sistemas y por qué?" | `plan_desarrollo_voxel_godot.md` (vivo, se actualiza) | Cuando cambia una decisión estructural grande |
| **4. Bitácora de fase/sesión** | "¿Qué se hizo esta sesión, qué se probó y descartó, qué bugs aparecieron, qué queda pendiente?" | `contexto_faseN_completa.md` (uno nuevo por fase o parte) | Al cerrar cada fase o sesión de trabajo |

Los niveles 3 y 4 ya se vienen haciendo bien en este proyecto — esta guía los formaliza para que se mantengan consistentes. Los niveles 1 y 2 son los que hay que reforzar de acá en adelante.

---

## 2. Nivel 1 — Comentarios inline

**Regla de oro: comentar el *por qué*, nunca el *qué*.** El código ya dice qué hace; si hace falta un comentario para explicar qué hace una línea, probablemente esa línea debería reescribirse más clara, no comentarse.

Comentar quando:
- Una decisión no es obvia y alguien (incluido el autor, en 6 meses) podría "corregirla" por error si no sabe la razón.
- Se descartó una alternativa más obvia y vale la pena que quede registrado por qué.
- Hay una limitación conocida, un caso borde no resuelto, o un TODO real.
- Hay una referencia a un bug ya resuelto que explica por qué el código quedó así (ej.: "no cambiar esto a `X`, ver bug del winding order en Fase 2").

**No comentar:**
- Lo que el código ya deja claro por sí mismo (`i++; // incrementa i` es ruido, no documentación).
- Bloques enteros de historia de la fase — eso va en el `contexto_faseN.md`, no en el código.

Ejemplos concretos de este proyecto, para calibrar:

```csharp
// BIEN — explica el porqué de una decisión no obvia:
// FloorDiv en vez de división nativa: con coordenadas negativas, la división
// de C# trunca hacia cero, no hacia -infinito. Ver bug documentado en Fase 1.
private static int FloorDiv(int a, int b) => (int)Math.Floor((double)a / b);

// BIEN — marca deuda técnica real, con razón:
// TEMPORAL: instrumentación de diagnóstico de la Fase 9 Parte 3, dejada a
// propósito por decisión del usuario. Candidata a limpiar o volver
// condicional (ver contexto_fase9_parte3.md, sección "Pendiente").
private static long _relightMs;

// MAL — no aporta nada que el código no diga ya:
// Suma 1 al contador
counter++;
```

**Marcadores estándar a usar en este proyecto** (mismo criterio que ya aparece en los `contexto_faseN.md`, ahora llevado al código):
- `// TEMPORAL:` — código de diagnóstico/debug que se sabe que hay que sacar o volver condicional más adelante.
- `// PENDIENTE:` — comportamiento incompleto a propósito, con la razón.
- `// DECISIÓN:` — se consideró una alternativa obvia y se descartó; explica por qué en una línea.

---

## 3. Nivel 2 — XML Doc Comments (C#)

Godot + Visual Studio/Rider leen los comentarios `///` y los muestran como tooltip al pasar el mouse sobre un método o clase. Es el estándar de C# para documentar una API pública.

**No hace falta documentar todo.** Se prioriza:
1. Clases que son punto de entrada de un sistema (`ChunkManager`, `WorldManager`, `LightPropagator`, `VoxelPathfinder`) — sí.
2. Métodos públicos que otros sistemas van a llamar (`GetBlockAt`, `SetBlockAt`, `RelightAfterEdit`) — sí.
3. Métodos privados internos, autoexplicativos por nombre — no hace falta, salvo que hagan algo no obvio (ahí es más apropiado un comentario inline).
4. Getters/setters triviales — no.

Formato mínimo útil (no hace falta abusar de todas las etiquetas XML que existen):

```csharp
/// <summary>
/// Punto único de consulta de bloques por posición de mundo. Traduce
/// mundo → sección/local con FloorDiv/Mod propios (coordenadas negativas
/// seguras). Fuera del área generada, devuelve AirId por convención.
/// </summary>
/// <param name="worldX">Coordenada X en espacio de mundo (no de sección).</param>
/// <returns>El id de bloque (ushort) en esa posición, o AirId si no existe.</returns>
public ushort GetBlockAt(int worldX, int worldY, int worldZ) { ... }
```

Regla práctica: si una clase o método ya está bien explicado en el `contexto_faseN.md` correspondiente, el XML doc comment puede ser un resumen corto de una o dos líneas (el detalle completo ya vive en el nivel 4) — no hay que duplicar toda la explicación en el código.

---

## 4. Nivel 3 — Documento de arquitectura (`plan_desarrollo_voxel_godot.md`)

Es el documento **vivo** que describe cómo está organizado el proyecto hoy: principios de arquitectura, estructura de carpetas, responsabilidades de cada sistema. A diferencia de los `contexto_faseN.md` (que son bitácora histórica, no se reescriben), este documento sí se actualiza cuando cambia algo estructural grande.

**Cuándo actualizarlo:**
- Cambia la estructura de carpetas de forma duradera.
- Se agrega o reemplaza un sistema central (ej.: cuando se decida entre Arch/Friflo para ECS, o cuando se implemente streaming de chunks).
- Un principio de arquitectura original deja de aplicar o se refina.

**Cuándo NO tocarlo:** para detalles de una fase puntual, bugs resueltos, o decisiones menores — eso es nivel 4.

---

## 5. Nivel 4 — Bitácora de fase/sesión (`contexto_faseN_completa.md`)

Este es el corazón de la documentación de este proyecto — ya se viene haciendo bien, esta sección lo formaliza para mantener la consistencia entre sesiones futuras.

### 5.1 Cuándo se crea uno nuevo

Un documento nuevo por **fase completa** (ej. `contexto_fase6_completa.md`) o por **parte/sesión de trabajo** dentro de una fase iterativa larga (ej. `contexto_fase9_parte4.md`). Nunca se reescribe uno viejo — son un historial cronológico, como un changelog detallado con razones.

### 5.2 Plantilla estándar

Basado en el patrón ya consolidado en este proyecto desde la Fase 1:

```markdown
# Contexto del proyecto — Juego voxel estilo Minecraft (Godot 4.7, C#)

Pegar este documento al inicio del chat nuevo, junto con [lista de documentos previos] si Claude los pide o para tenerlos de referencia.

## Estado: Fase N (Nombre de la fase) — COMPLETA / EN CURSO, Parte M

[1-2 líneas de resumen: qué se hizo, con qué principios/estilo de trabajo.]

## Estructura nueva agregada sobre la Fase N-1

[Árbol de carpetas — SOLO lo nuevo o modificado, no todo el proyecto.]

## Clases implementadas / modificadas y su responsabilidad

[Por cada clase tocada: qué hace, qué NO hace, decisiones de diseño puntuales
metidas ahí mismo si son chicas. Una por una, no un párrafo genérico.]

## Bugs encontrados y resueltos durante esta fase
[Numerados. Por cada uno: síntoma, causa real (no la hipótesis descartada),
fix. Esto es lo más valioso del documento — evita repetir diagnósticos.]

## Decisiones de diseño explícitas tomadas en esta fase
[Por qué se eligió A y no B, con el trade-off. Alternativas descartadas
y por qué, si vale la pena que quede registrado.]

## Pendiente identificado, no bloqueante
[Lista concreta. Distinguir "deuda técnica a propósito, documentada" de
"bug real menor". Heredar los pendientes de fases anteriores que sigan
sin resolver, marcados como "(Heredado de Fase X)".]

## Verificaciones hechas al cierre de la fase (todas OK)
[Checklist de qué se probó a mano y confirmó funcionando.]

## Configuración relevante en el editor
[Todo lo que se tocó a mano en Godot: Input Map, grupos, campos del
Inspector, nodos agregados/eliminados. Sin esto, el código solo no alcanza
para reproducir el estado del proyecto.]

## Siguiente paso: Fase N+1 — [Nombre]
[Qué sigue, qué decisiones ya están anticipadas por cómo quedó la
arquitectura actual, qué falta decidir en el próximo chat.]
```

### 5.3 Reglas de contenido (ya aplicadas, ahora explícitas)

- **Medir antes de asumir, y dejarlo por escrito.** Cuando se investiga un problema de rendimiento, documentar también las hipótesis descartadas con evidencia — no solo la causa real. Esto evita que una sesión futura repita el mismo camino equivocado (ver ejemplo real: la investigación de la luz en Fase 5 y Fase 9 Parte 1-2).
- **Todo bug documentado necesita: síntoma → causa real → fix.** Nunca solo "se arregló X" sin explicar qué lo causaba — si el síntoma vuelve a aparecer en otra forma, la causa registrada es lo que permite reconocerlo.
- **Las decisiones descartadas se documentan igual que las aceptadas**, si el descarte no fue trivial (ver ejemplo real: `IsOpenToSky` descartado en Fase 9 Parte 3, o `HasIndependentSupport` descartado en la misma sesión). Esto evita que alguien vuelva a proponer la misma solución ya probada y descartada.
- **Los pendientes se heredan explícitamente entre documentos**, con la fase de origen entre paréntesis. Nunca se "pierden" pendientes viejos por no repetirlos.
- **La sección de configuración del editor es obligatoria**, no opcional — es la parte que el código fuente por sí solo nunca puede reconstruir (grupos, Input Map, campos del Inspector).

---

## 6. Cuándo usar un ADR aparte (nivel adicional, opcional)

Los `contexto_faseN.md` ya funcionan como una bitácora que incluye decisiones — para la mayoría de los casos de este proyecto, alcanza con eso. Pero si en algún momento aparece una decisión **grande, cara de revertir, y que probablemente se vuelva a cuestionar en el futuro** (ejemplo real pendiente en este proyecto: elegir entre Arch y Friflo para el ECS; o el diseño de streaming dinámico de chunks), conviene sacarla a un documento propio, más corto y enfocado, en vez de enterrarla dentro de un `contexto_faseN.md` largo.

Formato estándar de ADR (una decisión = un documento):

```markdown
# ADR-00X: [Título corto de la decisión]

## Estado
[Propuesta | Aceptada | Reemplazada por ADR-00Y]

## Contexto
¿Qué problema hay que resolver? ¿Qué restricciones existen?

## Alternativas consideradas
- Opción A: [ventajas / desventajas]
- Opción B: [ventajas / desventajas]

## Decisión
Qué se eligió, en una o dos frases directas.

## Consecuencias
### Positivas
### Negativas / trade-offs aceptados
```

**Criterio para decidir si algo amerita un ADR propio en vez de vivir dentro de un `contexto_faseN.md`:**
- Afecta a varios sistemas a la vez, no a uno solo.
- Es cara o difícil de revertir después.
- Hubo debate real entre alternativas (no una elección obvia).
- Es probable que alguien pregunte "¿por qué está hecho así?" mucho después de la fase donde se decidió.

Si ninguna de estas aplica, con el `contexto_faseN.md` de esa fase alcanza — no hace falta un ADR aparte para cada decisión chica.

---

## 7. Checklist rápido al cerrar cualquier sesión de trabajo

1. ¿Hay código nuevo con comentarios `///` en las clases/métodos públicos importantes?
2. ¿Los comentarios inline explican el *por qué* de lo no obvio, no el *qué*?
3. ¿Se escribió (o actualizó) el `contexto_faseN_completa.md` de esta sesión, siguiendo la plantilla de la sección 5.2?
4. ¿Los bugs encontrados quedaron con síntoma → causa real → fix, no solo "se arregló"?
5. ¿Los pendientes de fases anteriores siguen listados (heredados), no se perdieron?
6. ¿La configuración manual del editor (Input Map, grupos, Inspector) quedó anotada?
7. ¿`plan_desarrollo_voxel_godot.md` necesita actualizarse porque cambió algo estructural grande? (la mayoría de las sesiones, la respuesta es no)
8. ¿Alguna decisión de esta sesión es lo bastante grande/cara de revertir como para merecer su propio ADR aparte?

---

## 8. Resumen para la IA

Cuando trabajes en este proyecto:
- Al escribir código nuevo: agregá XML doc comments a clases/métodos públicos importantes, y comentarios inline solo donde el *por qué* no sea obvio.
- Al cerrar una fase o sesión: generá (o actualizá) el `contexto_faseN_completa.md` correspondiente siguiendo la plantilla de la sección 5.2 — no hace falta que te lo pidan explícitamente, es parte natural de cerrar el trabajo.
- No dupliques información entre niveles: el detalle largo de una decisión vive en el `contexto_faseN.md`; el código solo necesita un resumen corto.
- Si una decisión te parece lo bastante grande como para ameritar un ADR aparte (criterio de la sección 6), decilo explícitamente antes de simplemente enterrarla en la bitácora de fase.
