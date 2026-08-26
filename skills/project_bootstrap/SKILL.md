---
name: project_bootstrap
description: Detecta el stack de un proyecto (lenguaje, framework, motor de DB, gestor de paquetes) leyendo sus archivos de manifiesto y propone el contenido para PROJECT.md. Úsalo cuando el usuario pida iniciar un proyecto nuevo, detectar el stack automáticamente, o completar/actualizar PROJECT.md sin llenarlo a mano.
---

# Project Bootstrap

Detectás el stack técnico de un repo leyendo sus archivos de manifiesto, y
proponés el contenido para `PROJECT.md` en vez de dejar que el usuario lo
complete a mano campo por campo.

## Señales a buscar (por carpeta/repo)

| Archivo presente | Lenguaje/runtime probable |
|---|---|
| `package.json` | Node.js — mirar `dependencies` para el framework (express, nestjs, next, react, vue, angular) |
| `requirements.txt`, `pyproject.toml` | Python — mirar deps para framework (django, flask, fastapi) |
| `pom.xml`, `build.gradle` | Java/Kotlin — mirar para Spring Boot, Micronaut |
| `*.csproj`, `*.sln` | .NET — mirar el SDK/target framework |
| `go.mod` | Go |
| `composer.json` | PHP — mirar para Laravel, Symfony |
| `Gemfile` | Ruby — mirar para Rails |

## Señal de motor de DB

Buscar en `.env`, `.env.example`, `docker-compose.yml`, o dependencias del
manifiesto (ej. `pg`/`mysql2`/`mongoose` en Node, `psycopg2`/`SQLAlchemy` en
Python, `Npgsql`/`Microsoft.EntityFrameworkCore.SqlServer` en .NET).

## Flujo

1. Recorrer el/los repo(s) del proyecto buscando las señales de arriba.
2. Para cada capa detectada (DB / backend / frontend), anotar lenguaje,
   framework y evidencia (qué archivo/dependencia lo confirmó).
3. Si una capa es ambigua (ej. dos frameworks de frontend candidatos, o no
   hay señal clara de DB), **preguntar al usuario en vez de asumir** — no
   completar PROJECT.md con una suposición no confirmada.
4. Proponer el `PROJECT.md` completo (usando `templates/PROJECT.md.template`
   del dev-toolkit como base) y mostrarlo antes de escribirlo, para que el
   usuario confirme o corrija.
5. Solo escribir el archivo después de la confirmación explícita del usuario.

## También genera/actualiza el `.gitignore` de la raíz

1. Listar las carpetas de primer nivel que tengan su propio `.git` (repos
   hijos independientes, tipo `backend-x/`, `frontend-x/`).
2. Tomar `templates/.gitignore.template` del dev-toolkit y reemplazar el
   placeholder `{{CHILD_REPOS}}` con una línea `nombre-carpeta/` por cada
   repo hijo detectado.
3. Si ya existe un `.gitignore` en la raíz, **no pisarlo silenciosamente**:
   mostrar el diff propuesto (qué carpetas nuevas se agregarían) y esperar
   confirmación del usuario antes de escribir.
4. Si aparece un repo hijo nuevo en una corrida posterior (ej. el usuario
   agregó `mobile-x/` más adelante), agregar solo esa línea nueva sin tocar
   el resto del archivo.

## DON'T
- No inventar convenciones de commits/branches que no estén documentadas en
  el repo (ej. no asumir Conventional Commits si no hay evidencia).
- No sobrescribir un `PROJECT.md` existente sin mostrar antes qué cambiaría.
