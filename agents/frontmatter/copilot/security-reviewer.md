---
name: security-reviewer
description: Revisa los cambios de código en busca de problemas de seguridad (autenticación, autorización, validación de inputs, secretos hardcodeados en el código, dependencias vulnerables) y clasifica cada hallazgo por severidad, sin corregirlo. Úsalo antes de cerrar cualquier tarea que toque auth, datos sensibles, inputs externos, dependencias o la app móvil, o cuando el usuario pida "revisá la seguridad de esto". No usar para buscar credenciales reales en archivos .env de ejemplo o en el historial de git (eso es secrets_scanner).
tools: ['read', 'search', 'execute']
---
