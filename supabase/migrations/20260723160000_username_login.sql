-- Pha 3a — Đăng nhập bằng tên đăng nhập (username), ngoài email.
-- Supabase Auth chỉ hỗ trợ đăng nhập bằng email/phone theo mặc định, nên
-- username được lưu ở public.profiles và có 1 RPC SECURITY DEFINER tra
-- ngược ra email tương ứng để client gọi signInWithPassword như bình thường.

alter table profiles add column username varchar(30);

-- Không phân biệt hoa/thường khi tra cứu và khi ràng buộc duy nhất.
create unique index ux_profiles_username on profiles (lower(username)) where username is not null;

-- Cho phép tự chọn user đọc username của chính mình (đã có policy select_own
-- ở Pha 1 bao trùm luôn cột mới này, không cần thêm policy).

-- Cập nhật trigger tạo profile: nhận thêm username từ metadata lúc signUp.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', 'Người học'),
    new.raw_user_meta_data ->> 'username'
  );
  return new;
end;
$$;

-- Tra email từ username — chạy với quyền definer để đọc được auth.users
-- (client không có quyền đọc bảng này trực tiếp). Chỉ trả về email, không
-- lộ thêm thông tin nào khác.
create or replace function get_email_by_username(p_username text)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_email text;
begin
  select u.email into v_email
  from auth.users u
  join public.profiles p on p.id = u.id
  where lower(p.username) = lower(p_username)
  limit 1;

  return v_email;
end;
$$;

revoke all on function get_email_by_username(text) from public;
grant execute on function get_email_by_username(text) to anon, authenticated;
