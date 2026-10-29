# TodoenOrden

Una pequeña aplicación web, pensada para el móvil, para quienes comparten piso. Reúne en un solo lugar la logística del día a día: quién vive en casa, qué hay que comprar, a quién le toca limpiar esta semana y qué facturas están por vencer.

Toda la aplicación es un único archivo, [`todoenorden_v2.html`](todoenorden_v2.html), sin necesidad de compilar nada.

## Acceso a la aplicación

Entra aquí: <https://github.com/ManuCem/TodoEnOrden/pull/new/add-readme>

## Funcionalidades

La aplicación tiene cuatro secciones, accesibles desde la barra de navegación inferior.

| Sección | Qué hace |
| --- | --- |
| **Piso** | Muestra el código de invitación del piso (6 letras, con aspecto de letras magnéticas de nevera) con un botón para copiarlo, la lista de compañeros, la opción de cambiar tu nombre y la opción de salir del piso. |
| **Compra** | Lista de la compra compartida. Puedes añadir productos, marcarlos como comprados o quitarlos. No se permiten nombres duplicados. |
| **Limpieza** | Define las zonas de limpieza (baño, cocina, salón...). Cada semana las zonas pasan al siguiente compañero. Solo puedes marcar como hechas tus propias tareas, y una barra de progreso muestra cuántas se han completado, con el color de quien las limpió. |
| **Facturas** | Da de alta facturas periódicas (nombre, importe, frecuencia, próximo vencimiento y quién adelanta el dinero). Se ordenan por fecha de vencimiento y se marcan como «vence hoy», «en unos días» o «vencida». Frecuencias: semanal, mensual, bimestral, trimestral y anual. |

### Primeros pasos

La primera vez escribes tu nombre y después puedes elegir entre:

- **Crear un piso**, que te da un código de 6 caracteres para compartir con tus compañeros.
- **Unirte a un piso** escribiendo el código que te haya dado un compañero.

Cada compañero recibe su propio color de «imán» (seis colores, asignados según el orden en que entró al piso). La aplicación se adapta automáticamente al modo claro y al modo oscuro.

## Cómo funciona

- **Interfaz:** HTML, CSS y JavaScript puro en un solo archivo. La tipografía Archivo se carga desde Google Fonts.
- **Base de datos:** [Supabase](https://supabase.com) (Postgres y autenticación), cargado desde un CDN mediante `@supabase/supabase-js`.
- **Autenticación:** inicio de sesión anónimo. No hay correo ni contraseña: cada navegador recibe su propio usuario anónimo. Por eso, si borras los datos del navegador, pierdes el acceso a ese usuario y tendrás que volver a unirte al piso con el código de invitación.
- **Datos que utiliza:** las tablas `profiles`, `apartments`, `apartment_members`, `shopping_items`, `cleaning_zones`, `cleaning_assignments` y `recurring_bills`, y las funciones de base de datos `create_apartment`, `join_apartment` y `ensure_week_assignments`. El acceso está protegido con seguridad a nivel de fila (row-level security) de Postgres.

## Cómo ejecutarla

1. Clona el repositorio y abre `todoenorden_v2.html` en un navegador (con doble clic, o sirviendo la carpeta con cualquier servidor estático).
2. La aplicación se conecta al proyecto de Supabase configurado al principio del script (`SUPABASE_URL` y `SUPABASE_KEY`). Esa clave es una clave publicable (pública), pensada para usarse en el navegador; los datos están protegidos por la seguridad a nivel de fila.
3. En el panel de Supabase hay que activar **Allow anonymous sign-ins** en **Authentication → Sign In / Providers**. Si no está activado, la aplicación muestra un error de conexión con estos mismos pasos.

### Modo de ejemplo

Para probar la aplicación sin base de datos, añade `?demo` a la dirección, por ejemplo `todoenorden_v2.html?demo`. Carga datos de ejemplo en memoria (un piso con tres compañeros, una lista de la compra, zonas de limpieza y tres facturas). No se guarda nada y la cabecera muestra «Datos de ejemplo». También puedes entrar al modo de ejemplo desde la pantalla de error de conexión.

## Usar tu propio proyecto de Supabase

Para ejecutar tu propia copia en lugar del servidor actual:

1. Crea un proyecto en Supabase y activa el inicio de sesión anónimo.
2. Crea las tablas y funciones indicadas arriba, con políticas de seguridad a nivel de fila que limiten cada tabla a los miembros del mismo piso.
3. Sustituye `SUPABASE_URL` y `SUPABASE_KEY` al principio del script por la URL y la clave publicable de tu proyecto.

## Colaboración

Quien necesite editar el proyecto debe añadirse como colaborador en **Settings → Collaborators** de GitHub. Lo mejor es proponer los cambios en una rama mediante una pull request.
