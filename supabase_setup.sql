-- USE CAY THUE: Supabase setup/migration
-- Run this entire file in Supabase Dashboard > SQL Editor > New query.

-- Add fields used by the website while preserving existing orders.
alter table public.orders
  add column if not exists category text,
  add column if not exists shop_note text;

alter table public.orders alter column status set default 'Chờ duyệt';
update public.orders set status = 'Chờ duyệt' where status = 'pending';

-- Private server-side price list. Customers cannot read or modify this table.
create table if not exists public.service_catalog (
  category text not null,
  service text not null,
  price numeric(12,0) not null check (price >= 0),
  primary key (category, service)
);
alter table public.service_catalog enable row level security;
revoke all on public.service_catalog from anon, authenticated;

insert into public.service_catalog(category, service, price) values
('CÀY LEVEL','Cày level từ 1 - max',50000),
('CÀY LEVEL','Cày level từ 1 - 700',20000),
('CÀY LEVEL','Cày level từ 700 - 1500',20000),
('CÀY LEVEL','Cày level từ 1500 - max',30000),
('CÀY THÔNG THẠO','Cày thông thạo 1 - 600tt',50000),
('CÀY THÔNG THẠO','Cày thông thạo 1 - 300tt',20000),
('CÀY THÔNG THẠO','Cày thông thạo 300 - 600tt',30000),
('VÕ & TRÁI ÁC QUỶ','Võ v2',40000),
('VÕ & TRÁI ÁC QUỶ','Godhuman',50000),
('VÕ & TRÁI ÁC QUỶ','Sanguine Art',140000),
('TỘC','Tộc v1 người máy',30000),
('TỘC','Tộc v1 quỷ',20000),
('TỘC','Tộc v2',10000),
('TỘC','Tộc v3',30000),
('TỘC','Tộc 4 (1 gear)',30000),
('KIẾM','SDK (đủ 2 kiếm + đủ thông thạo, làm nhiệm vụ thôi)',20000),
('KIẾM','SDK (không đủ kiếm)',40000),
('KIẾM','Lưỡi hái',10000),
('KIẾM','Kiếm Yama',10000),
('KIẾM','Kiếm Tushita',20000),
('KIẾM','Kiếm Oroshi',10000),
('KIẾM','Kiếm Shizu',10000),
('KIẾM','Kiếm Saishi',10000),
('KIẾM','Tam kiếm',50000),
('SÚNG','Guitar linh hồn (đủ nguyên liệu, làm nhiệm vụ thôi)',20000),
('SÚNG','Guitar linh hồn (không đủ nguyên liệu)',50000),
('SÚNG','Dragon Storm',50000),
('BOSS & ĐẢO','Rip Indra',20000),
('BOSS & ĐẢO','Dough King',30000),
('BOSS & ĐẢO','Leviathan 1 tim',90000),
('BOSS & ĐẢO','Tộc rồng v1',100000),
('BOSS & ĐẢO','Tộc rồng v4 (1 gear)',30000),
('BOSS & ĐẢO','Đảo rồng 1 trứng',10000),
('BOSS & ĐẢO','Đi đảo Kit',20000),
('RAID','Raid',10000),
('RAID','F',10000),
('TIỀN','Tiền 10 triệu',20000)
on conflict (category, service) do update set price = excluded.price;

-- Public visitors must submit through the validated function, not directly insert rows.
drop policy if exists "Allow customers to submit orders" on public.orders;
revoke insert on public.orders from anon, authenticated;

create or replace function public.create_public_order(
  p_roblox_username text,
  p_tiktok_username text,
  p_category text,
  p_service text,
  p_notes text default null
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_price numeric(12,0);
  v_code text;
begin
  if length(trim(coalesce(p_roblox_username,''))) < 1 or length(trim(p_roblox_username)) > 40 then
    raise exception 'Tên Roblox không hợp lệ';
  end if;
  if length(trim(coalesce(p_tiktok_username,''))) < 1 or length(trim(p_tiktok_username)) > 60 then
    raise exception 'Tên TikTok không hợp lệ';
  end if;
  if length(coalesce(p_notes,'')) > 500 then
    raise exception 'Ghi chú quá dài';
  end if;

  select price into v_price
  from public.service_catalog
  where category = p_category and service = p_service;
  if v_price is null then
    raise exception 'Dịch vụ không tồn tại hoặc đã ngừng nhận';
  end if;

  loop
    v_code := 'USE-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (select 1 from public.orders where order_code = v_code);
  end loop;

  insert into public.orders(
    order_code, roblox_username, tiktok_username, category,
    service, price, notes, status
  ) values (
    v_code, trim(p_roblox_username), trim(p_tiktok_username), p_category,
    p_service, v_price, nullif(trim(coalesce(p_notes,'')),''), 'Chờ duyệt'
  );

  return v_code;
end;
$$;

-- A customer can see only the order matching BOTH the code and their Roblox username.
create or replace function public.track_public_order(
  p_order_code text,
  p_roblox_username text
)
returns table (
  order_code text,
  roblox_username text,
  category text,
  service text,
  price numeric,
  notes text,
  status text,
  shop_note text,
  created_at timestamptz
)
language sql
security definer
set search_path = public, pg_temp
as $$
  select o.order_code, o.roblox_username, o.category, o.service,
         o.price, o.notes, o.status, o.shop_note, o.created_at
  from public.orders o
  where upper(o.order_code) = upper(trim(p_order_code))
    and lower(o.roblox_username) = lower(trim(p_roblox_username))
  limit 1;
$$;

revoke all on function public.create_public_order(text,text,text,text,text) from public;
revoke all on function public.track_public_order(text,text) from public;
grant execute on function public.create_public_order(text,text,text,text,text) to anon, authenticated;
grant execute on function public.track_public_order(text,text) to anon, authenticated;

-- IMPORTANT: keep your existing admin SELECT/UPDATE policies scoped to your own auth.uid().
-- Do not create a public SELECT policy on public.orders.
