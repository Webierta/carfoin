# Changelog

Este archivo registra y documenta los cambios más notables a lo largo del desarrollo del proyecto.

## [3.2.2] - 2024-08-05

### Fixed

- Buscar por ISIN.
- Exportar base de datos.

### Changed

- Actualizadas dependencias.

## [3.2.1] - 2024-01-11

### Changed

- Nueva firma de aplicación: Para aumentar la seguridad, se ha sustituido una clave de depuración temporal por una clave adecuada para su publicación. Esto supone que para actualizar desde una versión anterior es necesario desinstalar primero la vieja versión antes de instalar esta nueva versión.

## [3.2.0] - 2023-12-30

### Added

- Añadida compatibilidad con sistemas Linux (esto ha supuesto, entre otras cosas, el cambio de la ubicación de la base de datos para mayor estabilidad y rendimiento, por lo que es necesario tener una COPIA DE SEGURIDAD ANTES DE ACTUALIZAR).
- Nuevo sistema de notas como recordatorio periódico para hacer copias de seguridad.

### Fixed

- Corregido refresco de pantalla después de importar base de datos.

### Changed

- Actualizadas dependencias.
- Dependencias adaptadas a Linux (base de datos, manejo de permisos, reiniciar aplicación, compartir archivos, limpiar caché).
- Código saneado.

### Removed

- Eliminadas dependencias para reiniciar la aplicación.

## [3.1.1] - 2023-12-28

### Fixed

- Corregida migración de la base de datos desde versión 2 a 3 (ahora es compatible con la versión anterior).

## [3.1.0] - 2023-12-27

### Added

- Add this CHANGELOG file.
- Los fondos sin ticker, se actualizan en la base de datos con nuevo ticker.

### Changed

- Database versión 3: almacén del ticker de cada fondo (posible incompatibilidad con versiones anteriores).
- Consulta optimizada de precios por el ticker de Yahoo Finance.

### Fixed

- Corregidos varios errores.

## [3.0.0] - 2023-12-25

### Added

- Nueva API Yahoo Finance.
- Añadida consulta online por nombre del fondo.
- Nueva función para obtener la divisa del fondo buscado a través de la base de datos local.

### Changed

- Cambiada base de datos local.
- Nuevo visor pdf (eliminada librería comercial).
- Código reescrito.
- Dependencias actualizadas.

### Fixed

- Corregidos varios errores.

## [2.0.4] - 2022-10-16

### Added

- New light and dark themes.

## [2.0.3] - 2022-10-08

### Added

- Ready for F-Droid.

## [2.0.2] - 2022-10-06

### Changed

- Update plugins-dependencies.

## [2.0.1] - 2022-10-06

### Changed

- Changed fastlane directory structure.

## [2.0.0] - 2022-10-05

### Added

- Nuevo visor de PDF.
- Posibilidad de seleccionar destino para guardar los pdf generados.
- Nuevo servicio de reporte de errores.
- Nuevo modo de vista compacta para fondos.

### Changed

- Reducción de dependencia de librerías de terceros.
- Código optimizado con importante reducción de tamaño de APK.
- Retoques de UI (adaptación a Material 3 en progreso).

### Fixed

- Corregidos errores y mejorada estabilidad.

## [1.3.0] - 2022-09-26

### Added

- Nueva función para visualizar y descargar documentos en pdf de los fondos (folleto y último informe periódico).
- Nueva función que obtiene y actualiza mensualmente el Rating de Morningstar.

### Changed

- Base de datos incompatible con versiones anteriores (y con copias de seguridad y carteras generadas con versiones anteriores).

### Removed

- Eliminada librería de terceros que producía errores.

### Fixed

- Corregidos varios errores y mejorada fluidez y estabilidad.

## [1.2.5] - 2022-09-19

### Added

- Nueva funcionalidad que permite combinar operaciones en una misma fecha.

### Changed

- Mejoras de rendimiento.

### Fixed

- Corregidos errores.

## [1.2.4] - 2022-09-15

### Added

- Nueva Sección de Mantenimiento en Ajustes (archivo logfile).
- Las operaciones se muestran en el gráfico de valores.

### Fixed

- Varias correcciones.

## [1.2.3] - 2022-09-13

- First beta release.
- Adaptación a Android de la idea del Proyecto del mismo autor [Carfoin$](https://github.com/Webierta/carfoins).

[3.2.2]: https://github.com/Webierta/carfoin/compare/v3.2.1...v3.2.2
[3.2.1]: https://github.com/Webierta/carfoin/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/Webierta/carfoin/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/Webierta/carfoin/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/Webierta/carfoin/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/Webierta/carfoin/compare/v2.0.4...v3.0.0
[2.0.4]: https://github.com/Webierta/carfoin/compare/v2.0.3...v2.0.4
[2.0.3]: https://github.com/Webierta/carfoin/compare/v2.0.2...v2.0.3
[2.0.2]: https://github.com/Webierta/carfoin/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/Webierta/carfoin/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/Webierta/carfoin/compare/v1.3.0...v2.0.0
[1.3.0]: https://github.com/Webierta/carfoin/compare/v1.2.5...v1.3.0
[1.2.5]: https://github.com/Webierta/carfoin/compare/v1.2.4...v1.2.5
[1.2.4]: https://github.com/Webierta/carfoin/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/Webierta/carfoin/releases/tag/v1.2.3

