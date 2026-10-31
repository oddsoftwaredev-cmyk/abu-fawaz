-- شغّل الملف ده كله في Supabase → SQL Editor
-- آمن للتشغيل على داتابيز جديدة أو على داتابيز شغالة فيها بيانات (مفيش حاجة بتتمسح)

create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  unit text not null default 'none' check (unit in ('none','pack','ton','kg','ardeb')),
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
create table if not exists suppliers (
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
  supplier_id uuid references suppliers(id) on delete restrict,
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

-- ===== تحديثات على داتابيز قديمة (مش بتأثر على الجديدة) =====

-- عمود المورد في العمليات
alter table transactions
  add column if not exists supplier_id uuid references suppliers(id) on delete restrict;
create index if not exists tx_supplier_idx on transactions (supplier_id);

-- الشراء لازم له مورد (not valid = العمليات القديمة من غير مورد تفضل زي ما هي)
alter table transactions drop constraint if exists tx_purchase_supplier;
alter table transactions add constraint tx_purchase_supplier
  check (type <> 'purchase' or supplier_id is not null) not valid;

-- الأردب في وحدات القياس
alter table items drop constraint if exists items_unit_check;
alter table items add constraint items_unit_check
  check (unit in ('none','pack','ton','kg','ardeb'));

-- أرصدة المخزون (للتقارير؛ الواجهة بتحسبها بنفسها)
create or replace view stock_balances as
select wh, item_id,
  sum(case when type = 'purchase' then qty else -qty end) as balance
from transactions group by wh, item_id;

-- ⚠️ وصول عام بدون تسجيل دخول: أي حد معاه الرابط والمفتاح يقدر يقرأ ويعدّل.
-- لو هتضيف Login بعدين، غيّر السياسات دي لـ "to authenticated".
alter table items enable row level security;
alter table customers enable row level security;
alter table suppliers enable row level security;
alter table transactions enable row level security;
do $$ declare t text; begin
  foreach t in array array['items','customers','suppliers','transactions'] loop
    execute format('drop policy if exists public_all on %I', t);
    execute format('create policy public_all on %I for all to anon using (true) with check (true)', t);
  end loop;
end $$;
