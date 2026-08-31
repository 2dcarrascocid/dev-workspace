# Addendum a skills/evidence_logger/ — Certificación liviana

No reemplaza el registro de plan+resultado que ya hace evidence_logger — lo
complementa. Cuando el Validator aprueba una tarea, evidence_logger debería además
escribir un registro corto y estructurado (no prosa) en:

```
.adf/certifications/<path-normalizado>.yaml
```

`<path-normalizado>` = la ruta real que se tocó en esa tarea puntual, tomada de la
instrucción del usuario (ej. `routes/api/api-rendicion/servicios`,
`routes/api/api-gasto/administrador`, o cualquier otra dentro del proyecto),
normalizada reemplazando `/` por `_` para el nombre de archivo. NO es un valor fijo
— cambia en cada tarea según qué ruta se haya trabajado.

Ejemplo de cómo quedaría el YAML para una tarea puntual (los valores de `path`,
`files_touched`, `agent`, etc. son específicos de esa ejecución, no una plantilla a
copiar literal):

```yaml
path: routes/api/api-rendicion/servicios        # <- dinámico, la ruta real trabajada
tags: [backend, error-handling, service-unification]
standard_applied: standards/error-handling-backend.md
validated_by: security-reviewer
date: 2026-08-31
agent: claude
files_touched:
  - route-servicio.js
  - core-servicios.js
tests_passed: true
commit: null   # queda null si "nothing committed yet"
notes: >
  Wrapper route-servicio.js no estaba wireado con los middlewares — corregido.
  Ver docs/manejo-errores-servicios.md para detalle completo.
```

Si mañana se corre sobre `routes/api/api-gasto/administrador`, el archivo generado
sería `.adf/certifications/routes_api_api-gasto_administrador.yaml`, con su propio
`path`, `files_touched`, etc. — evidence_logger arma este archivo dinámicamente a
partir de la ruta y los datos reales de cada tarea, nunca copiando el ejemplo de
arriba tal cual.

## Para qué sirve esto en la práctica
Antes de que un agente (cualquier CLI) empiece a tocar una ruta, puede chequear
`.adf/certifications/` para esa ruta específica:
- Si ya existe un registro con el mismo `standard_applied` y `tests_passed: true`,
  no repite el trabajo desde cero — parte del estado ya certificado.
- Si el registro es viejo o el standard cambió desde entonces, lo sabe por
  comparación de fecha/versión del standard, en vez de asumir.
- Si dos sesiones en paralelo tocan rutas hermanas, esto es lo que le permite a la
  segunda sesión saber qué ya se hizo sin tener que leer commits a mano.

## Alcance de esta v1
No hace falta un schema validator ni un dashboard — un YAML por ruta, generado por
evidence_logger al cierre de cada tarea validada, alcanza. Si en el futuro esto
crece mucho, ahí se evalúa una herramienta dedicada (no antes).
