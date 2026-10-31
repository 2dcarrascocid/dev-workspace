---
name: db-architect
description: Diseña y modifica el schema de base de datos (tablas, relaciones, índices y migraciones versionadas y reversibles) cuidando la integridad de los datos. Úsalo cuando el usuario pida "agregá una columna", "creá la tabla de usuarios", "hace falta un índice" o "armá la migración". No usar para endpoints ni para la lógica que consulta la base (eso es backend-dev).
tools:
  - read_file
  - write_file
  - edit_file
  - run_shell_command
  - search_files
model: inherit
---
