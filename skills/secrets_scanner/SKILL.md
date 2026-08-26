---
name: secrets_scanner
description: Detecta si archivos de ejemplo/template de entorno (ejm.env, .env.example, .env.sample, .env.template) contienen valores reales en vez de placeholders, y si algún archivo con secretos quedó commiteado al historial de git. Úsalo antes de un commit, cuando el usuario pida escanear secretos, o cuando el health check detecte un archivo de ejemplo sospechoso.
---

# Secrets Scanner

Rol de **solo lectura y análisis** — nunca modificás archivos ni credenciales,
solo reportás hallazgos y recomendás la acción.

## Paso 1 — Encontrar archivos de ejemplo/template

Buscar en cada repo del proyecto (raíz y repos hijos) archivos que matcheen:
`ejm.env`, `.env.example`, `.env.sample`, `.env.template`, `*.env.example`.
Estos son los que **deberían** tener placeholders, no valores reales — a
diferencia de `.env`/`.env.local`, que sí tienen secretos reales por diseño y
no se escanean acá (se asume que están en `.gitignore`).

## Paso 2 — Distinguir placeholder de valor real

Para cada línea `CLAVE=valor` del archivo de ejemplo, clasificar `valor`:

**Probable placeholder** (no alertar):
- Contiene `your-`, `xxx`, `<...>`, `CHANGE_ME`, `example`, `REPLACE`,
  `placeholder`, o está vacío.

**Probable valor real** (alertar):
- JWT (empieza con `eyJ`), API key con formato reconocible (`AKIA...` de AWS,
  `sk_live_...`/`sk_test_...` de Stripe, etc.), strings largos alfanuméricos
  aleatorios sin patrón de placeholder, o cualquier valor que coincida
  exactamente con algo presente en el `.env` real del mismo repo (fuerte
  indicio de que se copió el valor real por error).

## Paso 3 — Confirmar exposición en git

Para cada archivo de ejemplo con valores reales sospechosos:

1. Confirmar si el archivo está en `.gitignore`:
   ```
   git check-ignore -v <archivo>
   ```
   Si está ignorado, el riesgo baja (nunca entró al historial) — igual
   recomendar reemplazar el valor por un placeholder, pero sin urgencia.

2. Si **no** está ignorado, revisar si ya fue commiteado:
   ```
   git log --all --oneline -- <archivo>
   ```
   Si hay commits, el secreto ya quedó en el historial de git — borrarlo del
   archivo hoy NO lo elimina del historial.

## Paso 4 — Reportar

Tabla: archivo | clave sospechosa | ¿ignorado? | ¿commiteado alguna vez? |
severidad | acción recomendada.

- Ignorado + nunca commiteado → severidad baja, acción: "reemplazar por
  placeholder cuando puedas".
- No ignorado + commiteado → severidad crítica, acción: "rotar la credencial
  en el proveedor (Supabase/AWS/etc.) YA, además de limpiar el archivo".

## DON'T
- No mostrar el valor real de la credencial en el reporte — solo el nombre de
  la variable y la clasificación de riesgo.
- No intentar limpiar el historial de git vos mismo (`filter-repo`, etc.) sin
  que el usuario lo pida explícitamente — es una operación destructiva que
  requiere que el usuario entienda las consecuencias (reescribe hashes de
  commits, afecta a quien tenga el repo clonado).
