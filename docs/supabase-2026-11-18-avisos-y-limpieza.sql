-- TodoenOrden · 18/11/2026
-- Dos cambios en la base de datos, pedidos tras probar la app:
--   1) Poder EDITAR un aviso del tablón ya publicado (antes solo se podía publicar y eliminar).
--   2) Reparto de limpieza: que a nadie le toquen dos zonas mientras otra persona no tiene ninguna.
-- Ninguno borra ni modifica datos existentes.

-- ============================================================
-- 1) EDITAR AVISOS
-- El rol authenticated solo tenía INSERT (apartment_id, title, content, expires_at),
-- SELECT y DELETE: no existía ningún permiso de UPDATE, así que editar era imposible.
-- ============================================================
grant update (title, content, expires_at) on public.bulletin_notices to authenticated;

-- Cualquier compañero del piso puede editar y eliminar un aviso, igual que las normas
-- («todos los compañeros tienen los mismos permisos»): el aviso del fontanero lo publicó
-- una persona y la hora la puede cambiar cualquiera. El autor y la fecha de publicación
-- no cambian nunca: los fija el disparador de abajo.
drop policy if exists notices_update_author on public.bulletin_notices;
drop policy if exists notices_update_members on public.bulletin_notices;
create policy notices_update_members on public.bulletin_notices
  as permissive for update to authenticated
  using (is_apartment_member(apartment_id))
  with check (is_apartment_member(apartment_id));

drop policy if exists notices_delete_author on public.bulletin_notices;
drop policy if exists notices_delete_members on public.bulletin_notices;
create policy notices_delete_members on public.bulletin_notices
  as permissive for delete to authenticated
  using (is_apartment_member(apartment_id));

-- El disparador solo saltaba al publicar. Ahora también al editar: mantiene al autor,
-- la fecha de publicación y el piso, limpia los espacios y sigue exigiendo que la
-- fecha de finalización sea futura.
CREATE OR REPLACE FUNCTION public.bulletin_notices_set_meta()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    new.user_id    := coalesce(auth.uid(), new.user_id);
    new.created_at := now();
  else
    new.user_id      := old.user_id;        -- editar no cambia de autor
    new.created_at   := old.created_at;
    new.apartment_id := old.apartment_id;
  end if;
  new.title   := btrim(new.title);
  new.content := btrim(new.content);
  if new.expires_at is not null and new.expires_at <= now() then
    raise exception 'EXPIRY_IN_PAST: la fecha de finalización debe ser futura'
      using errcode = '23514';
  end if;
  return new;
end;
$function$;

drop trigger if exists bulletin_notices_before_insert on public.bulletin_notices;
drop trigger if exists bulletin_notices_set_meta_trg on public.bulletin_notices;
create trigger bulletin_notices_set_meta_trg
  before insert or update on public.bulletin_notices
  for each row execute function public.bulletin_notices_set_meta();

-- ============================================================
-- 2) REPARTO DE LIMPIEZA: UNA ZONA PARA CADA UNO
-- Antes se descartaba del reparto a quien estuviera fuera 4 días o más de la semana.
-- Con 6 zonas y 6 compañeros, si uno estaba fuera quedaban 5 personas para 6 zonas
-- y a alguien le tocaban dos mientras el que estaba fuera no tenía ninguna.
-- Ahora: a quien está fuera no le toca SOLO si con los que quedan hay al menos una
-- persona por zona. Si no, entra también, antes que doblar a nadie.
-- ============================================================
CREATE OR REPLACE FUNCTION public.ensure_week_assignments(p_apartment_id uuid, p_week_start date DEFAULT NULL::date)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_week date := public.current_week_start();
  v_prev_week date;
  v_members uuid[]; v_zones uuid[]; v_todos uuid[]; v_presentes uuid[];
  n int; z int; i int; c int; m int; cap int; steps int;
  v_count int := 0; r int; v_u uuid; v_done boolean; v_found boolean; v_existing int := 0;
  prev int[]; asg int[]; kk int[]; load int[]; cur int[]; has boolean[]; fin boolean[];
