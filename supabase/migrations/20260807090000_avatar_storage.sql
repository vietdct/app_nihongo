-- Avatar upload — Storage bucket công khai đọc, chỉ chủ sở hữu được ghi/xoá.
-- Đường dẫn file quy ước: {user_id}/avatar.jpg — 1 avatar/user, ghi đè khi đổi ảnh.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Avatar công khai đọc"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "User tự upload avatar của mình"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "User tự cập nhật avatar của mình"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "User tự xoá avatar của mình"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
