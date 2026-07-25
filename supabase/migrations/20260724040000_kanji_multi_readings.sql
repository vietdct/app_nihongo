-- Pha 3e — Kanji đa âm/đa nghĩa: 1 chữ Hán không chỉ có đúng 1 âm On, 1 âm
-- Kun, 1 âm Hán Việt, 1 nghĩa — tuỳ chữ mà có thể nhiều. Chuyển 4 cột từ
-- text đơn sang text[] để lưu đủ danh sách thay vì gộp chung 1 chuỗi.

alter table kanji drop column onyomi;
alter table kanji drop column kunyomi;
alter table kanji drop column han_viet;
alter table kanji drop column meaning_vi;

alter table kanji add column onyomi text[];
alter table kanji add column kunyomi text[];
alter table kanji add column han_viet text[];
alter table kanji add column meaning_vi text[];
