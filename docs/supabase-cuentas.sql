-- TodoenOrden: añadidos de cuentas (foto de perfil, admin del piso, salir y eliminar).
-- Se ejecuta una vez en Supabase → SQL Editor. Es seguro repetirlo.
-- Requiere que ya existan las tablas base: profiles, apartments, apartment_members, etc.

-- 1) Foto de perfil visible para los compañeros
alter table public.profiles add column if not exists avatar_url text;

-- 2) Admin del piso = quien lo creó
alter table public.apartments add column if not exists owner_id uuid;

update public.apartments a set owner_id = (
  select m.user_id from public.apartment_members m
  where m.apartment_id = a.id order by m.created_at limit 1)
where a.owner_id is null;

create or replace function public._set_owner() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.apartments set owner_id = new.user_id where id = new.apartment_id and owner_id is null;
  return new;
end; $$;
drop trigger if exists trg_set_owner on public.apartment_members;
create trigger trg_set_owner after insert on public.apartment_members
  for each row execute function public._set_owner();

-- 3) Borrado de un piso con todos sus datos (uso interno)
create or replace function public._borrar_piso(p_id text)
returns void language plpgsql security definer set search_path = public as $$
declare r record; pasada int;
begin
  for pasada in 1..5 loop
    for r in select c.table_name from information_schema.columns c
             where c.table_schema = 'public' and c.column_name = 'apartment_id' and c.table_name <> 'apartments'
               and c.table_name in (select table_name from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE')
    loop
      begin execute format('delete from public.%I where apartment_id::text = $1', r.table_name) using p_id;
      exception when foreign_key_violation then null; end;
    end loop;
  end loop;
  delete from public.apartments where id::text = p_id;
end; $$;

-- 4) Salir del piso: el admin debe elegir sucesor; si eres la última persona, el piso se elimina
drop function if exists public.leave_apartment(text);
create or replace function public.leave_apartment(p_id text, p_new_owner uuid default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_otros int;
begin
  select owner_id into v_owner from public.apartments where id::text = p_id;
  select count(*) into v_otros from public.apartment_members where apartment_id::text = p_id and user_id <> auth.uid();
  if v_otros = 0 then
    delete from public.apartment_members where apartment_id::text = p_id and user_id = auth.uid();
    perform public._borrar_piso(p_id);
    return;
  end if;
  if v_owner = auth.uid() then
    if p_new_owner is null or p_new_owner = auth.uid() or not exists (
         select 1 from public.apartment_members where apartment_id::text = p_id and user_id = p_new_owner) then
      raise exception 'Elige a otra persona del piso como nuevo admin antes de salir';
    end if;
    update public.apartments set owner_id = p_new_owner where id::text = p_id;
  end if;
  delete from public.apartment_members where apartment_id::text = p_id and user_id = auth.uid();
end; $$;

-- 5) Eliminar el piso para todos: solo el admin
create or replace function public.delete_apartment(p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.apartments where id::text = p_id and owner_id = auth.uid()) then
    raise exception 'Solo el admin del piso puede eliminarlo';
  end if;
  perform public._borrar_piso(p_id);
end; $$;

-- 6) Eliminar mi cuenta: pasa el admin a una persona al azar o elimina los pisos donde estás solo
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare r record;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  for r in select apartment_id::text as aid from public.apartment_members where user_id = auth.uid() loop
    if not exists (select 1 from public.apartment_members where apartment_id::text = r.aid and user_id <> auth.uid()) then
      perform public._borrar_piso(r.aid);
    else
      update public.apartments set owner_id = (
        select user_id from public.apartment_members
        where apartment_id::text = r.aid and user_id <> auth.uid() order by random() limit 1)
      where id::text = r.aid and owner_id = auth.uid();
    end if;
  end loop;
  for r in select table_name from information_schema.columns
           where table_schema = 'public' and column_name = 'user_id'
             and table_name in (select table_name from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE')
  loop
    execute format('delete from public.%I where user_id = $1', r.table_name) using auth.uid();
  end loop;
  for r in select table_name, column_name from information_schema.columns
           where table_schema = 'public' and column_name in ('paid_by', 'created_by')
  loop
    begin execute format('update public.%I set %I = null where %I = $1', r.table_name, r.column_name, r.column_name) using auth.uid();
    exception when others then null; end;
  end loop;
  delete from public.profiles where id = auth.uid();
  delete from auth.users where id = auth.uid();
end; $$;

-- Permisos: solo usuarios con sesión pueden llamar a las funciones públicas
revoke all on function public._borrar_piso(text) from public, anon, authenticated;
revoke all on function public.leave_apartment(text, uuid) from public, anon;
revoke all on function public.delete_apartment(text) from public, anon;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.leave_apartment(text, uuid) to authenticated;
grant execute on function public.delete_apartment(text) to authenticated;
grant execute on function public.delete_my_account() to authenticated;
