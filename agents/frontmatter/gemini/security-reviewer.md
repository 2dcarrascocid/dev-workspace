---
name: security-reviewer
description: Revisa cambios de código en busca de problemas de seguridad antes de que una tarea se dé por cerrada. Úsalo antes de finalizar cualquier tarea que toque autenticación, datos sensibles, inputs externos o dependencias.
tools:
  - read_file
  - search_files
  - run_shell_command
model: inherit
---
