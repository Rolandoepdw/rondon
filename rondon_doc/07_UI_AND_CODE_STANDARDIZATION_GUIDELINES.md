---
tags:
  - ui-ux
  - flutter
  - standardization
  - code-conventions
created: 2026-10-18
---

# 07. Guía Universal de Arquitectura de UI y Código (Flutter)

## 1. Filosofía y Objetivo

Esta guía establece el **Blueprint y Estándar Universal** para construir la capa de presentación en aplicaciones Flutter con **Clean Architecture**, **GetIt** y **Cubit**.

La premisa fundamental es: **Cualquiera que sea la aplicación o la entidad del dominio, la estructura del código, la inyección de dependencias, el ciclo de vida de los formularios, las convenciones de Cubit y la arquitectura del sistema de diseño deben seguir exactamente el mismo patrón.**

---

## 2. Inyección de Dependencias y Contenedor de Servicio (GetIt + Cubit)

Todas las dependencias de la aplicación se registran en `injection_container.dart` utilizando `GetIt` (`sl`):

* **Data Sources & Repositories**: Se registran como `registerLazySingleton`.
* **Use Cases**: Se registran como `registerLazySingleton`.
* **Cubits**: Se registran como `registerFactory` para garantizar una instancia fresca por pantalla/módulo.
* **Prohibición**: Las vistas **nunca instancian Cubits ni Repositorios manualmente** con `new`. Consumen la instancia mediante `context.read<[Entity]Cubit>()` o `sl<[Entity]Cubit>()`.

---

## 3. Clasificación de Entidades y Patrones de Navegación UX

El volumen de información y la complejidad de las relaciones de una entidad determinan su patrón de UI/UX para evitar la sobre-navegación y mantener el Principio de Responsabilidad Única por Pantalla.

```
                  ┌──────────────────────────────────────────────┐
                  │    ¿Volumen y Complejidad de la Entidad?     │
                  └──────────────────────┬───────────────────────┘
                                         │
                   ┌─────────────────────┴─────────────────────┐
                   ▼                                           ▼
      [ENTIDADES COMPLEJAS / ALTO VOLUMEN]          [ENTIDADES SIMPLES / BAJO VOLUMEN]
      - Múltiples campos o secciones               - 2 a 4 campos simples
      - Relaciones con búsqueda/filtros            - Etiquetas, textos cortos o flags
      - Histórico o métricas detalladas            - El Card muestra toda la información
                   │                                           │
                   ▼                                           ▼
        PATRÓN: NAVEGACIÓN PÁGINAS                   PATRÓN: NAVEGACIÓN MODAL / FAB
     (List -> Detail -> Full Form Page)             (List -> Modal/BottomSheet Form)
```

---

### Patrón A: Entidades Complejas / Alto Volumen (Full Page Navigation)

Aplica cuando la entidad posee un volumen de datos que no cabe legiblemente en una tarjeta de lista o requiere sub-entidades avanzadas con búsqueda o selección múltiple.

* **List View (`[Entities]Page`)**: Presenta tarjetas resumidas de alto nivel.
* **Detail View (`[Entity]DetailPage`)**: **Obligatoria**. Muestra la información completa, gráficos, tablas relacionadas o miembros.
* **Form View (`[Entity]FormPage`)**: Página completa (`Page Route`).

#### Flujos de Navegación Estándar:
1. **Creación**:
   `[Entities]Page` -> Tap en FAB -> `[Entity]FormPage (Modo Crear)` -> Guardar -> `Navigator.pop()` -> Regresa a `[Entities]Page` actualizada.
2. **Visualización y Edición**:
   `[Entities]Page` -> Tap en Card -> `[Entity]DetailPage` -> Tap en Editar -> `[Entity]FormPage (Modo Editar)` -> Guardar -> `Navigator.pop()` -> Regresa a `[Entity]DetailPage` actualizada.
3. **Eliminación desde Detalle**:
   `[Entity]DetailPage` -> Tap en Eliminar -> Diálogo de Confirmación -> Confirmar -> `Navigator.pop()` -> Regresa a `[Entities]Page`.

---

### Patrón B: Entidades Simples / Bajo Volumen (Lightweight Modal Navigation)

