-- شغّل الملف ده كله في Supabase → SQL Editor
create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  unit text not null default 'none' check (unit in ('none','pack','ton','kg')),
  description text default '',
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  notes text default '',
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('purchase','sale')),
  tx_date date not null,
  item_id uuid not null references items(id) on delete restrict,
  customer_id uuid references customers(id) on delete restrict,
  qty numeric(14,3) not null check (qty > 0),
  price numeric(14,2) not null check (price >= 0),
  total numeric(14,2) not null,
  paid numeric(14,2) not null default 0 check (paid >= 0),
  wh text not null default 'المخزن الرئيسي',
  created_at timestamptz not null default now(),
  check (type <> 'sale' or customer_id is not null),
  check (paid <= total)
);
create index if not exists tx_date_idx on transactions (tx_date);
create index if not exists tx_item_idx on transactions (item_id);
create index if not exists tx_customer_idx on transactions (customer_id);

-- أرصدة المخزون (للتقارير؛ الواجهة بتحسبها بنفسها)
create or replace view stock_balances as
select wh, item_id,
  sum(case when type = 'purchase' then qty else -qty end) as balance
from transactions group by wh, item_id;

-- ⚠️ وصول عام بدون تسجيل دخول: أي حد معاه الرابط والمفتاح يقدر يقرأ ويعدّل.
-- لو هتضيف Login بعدين، غيّر السياسات دي لـ "to authenticated".
alter table items enable row level security;
alter table customers enable row level security;
alter table transactions enable row level security;
do $$ declare t text; begin
  foreach t in array array['items','customers','transactions'] loop
    execute format('drop policy if exists public_all on %I', t);
    execute format('create policy public_all on %I for all to anon using (true) with check (true)', t);
  end loop;
end $$;
