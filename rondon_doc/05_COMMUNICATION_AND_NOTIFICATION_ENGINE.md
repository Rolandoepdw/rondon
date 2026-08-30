---
tags:
  - communications
  - whatsapp
  - notifications
created: 2026-08-29
---

# 05. Motor de Comunicación y Notificaciones

## 1. Estrategia de Comunicación

La comunicación se basa en **despacho asistido hacia WhatsApp**:
1. El sistema genera el texto reemplazando variables.
2. La app abre WhatsApp (`wa.me`) con el mensaje pre-cargado.
3. El Administrador confirma el envío.

---

## 2. Motor de Plantillas de Mensajes

### 2.1. Variables de Sustitución

- `{VECINO_NOMBRE}`: Nombre del destinatario.
- `{FECHA}`: Fecha legible.
- `{TURNO_NOMBRE}`: Nombre de la plantilla (ej. "Turno Madrugada").
- `{HORARIO}`: Franja horaria.
- `{COMPANEROS}`: Lista de compañeros.
- `{ROL_PARTICIPANTE}`: "Titular" o "Refuerzo".

### 2.2. Plantillas Predeterminadas

> [!INFO] Plantilla A: Recordatorio Individual
> ```text
> 🚨 *RECORDATORIO DE GUARDIA VECINAL* 🚨
> 
> Hola *{VECINO_NOMBRE}*, te recordamos tu compromiso:
> 📅 *Fecha:* {FECHA}
> ⏰ *Horario:* {HORARIO} ({TURNO_NOMBRE})
> 👥 *Compañeros:* {COMPANEROS}
> 📌 *Condición:* {ROL_PARTICIPANTE}
> 
> ¡Gracias por cuidar nuestro barrio! 🛡️
> ```

---

## 3. Notificaciones Locales (Admin)

El sistema programa alarmas locales para asegurar el cumplimiento de los procesos:

> [!IMPORTANT] Programación de Alertas
> 1. **Mañana (08:00 AM):** Disparar auditoría de la noche anterior.
> 2. **Tarde (20:00 PM):** Disparar envío de recordatorios para la noche actual.

---

## 4. Implementación Técnica

- **Lanzador de URLs:** Uso de `url_launcher` para esquemas `https://wa.me/` y `whatsapp://send`.
- **Sanitización:** Normalización de números telefónicos (remover caracteres no numéricos, añadir código de país).
- **Fallback:** Si WhatsApp no está instalado, se ofrece "Copiar al portapapeles".

Ver también:
- [[04_ADMIN_INTERFACE_AND_UX_FLOWS#2.1. Pantalla 1: Dashboard / Vista de Hoy (HomeScreen)|Acciones desde Dashboard]]