Aplica cuando la entidad tiene pocos inputs o información compacta (ej. tags, configuraciones cortas, categorías simples) donde la tarjeta en el listado actúa como vista de detalle suficiente.

* **List View (`[Entities]Page`)**: La tarjeta muestra toda la información relevante de la entidad. **No requiere vista de detalle**.
* **Form View (`[Entity]BottomSheet` / `[Entity]Dialog`)**: Modal ligero o BottomSheet sin salir de la pantalla principal.

#### Flujos de Navegación Estándar:
1. **Creación**:
   `[Entities]Page` -> Tap en FAB -> Abre `[Entity]BottomSheet (Modo Crear)` -> Guardar -> Cierra Modal -> Actualiza `[Entities]Page`.
2. **Edición**:
   `[Entities]Page` -> Tap en Editar (Botón de Acción / FAB) -> Abre `[Entity]BottomSheet (Modo Editar)` -> Guardar -> Cierra Modal -> Actualiza `[Entities]Page`.
3. **Eliminación**:
   `[Entities]Page` -> Tap en Eliminar (Botón de Acción / FAB) -> Diálogo de Confirmación -> Confirmar -> Actualiza `[Entities]Page`.

---

## 4. Separación Estricta de Efectos Secundarios (BlocBuilder vs. BlocListener vs. BlocConsumer)

1. **`BlocBuilder`**: Exclusivamente para renderizar widgets en respuesta a cambios de estado. **Prohibido** ejecutar navegación (`Navigator.pop`) o mostrar `SnackBar` en su callback.
2. **`BlocListener`**: Exclusivamente para efectos secundarios de una sola ejecución (mostrar `SnackBar`, abrir diálogos, navegar tras guardar con éxito).
3. **`BlocConsumer`**: Se utiliza cuando una pantalla requiere tanto renderizado visual como reacciones a efectos secundarios de forma simultánea.

---

## 5. Arquitectura de Sistema de Diseño en 4 Capas

1. **Capa 1: Design Tokens**: Clases estáticas puras (`AppColors`, `AppSizes`, `AppTextStyles`, `AppShadows`, `AppBorders`).
2. **Capa 2: Theme System & Extensions**: Configuración de `ThemeData` global y extensiones mediante `ThemeExtension<T>` y `Theme.of(context)`.
3. **Capa 3: Componentes Reutilizables**:
   - **Core UI Widgets**: `AppButton`, `AppCard`, `AppTextField`, `AppEmptyState`, `AppTile`, `AppBadge`.
   - **Widgets Artesanales**: Componentes visuales a medida del proyecto.
4. **Capa 4: Pantallas & Gestión de Estado**: Vistas principales desacopladas conectadas con sus Cubits.

---

## 6. Ordenación Interna de Código en Clases Flutter (Class Member Order)

Toda clase `State<T>` o `StatelessWidget` debe ordenar sus miembros con la siguiente secuencia exacta:

1. `// 1. Keys, Controllers & Local State` (`GlobalKey<FormState>`, `TextEditingController`, variables de estado).
2. `// 2. Lifecycle Methods` (`initState()`, `didChangeDependencies()`, `dispose()`).
3. `// 3. Build Method` (`Widget build(BuildContext context)`).
4. `// 4. Action Handlers & Async Callbacks` (`_handleSubmit()`, `_handleDelete()`, etc.).
5. `// 5. Helper UI Builders` (`_buildFormFields()`, `_buildHeader()`, etc.).

---

## 7. Reglas de Higiene de Código y Linter (Code Health)

1. **Imports Absolutos de Paquete**: Usar `import 'package:nombre_proyecto/...';` en lugar de rutas relativas con subidas de directorio (`../../..`).
2. **Logging Estructurado**: Prohibido el uso de `print()`. 
   * Usar el servicio `AppLogger` (si está disponible) o `dev.log('mensaje', name: 'CATEGORIA')` de `dart:developer`.
   * Categorías estándar: `DATABASE`, `SQUADS`, `NEIGHBORS`, `SHIFTS`, `TEMPLATES`, `CUBIT`.
   * Usar colores ANSI para diferenciar operaciones CRUD: 🟩 Create, 🟦 Read, 🟨 Update, 🟥 Delete.
