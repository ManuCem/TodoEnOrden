# [TodoenOrden](https://github.com/ManuCem/TodoEnOrden/blob/main/index%20(11).html)

Aplicación web para la gestión colaborativa de pisos compartidos. Proyecto universitario.

**Acceso a la aplicación:** <https://manucem.github.io/TodoEnOrden/index.html>

## 1. Descripción

TodoenOrden centraliza la organización doméstica de las personas que comparten vivienda: la composición del piso, la compra común, el reparto de tareas de limpieza y el seguimiento de las facturas periódicas. Está diseñada con un enfoque *mobile-first* y se entrega como un único archivo HTML, sin proceso de compilación.

## 2. Funcionalidades

| Módulo | Descripción |
| --- | --- |
| **Piso** | Creación de un piso o incorporación mediante un código de invitación de 6 caracteres. Listado de compañeros, edición del nombre propio y salida del piso. |
| **Compra** | Lista de la compra compartida: alta de productos, marcado como comprados y eliminación. No admite nombres duplicados. |
| **Limpieza** | Definición de zonas de limpieza con rotación semanal automática entre los compañeros. Cada usuario solo puede marcar como completadas sus propias tareas. |
| **Facturas** | Alta de facturas periódicas (importe, frecuencia, vencimiento y persona que adelanta el pago), ordenadas por fecha de vencimiento con indicación de estado. |

## 3. Arquitectura y tecnologías

- **Cliente:** HTML5, CSS3 y JavaScript sin dependencias de *frameworks*. Diseño adaptable con soporte de modo claro y oscuro.
- **Backend:** [Supabase](https://supabase.com) (PostgreSQL y servicio de autenticación), accedido mediante `@supabase/supabase-js`.
- **Autenticación:** inicio de sesión anónimo; no se almacenan correos ni contraseñas.
- **Seguridad de los datos:** políticas de seguridad a nivel de fila (*row-level security*) de PostgreSQL.
- **Modelo de datos:** tablas `profiles`, `apartments`, `apartment_members`, `shopping_items`, `cleaning_zones`, `cleaning_assignments` y `recurring_bills`, y funciones `create_apartment`, `join_apartment` y `ensure_week_assignments`.
- **Despliegue:** GitHub Pages.

## 4. Ejecución

**En línea:** accede a la [aplicación desplegada](https://manucem.github.io/TodoEnOrden/todoenorden_v2.html).

**En local:** clona el repositorio y abre `todoenorden_v2.html` en un navegador. Requiere conexión a internet y que el inicio de sesión anónimo esté activado en el proyecto de Supabase (*Authentication → Sign In / Providers → Allow anonymous sign-ins*).

**Modo demostración:** al añadir `?demo` a la dirección se cargan datos de ejemplo en memoria, sin necesidad de base de datos. Nada se guarda.

## 5. Estructura del repositorio

| Archivo | Contenido |
| --- | --- |
| `todoenorden_v2.html` | Aplicación completa (interfaz y lógica). |
| `README.md` | Documentación del proyecto. |
