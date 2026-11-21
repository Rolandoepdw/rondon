---
tags:
  - architecture
  - clean-architecture
  - pragmatic
  - flutter
created: 2026-10-18
---

# 08. Guía de Clean Architecture Pragmática (Flutter)

## 1. Introducción y Filosofía

Esta guía documenta la variante **Pragmática / Ágil de Clean Architecture**. Su propósito es maximizar la velocidad de desarrollo en proyectos pequeños y medianos reduciendo el código repetitivo (*boilerplate*) inútil sin comprometer la testabilidad, la inyección de dependencias ni la mantenibilidad.

---

## 2. Pilares de la Variante Pragmática

1. **Clase de Datos Unificada (`EntityModel`)**:
   En lugar de mantener `Entity`, `Model` y `DTO` separados cuando los campos son idénticos, se unifican en una sola clase pura de Dart que contiene atributos, `copyWith`, `Equatable` y serializadores `fromMap`/`toMap`.

2. **Acceso Directo `Cubit -> Repository` en CRUDs Simples**:
   Se eliminan los casos de uso "pasamanos" (ej. `GetUsers` que solo llama a `repository.getUsers()`). El `Cubit` consume directamente la interfaz del repositorio.
   * **Excepción**: Se crean Casos de Uso exclusivamente para lógica de negocio compleja, algoritmos pesados o coordinación multi-repositorio (ej. `GenerateCycleScheduleUseCase`).

3. **Repositorios Directos para Fuentes Únicas**:
   Si la aplicación solo consulta SQLite o solo consulta una API REST, la implementación del Repositorio ejecuta directamente las consultas sin crear clases `DataSource` redundantes.

---

## 3. Perfiles de Organización de Carpetas

### Perfil A: Estructura por Capas Globales (*Layer-First*)
Recomendada para micro-aplicaciones o MVPs de 1 a 4 entidades:
* `lib/data/`: `EntityModels` e `Implementaciones de Repositorios`.
* `lib/domain/`: `Contratos de Repositorios` y `Casos de Uso Complejos`.
* `lib/presentation/`: `Cubits` y `Pantallas/Widgets`.

### Perfil B: Estructura por Módulos (*Feature-First*)
Recomendada para proyectos de 5 o más entidades:
* `lib/features/[nombre_feature]/`: Contiene el modelo, repositorio, cubit y vistas del módulo juntas.
