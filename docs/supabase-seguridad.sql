-- TodoenOrden: refuerzo de seguridad en Supabase.
-- Se ejecuta en Supabase → SQL Editor. Es seguro repetirlo.
-- Ejecuta ANTES docs/supabase-cuentas.sql (necesita la columna apartments.owner_id).

-- 1) El admin del piso no se puede cambiar editando la tabla desde el cliente.
--    Solo cambia a través de las funciones leave_apartment / delete_my_account.
create or replace function public._proteger_owner() returns trigger
language plpgsql set search_path = public as $$
begin
  if new.owner_id is distinct from old.owner_id and current_user in ('authenticated', 'anon') then
    raise exception 'El admin solo cambia al salir del piso';
  end if;
  return new;
end; $$;
drop trigger if exists trg_proteger_owner on public.apartments;
create trigger trg_proteger_owner before update on public.apartments
  for each row execute function public._proteger_owner();

-- 2) Límites en el perfil: una foto solo puede ser un JPEG reducido o una foto de Google,
--    y el nombre no puede ser enorme. (not valid = no revisa filas antiguas, sí las nuevas)
do $$ begin
  alter table public.profiles add constraint profiles_avatar_valida check (
    avatar_url is null or (
      length(avatar_url) < 70000 and (
        avatar_url ~ '^data:image/jpeg;base64,[A-Za-z0-9+/=]+$'
        or avatar_url ~* '^https://[a-z0-9.-]+\.googleusercontent\.com/'))) not valid;
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.profiles add constraint profiles_nombre_corto check (
    full_name is null or length(full_name) <= 60) not valid;
exception when duplicate_object then null; end $$;

-- 3) AUDITORÍA (solo lectura): ejecútalas una a una y revisa el resultado.

-- 3a) Todas las tablas deben salir con rowsecurity = true.
select tablename, rowsecurity from pg_tables where schemaname = 'public' order by tablename;

-- 3b) Políticas existentes: comprueba que cada una limita por pertenencia al piso o por auth.uid().
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies where schemaname = 'public' order by tablename, policyname;

-- 3c) Funciones que puede ejecutar el rol anónimo (no debería salir ninguna sensible).
select routine_name from information_schema.routine_privileges
where routine_schema = 'public' and grantee in ('anon', 'PUBLIC') order by routine_name;