begin
  if not public.is_apartment_member(p_apartment_id) then
    raise exception 'No perteneces a este piso';
  end if;
  if p_week_start is not null and date_trunc('week', p_week_start)::date <> v_week then
    raise exception 'Solo se puede generar el reparto de la semana actual';
  end if;

  -- un solo cálculo a la vez por piso (dos compañeros abriendo a la vez)
  perform pg_advisory_xact_lock(hashtext('ensure_week:' || p_apartment_id::text));

  select array_agg(id order by created_at, id) into v_zones
    from public.cleaning_zones where apartment_id = p_apartment_id;
  z := coalesce(array_length(v_zones, 1), 0);

  select array_agg(user_id order by created_at, user_id) into v_todos
    from public.apartment_members where apartment_id = p_apartment_id;
  select array_agg(user_id order by created_at, user_id) into v_presentes
    from public.apartment_members where apartment_id = p_apartment_id
     and public.dias_ausente(p_apartment_id, user_id, v_week, v_week + 6) < 4;   -- fuera casi toda la semana
  -- a quien está fuera no le toca, pero solo si quedan personas para todas las zonas:
  -- antes que doblar a alguien, entra en el reparto quien está fuera
  if coalesce(array_length(v_presentes, 1), 0) >= z then v_members := v_presentes;
  else v_members := v_todos; end if;

  n := coalesce(array_length(v_members, 1), 0);
  if n < 2 or z = 0 then return 0; end if;   -- con un solo compañero no se puede cambiar la zona de nadie

  -- quién tuvo cada zona la última semana guardada antes de la actual
  select max(week_start) into v_prev_week from public.cleaning_assignments
    where apartment_id = p_apartment_id and week_start < v_week;
  prev := array_fill(0, array[z]);
  if v_prev_week is not null then
    for i in 1..z loop
      select user_id into v_u from public.cleaning_assignments
        where apartment_id = p_apartment_id and week_start = v_prev_week and zone_id = v_zones[i];
      prev[i] := coalesce(array_position(v_members, v_u), 0);
    end loop;
  end if;

  -- lo que ya hay repartido esta semana
  load := array_fill(0, array[n]);
  cur := array_fill(0, array[z]); has := array_fill(false, array[z]); fin := array_fill(false, array[z]);
  for i in 1..z loop
    select user_id, is_done into v_u, v_done from public.cleaning_assignments
      where apartment_id = p_apartment_id and week_start = v_week and zone_id = v_zones[i];
    v_found := found;
    if v_found then
      has[i] := true; fin[i] := v_done; v_existing := v_existing + 1;
      cur[i] := coalesce(array_position(v_members, v_u), 0);
      if cur[i] > 0 then load[cur[i]] := load[cur[i]] + 1; end if;
    end if;
  end loop;

  if v_existing = 0 then
    -- SEMANA NUEVA: reparto completo con búsqueda con vuelta atrás
    for cap in ceil(z::numeric / n)::int .. z loop
      kk := array_fill(0, array[z]); asg := array_fill(0, array[z]); load := array_fill(0, array[n]);
      i := 1; steps := 0;
      while i >= 1 and i <= z and steps < 100000 loop
        steps := steps + 1; m := 0;
        while kk[i] < n loop
          if prev[i] > 0 then c := (((prev[i] - 1 - (kk[i] + 1)) % n) + n) % n + 1;
          else c := ((i - 1 + kk[i]) % n) + 1; end if;
          kk[i] := kk[i] + 1;
          if (prev[i] = 0 or c <> prev[i]) and load[c] < cap then m := c; exit; end if;
        end loop;
        if m > 0 then
          asg[i] := m; load[m] := load[m] + 1; i := i + 1;
          if i <= z then kk[i] := 0; end if;
        else
          kk[i] := 0; i := i - 1;
          if i >= 1 then load[asg[i]] := load[asg[i]] - 1; end if;
        end if;
      end loop;
      exit when i = z + 1;
    end loop;
    if i <> z + 1 then return 0; end if;
    for i in 1..z loop
      insert into public.cleaning_assignments (apartment_id, zone_id, user_id, week_start)
      values (p_apartment_id, v_zones[i], v_members[asg[i]], v_week)
      on conflict (zone_id, week_start) do nothing;
      get diagnostics r = row_count; v_count := v_count + r;
    end loop;
  else
    -- SEMANA YA REPARTIDA: no se mueve nada. Solo se cubren zonas nuevas
    -- o turnos pendientes de alguien que ya no está en el piso.
    -- Una zona nueva va a quien menos zonas tenga (así no se dobla a nadie).
    for i in 1..z loop
      if not has[i] or (cur[i] = 0 and not fin[i]) then
        m := 0;
        for c in 1..n loop
          if (prev[i] = 0 or c <> prev[i]) and (m = 0 or load[c] < load[m]) then m := c; end if;
        end loop;
        if m > 0 then
          insert into public.cleaning_assignments (apartment_id, zone_id, user_id, week_start)
          values (p_apartment_id, v_zones[i], v_members[m], v_week)
          on conflict (zone_id, week_start) do update set user_id = excluded.user_id
            where public.cleaning_assignments.is_done = false;
          load[m] := load[m] + 1; v_count := v_count + 1;
        end if;
      end if;
    end loop;
  end if;

  return v_count;
end;
$function$;
