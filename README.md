<div align="center">

# 🏠 [TodoenOrden](https://manucem.github.io/TodoEnOrden/index.html)

**El piso compartido, sin líos: compra, limpieza y facturas en un solo sitio.**

![HTML5](https://img.shields.io/badge/HTML5-single%20file-E34F26?logo=html5&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Postgres%20%2B%20Auth-3ECF8E?logo=supabase&logoColor=white)
![Google](https://img.shields.io/badge/Login-Google%20OAuth-4285F4?logo=google&logoColor=white)
![GitHub Pages](https://img.shields.io/badge/Deploy-GitHub%20Pages-222?logo=github&logoColor=white)
![Mobile first](https://img.shields.io/badge/Mobile-first-8A2BE2)

### 👉 [**Abrir la aplicación**](https://manucem.github.io/TodoEnOrden/index.html) · [**Probar el modo demo**](https://manucem.github.io/TodoEnOrden/index.html?demo)

</div>

---

## 📸 Así se ve

> Capturas del modo demostración (datos de ejemplo).

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/piso.png" width="230" alt="Piso"><br><b>Piso</b><br><sub>turno, código, invitación y compañeros</sub></td>
    <td align="center"><img src="docs/screenshots/compra.png" width="230" alt="Compra"><br><b>Compra</b><br><sub>lista compartida por días</sub></td>
    <td align="center"><img src="docs/screenshots/limpieza.png" width="230" alt="Limpieza"><br><b>Limpieza</b><br><sub>rotación semanal con fotos</sub></td>
    <td align="center"><img src="docs/screenshots/facturas.png" width="230" alt="Facturas"><br><b>Facturas</b><br><sub>reparto y pago de tu parte</sub></td>
  </tr>
</table>

---

## ✨ Qué hace

| | Módulo | Descripción |
| --- | --- | --- |
| 🚪 | **Alta inicial** | El usuario crea un piso (recibe un código de 6 caracteres) o se une a uno con ese código o con un enlace de invitación. |
| 🏠 | **Piso** | Código del piso, compañeros con su foto y color, turno de limpieza del usuario, invitación por enlace o **código QR** y **Ajustes del piso** (salir y eliminar). |
| 🛒 | **Compra** | Lista compartida agrupada por días: alta, edición, marcado como comprado y borrado. Sin duplicados. |
| 🧹 | **Limpieza** | Zonas del piso y reparto semanal automático con rotación (lunes a domingo). Cada persona marca solo sus tareas. Recordatorio del turno e histórico de cumplimiento, con la foto y el nombre de cada compañero. |
| 💶 | **Facturas** | Facturas periódicas (semanal a anual) con importe, vencimiento y quién adelanta el pago. El importe se divide entre los compañeros y cada uno marca su parte. Aviso en la cabecera cuando algo vence en menos de 3 días. |
| 👤 | **Mi perfil** | Cuenta de Google, foto y nombre visibles para el piso, resumen de **todos tus pisos** (código, compañeros, compra, limpieza y facturas) y eliminación de la cuenta. |

---

## 🔐 Cuentas y sesión

La app funciona **desde el primer segundo, sin registrarse**, y permite subir de nivel con Google cuando se quiera.

1. **Sesión anónima.** Al abrir la app, Supabase crea un usuario anónimo. No se piden correo ni contraseña.
2. **Iniciar sesión con Google.** El botón de la cabecera usa OAuth de Google a través de Supabase.
   - Si ya tienes un piso, Google se **enlaza** a tu usuario actual (`linkIdentity`) y no pierdes nada.
   - Si esa cuenta de Google ya existía (otro móvil u otra sesión), la app detecta el aviso de Supabase y **entra con esa cuenta** automáticamente.
3. **Nombre y foto automáticos.** Al entrar con Google se rellena el nombre y se guarda la foto de la cuenta. Después puedes cambiarlos en **Mi perfil → Cambiar foto y nombre de usuario** sin tocar tu cuenta de Google. La foto subida se recorta y se reduce a 160 px y se guarda en la base de datos.
4. **Cerrar sesión.** Vuelve a una sesión anónima nueva.
5. **Eliminar mi cuenta.** Borra tu usuario y tus datos. En cada piso: si eras admin y hay más gente, el admin pasa a una persona **elegida al azar**; si estabas solo, el piso se elimina. Antes de confirmar, la app avisa de qué le pasará a cada piso.

### 👑 Roles: admin del piso

El **admin es quien creó el piso** (`apartments.owner_id`).

| Acción | Quién puede | Qué pasa |
| --- | --- | --- |
| Salir del piso | Cualquiera | Dejas de ver sus datos y puedes volver con el código. La app avisa si tienes deudas o te deben dinero. |
| Salir siendo admin | Admin | Debe **elegir a otra persona como admin** antes de salir. |
| Salir siendo la última persona | Cualquiera | El piso se elimina porque nadie más lo usa. La app lo avisa antes. |
| Eliminar el piso para todos | **Solo el admin** | Borra el piso con su compra, limpieza y facturas, y todos lo pierden. Hay que escribir el nombre del piso para confirmar. |

### 🔗 Invitar a compañeros

Desde **Piso → Código del piso**: **Compartir invitación** (hoja de compartir del móvil o copia el enlace) y **Código QR**. El enlace tiene la forma `…/index.html?codigo=ABC123`. Al abrirlo, la app pregunta **«¿Quieres unirte a este piso?»**; nunca entra sin confirmar. El código se guarda para sobrevivir al inicio de sesión con Google.

---

## 🧱 Arquitectura y tecnologías

- **Cliente:** HTML5, CSS3 y JavaScript sin *frameworks* ni proceso de compilación; un único `index.html`. Diseño *mobile-first* con modo claro y oscuro y estética de tablón de la nevera.
- **Backend:** [Supabase](https://supabase.com) (PostgreSQL + Auth) mediante `@supabase/supabase-js`.
- **Autenticación:** sesión anónima + Google OAuth con enlace de identidades.
- **Seguridad de los datos:** políticas de seguridad a nivel de fila (*row-level security*); la clave pública (`sb_publishable_…`) puede estar en el cliente. Las operaciones delicadas (salir, eliminar piso y cuenta) son funciones `security definer` que comprueban quién llama.
- **QR:** [`qrcode-generator`](https://github.com/kazuhikoarase/qrcode-generator) cargado desde jsDelivr.
- **Capa de datos:** la interfaz usa una API interna con dos implementaciones intercambiables: Supabase y una versión en memoria para el **modo demostración**.
- **Tolerancia a fallos:** si faltan las columnas `avatar_url` u `owner_id`, la app sigue funcionando con el comportamiento anterior en vez de romperse. Si no hay conexión, muestra instrucciones y opciones de reintentar o abrir la demo.
- **Despliegue:** GitHub Pages.

### 🗄️ Modelo de datos (Supabase)

| Elemento | Para qué sirve |
| --- | --- |
| `profiles` | Nombre (`full_name`) y foto (`avatar_url`) de cada usuario. |
| `apartments` | Pisos: nombre, código de invitación y **admin** (`owner_id`). |
| `apartment_members` | Quién pertenece a qué piso. |
| `shopping_items` | Lista de la compra. |
| `cleaning_zones` · `cleaning_assignments` | Zonas y turnos semanales. |
| `recurring_bills` · `bill_payments` | Facturas periódicas y pagos por persona. |
| Vista `apartment_balances` | Saldo de cada usuario en el piso. |
| Funciones | `create_apartment`, `join_apartment`, `ensure_week_assignments`, `current_week_start`, `advance_bill`, `leave_apartment`, `delete_apartment`, `delete_my_account`. |

---

## 🚀 Puesta en marcha

### Usarla
**En línea:** <https://manucem.github.io/TodoEnOrden/index.html>
**Modo demo (sin base de datos):** añade `?demo` a la dirección. Nada se guarda. También puedes abrir una pestaña concreta con `?demo&tab=compra` (`piso`, `compra`, `limpieza` o `facturas`).
**En local:** clona el repositorio y abre `index.html` (necesita internet y los ajustes de Supabase de abajo).

### Montar tu propio Supabase + Google

1. **Supabase.** Crea un proyecto y las tablas del modelo de datos (con RLS).
2. **Sesión anónima.** *Authentication → Sign In / Providers →* activa **Allow anonymous sign-ins**.
3. **Enlazar identidades.** En la misma pantalla activa **Enable manual linking**.
4. **Google Cloud.** Crea un proyecto → *Google Auth Platform*: configura la pantalla de consentimiento como **Externa**, **publícala**, y crea un **cliente OAuth de tipo Aplicación web**. En *URI de redirección autorizados* pega el *Callback URL* que muestra Supabase (`https://<tu-proyecto>.supabase.co/auth/v1/callback`).
5. **Proveedor Google.** En Supabase, *Providers → Google*: activa el proveedor y pega el **Client ID** y el **Client Secret**. *(El secreto va solo en el panel de Supabase, nunca en el repositorio.)*
6. **URLs.** *Authentication → URL Configuration*: pon la **Site URL** y añade la dirección de la app en **Redirect URLs**.
7. **SQL de cuentas.** Ejecuta [`docs/supabase-cuentas.sql`](docs/supabase-cuentas.sql) en el *SQL Editor* (foto de perfil, admin del piso, salir y eliminar).
8. **Cliente.** Cambia `SUPABASE_URL` y `SUPABASE_KEY` al inicio del script de `index.html`.

> ℹ️ Plan gratuito: Google OAuth y Supabase Free no tienen coste. Un proyecto de Supabase sin actividad durante ~7 días se pausa y se reactiva con un clic.

---

## 📁 Estructura del repositorio

| Ruta | Contenido |
| --- | --- |
| `index.html` | Aplicación completa (interfaz y lógica). |
| `docs/supabase-cuentas.sql` | SQL de cuentas: foto, admin del piso, salir y eliminar. |
| `docs/screenshots/` | Capturas del modo demo usadas en este README. |
| `README.md` | Documentación del proyecto. |

---

<div align="center">
<sub>Proyecto universitario · Hecho con ☕, HTML y Supabase</sub>
</div>
