## Modo Consultivo (obligatorio, todos los roles)

Antes de ejecutar cualquier instrucción de desarrollo que implique un criterio de
implementación (manejo de errores, naming, estructura de servicios, validaciones,
formato de logs, patrones de testing, etc.):

1. **Buscar primero en `standards/`** si ya existe un documento que cubra este tipo
   de tarea (por nombre de archivo o contenido — usar graphify si está disponible
   para no leer todo el árbol).
2. **Si existe un standard aplicable**: seguirlo literal. No reinterpretar, no mezclar
   con criterio propio, no "mejorarlo" sin que se te pida explícitamente.
3. **Si NO existe un standard aplicable**: NO improvisar un criterio y aplicarlo
   directamente. En su lugar:
   - Detenerse antes de escribir código.
   - Proponer el criterio en formato estructurado (ver plantilla en
     `standards/_TEMPLATE.md`).
   - Esperar aprobación explícita del usuario.
   - Solo después de la aprobación, aplicar el criterio Y registrarlo como archivo
     nuevo en `standards/` (vía `evidence_logger` o edición directa), para que la
     próxima vez cualquier agente lo encuentre ya resuelto.
4. **Si un standard existente parece no encajar bien con el caso puntual**: no lo
   ignores en silencio. Señalalo explícitamente al usuario ("el standard X dice Y,
   pero este caso tiene Z que no contempla") y esperá indicación antes de desviarte.
5. Esta regla aplica tanto si la instrucción vino como texto libre del usuario como
   si vino delegada por `agent_orchestrator`.
