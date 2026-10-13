-- Bucket công khai chứa audio hội thoại tạo sẵn (cloud TTS) cho phần Nghe hiểu.
-- App đọc qua URL công khai theo tên file (xem tool/generate_listening_audio.py).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listening-audio', 'listening-audio', true, 5242880, array['audio/mpeg'])
on conflict (id) do nothing;
