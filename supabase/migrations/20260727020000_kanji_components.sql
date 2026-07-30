-- Kanji Family: cột components lưu các bộ (component) ghép trực tiếp nên
-- chữ Hán này, tách 1 cấp từ dữ liệu IDS thật (CHISE IDS Database qua
-- github.com/cjkvi/cjkvi-ids, CC0) — không tự bịa cách ghép bộ. Chỉ những
-- chữ có ít nhất 1 bộ trùng với 1 kanji khác đang có trong app mới được gán
-- giá trị (xem UPDATE ở seed_content_n5.sql) — 1 kanji không có quan hệ ghép
-- bộ thật với kanji nào khác trong bộ hiện có thì giữ mảng rỗng mặc định.
alter table kanji add column components text[] not null default '{}';
