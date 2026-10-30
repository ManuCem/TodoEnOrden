# [TodoenOrden](https://manucem.github.io/TodoEnOrden/index.html)

Aplicación web para la gestión colaborativa de pisos compartidos. Proyecto universitario.

**Acceso a la aplicación:** <https://manucem.github.io/TodoEnOrden/index.html>

## 1. Descripción

TodoenOrden centraliza la organización doméstica de las personas que comparten vivienda: la composición del piso, la compra común, el reparto de tareas de limpieza y el seguimiento de las facturas periódicas. Está diseñada con un enfoque *mobile-first* y se entrega como un único archivo HTML, sin proceso de compilación.

## 2. Funcionalidades

| Módulo | Descripción |
| --- | --- |
| **Alta inicial** | Pantalla de bienvenida: el usuario indica su nombre y crea un piso (recibe un código de 6 caracteres) o se une a uno existente con ese código. |
| **Piso** | Muestra el código de invitación (con botón para copiarlo) y el listado de compañeros, con un color por persona. Permite cambiar el nombre propio y salir del piso. Antes de salir, la aplicación consulta el saldo del usuario y avisa de si tiene deudas pendientes, si le deben dinero o si sus cuentas están saldadas. |
| **Compra** | Lista de la compra compartida: alta, edición del nombre, marcado como comprado/pendiente y eliminación de productos, con contador de pendientes. No admite nombres duplicados. |
| **Limpieza** | Definición de zonas de limpieza (sin duplicados) y asignación semanal automática: cada semana (de lunes a domingo) las zonas rotan al siguiente compañero. Muestra el progreso de la semana y la fecha de realización. Cada usuario solo puede marcar como hechas sus propias tareas. |
| **Facturas** | Alta de facturas periódicas con nombre, importe, frecuencia (semanal, mensual, bimestral, trimestral o anual), fecha de vencimiento y persona que adelanta el pago. Validación de campos con mensajes de error. Se listan ordenadas por vencimiento, con indicación de estado (vencida, vence hoy, mañana, en N días); las pausadas no se muestran. |
| **Avisos** | Si alguna factura vence en menos de 3 días (o ya ha vencido), aparece un aviso en la cabecera de las demás pestañas que lleva directamente a Facturas. |

## 3. Arquitectura y tecnologías

- **Cliente:** HTML5, CSS3 y JavaScript sin dependencias de *frameworks*. Diseño adaptable con soporte de modo claro y oscuro.
- **Backend:** [Supabase](https://supabase.com) (PostgreSQL y servicio de autenticación), accedido mediante `@supabase/supabase-js`.
- **Autenticación:** inicio de sesión anónimo; no se almacenan correos ni contraseñas.
- **Seguridad de los datos:** políticas de seguridad a nivel de fila (*row-level security*) de PostgreSQL.
- **Sesión:** se conserva en el almacenamiento del navegador, con alternativa en memoria si este no está disponible.
- **Modelo de datos:** tablas `profiles`, `apartments`, `apartment_members`, `shopping_items`, `cleaning_zones`, `cleaning_assignments` y `recurring_bills`; vista `apartment_balances` (saldo por usuario); y funciones `create_apartment`, `join_apartment` y `ensure_week_assignments`.
- **Capa de datos:** la interfaz accede a los datos a través de una API interna con dos implementaciones intercambiables: Supabase y una versión en memoria para el modo demostración.
- **Gestión de errores:** si no hay conexión, la aplicación muestra una pantalla con instrucciones (por ejemplo, activar el acceso anónimo) y opciones de reintentar o abrir los datos de ejemplo.
- **Despliegue:** GitHub Pages.

## 4. Ejecución

**En línea:** accede a la [aplicación desplegada](https://manucem.github.io/TodoEnOrden/index.html).

**En local:** clona el repositorio y abre `index.html` en un navegador. Requiere conexión a internet y que el inicio de sesión anónimo esté activado en el proyecto de Supabase (*Authentication → Sign In / Providers → Allow anonymous sign-ins*).

**Modo demostración:** al añadir `?demo` a la dirección se cargan datos de ejemplo en memoria, sin necesidad de base de datos. Nada se guarda.

## 5. Estructura del repositorio

| Archivo | Contenido |
| --- | --- |
| `index.html` | Aplicación completa (interfaz y lógica). |
| `README.md` | Documentación del proyecto. |
