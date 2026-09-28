-- ============================================================
-- 跨境电商推品平台 · Supabase 建表脚本
-- 使用方法：登录 supabase.com → 打开你的项目 → 左侧 "SQL Editor"
--          → New query → 粘贴本脚本 → Run（运行一次即可）
-- ============================================================

-- 1) 创建图片存储桶（用于存放商品图片，公开可读）
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- 2) 店铺表
create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  platform text,
  target_market text,
  store_url text,
  category text,
  rating text,
  remark text,
  created_at timestamptz default now()
);

-- 3) 商品表（通过 store_id 关联店铺，一对多）
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid references public.stores(id) on delete cascade,
  name text not null,
  sku text,
  images jsonb default '[]',
  highlights jsonb default '[]',
  specs text,
  commission_rate numeric,
  commission_note text,
  supply_price numeric,
  suggested_price numeric,
  discount text,
  target_market text,
  platform text,
  material_status text,
  stock_info text,
  sales_data text,
  authorization_note text,
  status text default 'pending',
  contact_person text,
  contact_info text,
  remark text,
  created_at timestamptz default now()
);

-- 4) 开启行级安全
alter table public.stores enable row level security;
alter table public.products enable row level security;

-- ============================================================
-- 权限策略：打品团队（匿名）只读，运营人员（登录用户）可读写
-- 匿名访问 = 未登录打开网站的人（打品团队）
-- 登录用户 = 用 Supabase 账号登录管理后台的人（你）
-- ============================================================

-- 店铺表：
--   匿名(anon)：只允许 SELECT（只读）
drop policy if exists "anon select stores" on public.stores;
create policy "anon select stores"
  on public.stores for select
  using (true);

--   登录用户(authenticated)：允许增删改查
drop policy if exists "auth all stores" on public.stores;
create policy "auth all stores"
  on public.stores for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- 商品表：
--   匿名(anon)：只允许 SELECT（只读）
drop policy if exists "anon select products" on public.products;
create policy "anon select products"
  on public.products for select
  using (true);

--   登录用户(authenticated)：允许增删改查
drop policy if exists "auth all products" on public.products;
create policy "auth all products"
  on public.products for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- ============================================================
-- 图片存储桶权限：
--   公开可读（打品团队能看商品图）
--   仅登录用户可上传/覆盖/删除（运营人员才能传图）
-- ============================================================
drop policy if exists "public read images" on storage.objects;
create policy "public read images"
  on storage.objects for select
  using (bucket_id = 'product-images');

drop policy if exists "auth upload images" on storage.objects;
create policy "auth upload images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-images');

drop policy if exists "auth delete images" on storage.objects;
create policy "auth delete images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'product-images');

-- ============================================================
-- 说明：
-- 1. 匿名 = 未登录访问网站的人（打品团队）→ 只能看，不能改
-- 2. 登录用户 = 用 Supabase Auth 账号登录管理后台的人（你）→ 可增删改
-- 3. 前端已做配合：管理后台需要登录才能进入，写操作会自动带上登录凭证
-- ============================================================
-- （注：内容由AI生成）
