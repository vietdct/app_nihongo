-- Pha 3d — Flashcard Kanji: âm Hán Việt, mẹo ghi nhớ, và dữ liệu nét vẽ.
-- stroke_data lưu dạng JSON rút gọn từ KanjiVG (viewBox + danh sách path
-- "d" của từng nét, đúng thứ tự viết) — nhẹ hơn nhiều so với lưu nguyên SVG,
-- và app tự vẽ/animate lại bằng CustomPainter, không cần parser SVG đầy đủ.
--
-- Dữ liệu nét chữ dựa trên dự án KanjiVG (Ulrich Apel, CC BY-SA 3.0,
-- http://kanjivg.tagaini.net) — ghi chú attribution hiển thị trong app.

alter table kanji add column han_viet varchar(64);
alter table kanji add column mnemonic text;
alter table kanji add column stroke_data jsonb;
