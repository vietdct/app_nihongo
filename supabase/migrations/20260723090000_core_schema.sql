-- Pha 1 — Schema lõi + Row Level Security
-- Tham chiếu: Tài liệu thiết kế v2.0, mục 3 (Thiết kế Database).

create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────────────────────
-- Cấp độ JLPT (N5..N1) — dữ liệu tham chiếu, công khai đọc
-- ─────────────────────────────────────────────────────────────
create table jlpt_levels (
  id          uuid primary key default gen_random_uuid(),
  code        varchar(4)  not null,      -- 'N5'..'N1'
  title       varchar(64) not null,
  order_index int         not null,
  created_at  timestamptz not null default now()
);
create unique index ux_jlpt_levels_code on jlpt_levels (code);

insert into jlpt_levels (code, title, order_index) values
  ('N5', 'Sơ cấp N5',        1),
  ('N4', 'Sơ trung cấp N4',  2),
  ('N3', 'Trung cấp N3',     3),
  ('N2', 'Trung cao cấp N2', 4),
  ('N1', 'Cao cấp N1',       5);

-- ─────────────────────────────────────────────────────────────
-- Hồ sơ người dùng — mở rộng bảng auth.users do Supabase Auth quản lý
-- ─────────────────────────────────────────────────────────────
create table profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  display_name     varchar(100) not null,
  avatar_url       text,
  current_level_id uuid references jlpt_levels(id),
  xp               integer not null default 0,
  streak_count     integer not null default 0,
  last_study_date  date,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index ix_profiles_level on profiles (current_level_id);

-- Tự tạo profile mỗi khi có user mới đăng ký
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', 'Người học')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- Row Level Security
--   Quy tắc: MỌI bảng có dữ liệu riêng tư đều phải bật RLS.
--   Đây là lỗi bảo mật số 1 của mô hình Supabase nếu quên.
-- ─────────────────────────────────────────────────────────────
alter table profiles enable row level security;

create policy "profiles_select_own"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- jlpt_levels là nội dung công khai: ai đăng nhập cũng đọc được, không ai ghi qua client
alter table jlpt_levels enable row level security;

create policy "jlpt_levels_read_all"
  on jlpt_levels for select
  using (true);
