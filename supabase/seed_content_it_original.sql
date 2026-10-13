-- Khoá "Tiếng Nhật IT" — 15 bài học NGUYÊN BẢN cho dự án phần mềm.
--
-- Nội dung được tự biên soạn từ tình huống công việc phổ biến (khởi động,
-- ước lượng, yêu cầu, thiết kế, kiểm thử, phát hành...), không sao chép câu
-- chữ, bài tập hoặc audio của bất kỳ giáo trình nào. Mỗi bài có 8 từ vựng,
-- 1 mẫu câu thực hành và 1 hội thoại nghe gắn trực tiếp với bài đó.
--
-- Phụ thuộc: migration 20260819090000_link_listening_dialogues_to_lessons.sql
-- Chạy sau migration: supabase db query --linked -f supabase/seed_content_it_original.sql

insert into jlpt_levels (code, title, order_index)
values ('IT', 'Tiếng Nhật IT', 6)
on conflict (code) do update set
  title = excluded.title,
  order_index = excluded.order_index;

insert into lessons (id, level_id, title, description, order_index)
values
  ('98000000-0000-0000-0000-000000000001'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 1 — Khởi động dự án', 'Giới thiệu mục tiêu, khách hàng và phạm vi công việc.', 1),
  ('98000000-0000-0000-0000-000000000002'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 2 — Lập dự toán', 'Trao đổi về khối lượng, chi phí và đề xuất.', 2),
  ('98000000-0000-0000-0000-000000000003'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 3 — Chuẩn bị môi trường', 'Thiết lập tài khoản, quyền truy cập và môi trường phát triển.', 3),
  ('98000000-0000-0000-0000-000000000004'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 4 — Họp và biên bản', 'Ghi nhận nội dung thảo luận, quyết định và việc cần làm.', 4),
  ('98000000-0000-0000-0000-000000000005'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 5 — Làm rõ yêu cầu', 'Phỏng vấn người dùng và thống nhất ưu tiên chức năng.', 5),
  ('98000000-0000-0000-0000-000000000006'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 6 — Thiết kế tổng thể', 'Đọc bản thiết kế màn hình, xử lý và liên kết hệ thống.', 6),
  ('98000000-0000-0000-0000-000000000007'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 7 — Xử lý thay đổi', 'Đánh giá ảnh hưởng và xin phê duyệt thay đổi yêu cầu.', 7),
  ('98000000-0000-0000-0000-000000000008'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 8 — Thiết kế chi tiết', 'Mô tả cấu trúc chương trình, điều kiện và ngoại lệ.', 8),
  ('98000000-0000-0000-0000-000000000009'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 9 — Báo cáo tiến độ', 'Báo cáo việc hoàn thành, rủi ro và kế hoạch tuần tới.', 9),
  ('98000000-0000-0000-0000-000000000010'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 10 — Bảo mật thông tin', 'Bảo vệ dữ liệu, quản lý quyền hạn và xử lý sự cố.', 10),
  ('98000000-0000-0000-0000-000000000011'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 11 — Quy tắc lập trình', 'Thống nhất cách viết mã và quy trình review.', 11),
  ('98000000-0000-0000-0000-000000000012'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 12 — Kiểm thử phần mềm', 'Viết test case, ghi nhận lỗi và kiểm tra lại.', 12),
  ('98000000-0000-0000-0000-000000000013'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 13 — Báo cáo chất lượng', 'Đo lường, phân tích nguyên nhân và cải tiến chất lượng.', 13),
  ('98000000-0000-0000-0000-000000000014'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 14 — Phát hành hệ thống', 'Chuẩn bị phiên bản, triển khai và thông báo bảo trì.', 14),
  ('98000000-0000-0000-0000-000000000015'::uuid, (select id from jlpt_levels where code = 'IT'), 'Bài 15 — Bàn giao và hỗ trợ', 'Lấy phản hồi, bàn giao vận hành và hỗ trợ khách hàng.', 15)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  order_index = excluded.order_index;

insert into vocabulary (id, word, reading, part_of_speech, category, level_id)
values
  ('99000000-0000-0000-0000-000000000001'::uuid, 'プロジェクト', 'プロジェクト', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000002'::uuid, '開発', 'かいはつ', 'danh từ / する', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000003'::uuid, '顧客', 'こきゃく', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000004'::uuid, '目的', 'もくてき', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000005'::uuid, '範囲', 'はんい', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000006'::uuid, '納期', 'のうき', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000007'::uuid, '予算', 'よさん', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000008'::uuid, '担当者', 'たんとうしゃ', 'danh từ', 'Khởi động dự án', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000009'::uuid, '見積もり', 'みつもり', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000010'::uuid, '工数', 'こうすう', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000011'::uuid, '単価', 'たんか', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000012'::uuid, '仕様', 'しよう', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000013'::uuid, '前提条件', 'ぜんていじょうけん', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000014'::uuid, '提案書', 'ていあんしょ', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000015'::uuid, '費用', 'ひよう', 'danh từ', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000016'::uuid, '承認', 'しょうにん', 'danh từ / する', 'Lập dự toán', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000017'::uuid, '開発環境', 'かいはつかんきょう', 'danh từ', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000018'::uuid, 'サーバー', 'サーバー', 'danh từ', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000019'::uuid, 'データベース', 'データベース', 'danh từ', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000020'::uuid, 'リポジトリ', 'リポジトリ', 'danh từ', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000021'::uuid, 'アカウント', 'アカウント', 'danh từ', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000022'::uuid, '権限', 'けんげん', 'danh từ', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000023'::uuid, '接続', 'せつぞく', 'danh từ / する', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000024'::uuid, '設定', 'せってい', 'danh từ / する', 'Môi trường phát triển', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000025'::uuid, '議事録', 'ぎじろく', 'danh từ', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000026'::uuid, '会議', 'かいぎ', 'danh từ', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000027'::uuid, '議題', 'ぎだい', 'danh từ', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000028'::uuid, '決定事項', 'けっていじこう', 'danh từ', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000029'::uuid, '宿題', 'しゅくだい', 'danh từ', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000030'::uuid, '参加者', 'さんかしゃ', 'danh từ', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000031'::uuid, '共有', 'きょうゆう', 'danh từ / する', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000032'::uuid, '確認', 'かくにん', 'danh từ / する', 'Họp và biên bản', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000033'::uuid, '要件定義', 'ようけんていぎ', 'danh từ', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000034'::uuid, '機能', 'きのう', 'danh từ', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000035'::uuid, '画面', 'がめん', 'danh từ', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000036'::uuid, '利用者', 'りようしゃ', 'danh từ', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000037'::uuid, '優先順位', 'ゆうせんじゅんい', 'danh từ', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000038'::uuid, 'ヒアリング', 'ヒアリング', 'danh từ / する', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000039'::uuid, '合意', 'ごうい', 'danh từ / する', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000040'::uuid, '業務', 'ぎょうむ', 'danh từ', 'Làm rõ yêu cầu', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000041'::uuid, '基本設計', 'きほんせっけい', 'danh từ', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000042'::uuid, '画面遷移', 'がめんせんい', 'danh từ', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000043'::uuid, '入力項目', 'にゅうりょくこうもく', 'danh từ', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000044'::uuid, '出力', 'しゅつりょく', 'danh từ', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000045'::uuid, '処理', 'しょり', 'danh từ / する', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000046'::uuid, 'インターフェース', 'インターフェース', 'danh từ', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000047'::uuid, 'レビュー', 'レビュー', 'danh từ / する', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000048'::uuid, '修正', 'しゅうせい', 'danh từ / する', 'Thiết kế tổng thể', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000049'::uuid, '変更要求', 'へんこうようきゅう', 'danh từ', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000050'::uuid, '影響', 'えいきょう', 'danh từ', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000051'::uuid, '追加', 'ついか', 'danh từ / する', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000052'::uuid, '削除', 'さくじょ', 'danh từ / する', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000053'::uuid, '調整', 'ちょうせい', 'danh từ / する', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000054'::uuid, '期限', 'きげん', 'danh từ', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000055'::uuid, '差分', 'さぶん', 'danh từ', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000056'::uuid, '依頼', 'いらい', 'danh từ / する', 'Xử lý thay đổi', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000057'::uuid, '詳細設計', 'しょうさいせっけい', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000058'::uuid, 'クラス', 'クラス', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000059'::uuid, 'モジュール', 'モジュール', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000060'::uuid, '例外', 'れいがい', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000061'::uuid, '条件', 'じょうけん', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000062'::uuid, '仕様書', 'しようしょ', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000063'::uuid, '実装', 'じっそう', 'danh từ / する', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000064'::uuid, '入力値', 'にゅうりょくち', 'danh từ', 'Thiết kế chi tiết', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000065'::uuid, '週報', 'しゅうほう', 'danh từ', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000066'::uuid, '進捗', 'しんちょく', 'danh từ', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000067'::uuid, '完了', 'かんりょう', 'danh từ / する', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000068'::uuid, '課題', 'かだい', 'danh từ', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000069'::uuid, '対応', 'たいおう', 'danh từ / する', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000070'::uuid, '遅れ', 'おくれ', 'danh từ', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000071'::uuid, '予定', 'よてい', 'danh từ', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000072'::uuid, '報告', 'ほうこく', 'danh từ / する', 'Báo cáo tiến độ', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000073'::uuid, '情報セキュリティ', 'じょうほうセキュリティ', 'danh từ', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000074'::uuid, '個人情報', 'こじんじょうほう', 'danh từ', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000075'::uuid, '暗号化', 'あんごうか', 'danh từ / する', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000076'::uuid, '脆弱性', 'ぜいじゃくせい', 'danh từ', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000077'::uuid, '対策', 'たいさく', 'danh từ', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000078'::uuid, '監査', 'かんさ', 'danh từ / する', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000079'::uuid, '事故', 'じこ', 'danh từ', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000080'::uuid, 'アクセス制御', 'アクセスせいぎょ', 'danh từ', 'Bảo mật thông tin', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000081'::uuid, 'コーディング規約', 'コーディングきやく', 'danh từ', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000082'::uuid, '命名規則', 'めいめいきそく', 'danh từ', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000083'::uuid, 'インデント', 'インデント', 'danh từ', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000084'::uuid, 'コメント', 'コメント', 'danh từ', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000085'::uuid, 'ブランチ', 'ブランチ', 'danh từ', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000086'::uuid, 'マージ', 'マージ', 'danh từ / する', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000087'::uuid, '競合', 'きょうごう', 'danh từ', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000088'::uuid, 'コードレビュー', 'コードレビュー', 'danh từ / する', 'Quy tắc lập trình', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000089'::uuid, 'テストケース', 'テストケース', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000090'::uuid, '期待結果', 'きたいけっか', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000091'::uuid, '実際の結果', 'じっさいのけっか', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000092'::uuid, '不具合', 'ふぐあい', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000093'::uuid, '再現', 'さいげん', 'danh từ / する', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000094'::uuid, '回帰テスト', 'かいきテスト', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000095'::uuid, 'テスト環境', 'テストかんきょう', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000096'::uuid, '確認項目', 'かくにんこうもく', 'danh từ', 'Kiểm thử phần mềm', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000097'::uuid, '品質', 'ひんしつ', 'danh từ', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000098'::uuid, '品質保証', 'ひんしつほしょう', 'danh từ', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000099'::uuid, '指標', 'しひょう', 'danh từ', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000100'::uuid, '原因', 'げんいん', 'danh từ', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000101'::uuid, '改善', 'かいぜん', 'danh từ / する', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000102'::uuid, '成果物', 'せいかぶつ', 'danh từ', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000103'::uuid, '検証', 'けんしょう', 'danh từ / する', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000104'::uuid, '傾向', 'けいこう', 'danh từ', 'Báo cáo chất lượng', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000105'::uuid, 'リリース', 'リリース', 'danh từ / する', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000106'::uuid, 'バージョン', 'バージョン', 'danh từ', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000107'::uuid, '展開', 'てんかい', 'danh từ / する', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000108'::uuid, '保守', 'ほしゅ', 'danh từ / する', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000109'::uuid, 'バックアップ', 'バックアップ', 'danh từ / する', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000110'::uuid, '更新', 'こうしん', 'danh từ / する', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000111'::uuid, '停止時間', 'ていしじかん', 'danh từ', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000112'::uuid, '通知', 'つうち', 'danh từ / する', 'Phát hành hệ thống', (select id from jlpt_levels where code = 'IT')),

  ('99000000-0000-0000-0000-000000000113'::uuid, '納品', 'のうひん', 'danh từ / する', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000114'::uuid, '運用', 'うんよう', 'danh từ / する', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000115'::uuid, 'サポート', 'サポート', 'danh từ / する', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000116'::uuid, '満足度', 'まんぞくど', 'danh từ', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000117'::uuid, 'フィードバック', 'フィードバック', 'danh từ', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000118'::uuid, '契約', 'けいやく', 'danh từ / する', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000119'::uuid, '引き継ぎ', 'ひきつぎ', 'danh từ / する', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT')),
  ('99000000-0000-0000-0000-000000000120'::uuid, '問い合わせ', 'といあわせ', 'danh từ', 'Bàn giao và hỗ trợ', (select id from jlpt_levels where code = 'IT'))
on conflict (id) do update set
  word = excluded.word,
  reading = excluded.reading,
  part_of_speech = excluded.part_of_speech,
  category = excluded.category,
  level_id = excluded.level_id;

insert into vocabulary_meanings (vocabulary_id, order_index, meaning_vi, example_jp, example_vi)
values
  ('99000000-0000-0000-0000-000000000001'::uuid, 0, 'dự án', 'このプロジェクトは来月始まります。', 'Dự án này bắt đầu vào tháng sau.'),
  ('99000000-0000-0000-0000-000000000002'::uuid, 0, 'phát triển; phát triển phần mềm', '開発チームは五人です。', 'Nhóm phát triển có năm người.'),
  ('99000000-0000-0000-0000-000000000003'::uuid, 0, 'khách hàng', '顧客の意見を聞きます。', 'Chúng tôi lắng nghe ý kiến của khách hàng.'),
  ('99000000-0000-0000-0000-000000000004'::uuid, 0, 'mục tiêu, mục đích', 'プロジェクトの目的を説明します。', 'Tôi sẽ giải thích mục tiêu của dự án.'),
  ('99000000-0000-0000-0000-000000000005'::uuid, 0, 'phạm vi', '作業の範囲を確認してください。', 'Hãy xác nhận phạm vi công việc.'),
  ('99000000-0000-0000-0000-000000000006'::uuid, 0, 'hạn giao hàng', '納期は九月三十日です。', 'Hạn giao hàng là ngày 30 tháng 9.'),
  ('99000000-0000-0000-0000-000000000007'::uuid, 0, 'ngân sách', '予算内で計画を立てます。', 'Chúng tôi lập kế hoạch trong phạm vi ngân sách.'),
  ('99000000-0000-0000-0000-000000000008'::uuid, 0, 'người phụ trách', '担当者にメールを送ります。', 'Tôi gửi email cho người phụ trách.'),

  ('99000000-0000-0000-0000-000000000009'::uuid, 0, 'báo giá, ước tính', '見積もりを明日お送りします。', 'Ngày mai chúng tôi sẽ gửi báo giá.'),
  ('99000000-0000-0000-0000-000000000010'::uuid, 0, 'khối lượng công việc (công-ngày/công-giờ)', 'この機能の工数は三人日です。', 'Khối lượng cho chức năng này là ba công-ngày.'),
  ('99000000-0000-0000-0000-000000000011'::uuid, 0, 'đơn giá', '単価を見積書に記載します。', 'Chúng tôi ghi đơn giá vào báo giá.'),
  ('99000000-0000-0000-0000-000000000012'::uuid, 0, 'đặc tả', '仕様がまだ確定していません。', 'Đặc tả vẫn chưa được chốt.'),
  ('99000000-0000-0000-0000-000000000013'::uuid, 0, 'điều kiện tiền đề', '前提条件を提案書に書きます。', 'Tôi ghi các điều kiện tiền đề trong đề xuất.'),
  ('99000000-0000-0000-0000-000000000014'::uuid, 0, 'tài liệu đề xuất', '提案書を確認していただけますか。', 'Anh/chị có thể kiểm tra tài liệu đề xuất không?'),
  ('99000000-0000-0000-0000-000000000015'::uuid, 0, 'chi phí', '追加の費用がかかります。', 'Sẽ phát sinh thêm chi phí.'),
  ('99000000-0000-0000-0000-000000000016'::uuid, 0, 'phê duyệt', '部長の承認を待っています。', 'Chúng tôi đang chờ trưởng bộ phận phê duyệt.'),

  ('99000000-0000-0000-0000-000000000017'::uuid, 0, 'môi trường phát triển', '開発環境を今日中に用意します。', 'Chúng tôi sẽ chuẩn bị môi trường phát triển trong hôm nay.'),
  ('99000000-0000-0000-0000-000000000018'::uuid, 0, 'máy chủ', 'サーバーの状態を確認します。', 'Tôi kiểm tra trạng thái máy chủ.'),
  ('99000000-0000-0000-0000-000000000019'::uuid, 0, 'cơ sở dữ liệu', 'データベースに接続できません。', 'Không thể kết nối với cơ sở dữ liệu.'),
  ('99000000-0000-0000-0000-000000000020'::uuid, 0, 'kho mã nguồn', 'リポジトリを共有しました。', 'Tôi đã chia sẻ kho mã nguồn.'),
  ('99000000-0000-0000-0000-000000000021'::uuid, 0, 'tài khoản', '新しいアカウントを作成します。', 'Tôi tạo một tài khoản mới.'),
  ('99000000-0000-0000-0000-000000000022'::uuid, 0, 'quyền hạn', 'このフォルダへの権限が必要です。', 'Cần có quyền truy cập thư mục này.'),
  ('99000000-0000-0000-0000-000000000023'::uuid, 0, 'kết nối; kết nối vào', 'VPNに接続してください。', 'Hãy kết nối vào VPN.'),
  ('99000000-0000-0000-0000-000000000024'::uuid, 0, 'cài đặt; cấu hình', '設定を保存してから再起動します。', 'Tôi lưu cài đặt rồi khởi động lại.'),

  ('99000000-0000-0000-0000-000000000025'::uuid, 0, 'biên bản cuộc họp', '議事録を会議のあとで共有します。', 'Tôi sẽ chia sẻ biên bản sau cuộc họp.'),
  ('99000000-0000-0000-0000-000000000026'::uuid, 0, 'cuộc họp', '会議は十時からです。', 'Cuộc họp bắt đầu từ 10 giờ.'),
  ('99000000-0000-0000-0000-000000000027'::uuid, 0, 'chủ đề họp', '今日の議題は進捗です。', 'Chủ đề hôm nay là tiến độ.'),
  ('99000000-0000-0000-0000-000000000028'::uuid, 0, 'hạng mục đã quyết định', '決定事項を最後に読み上げます。', 'Cuối cùng tôi sẽ đọc lại các hạng mục đã quyết định.'),
  ('99000000-0000-0000-0000-000000000029'::uuid, 0, 'việc cần làm', '私の宿題は画面を修正することです。', 'Việc của tôi là sửa màn hình.'),
  ('99000000-0000-0000-0000-000000000030'::uuid, 0, 'người tham gia', '参加者は全部で六人です。', 'Tổng cộng có sáu người tham gia.'),
  ('99000000-0000-0000-0000-000000000031'::uuid, 0, 'chia sẻ', '資料をチームに共有します。', 'Tôi chia sẻ tài liệu với cả nhóm.'),
  ('99000000-0000-0000-0000-000000000032'::uuid, 0, 'xác nhận; kiểm tra', '内容を確認して返信してください。', 'Hãy xác nhận nội dung và phản hồi.'),

  ('99000000-0000-0000-0000-000000000033'::uuid, 0, 'xác định yêu cầu', '要件定義は来週から始まります。', 'Giai đoạn xác định yêu cầu bắt đầu từ tuần sau.'),
  ('99000000-0000-0000-0000-000000000034'::uuid, 0, 'chức năng', '検索機能を追加したいです。', 'Chúng tôi muốn thêm chức năng tìm kiếm.'),
  ('99000000-0000-0000-0000-000000000035'::uuid, 0, 'màn hình', 'ログイン画面を見せてください。', 'Hãy cho tôi xem màn hình đăng nhập.'),
  ('99000000-0000-0000-0000-000000000036'::uuid, 0, 'người sử dụng', '利用者の数を教えてください。', 'Hãy cho tôi biết số người sử dụng.'),
  ('99000000-0000-0000-0000-000000000037'::uuid, 0, 'thứ tự ưu tiên', '優先順位の高い機能から作ります。', 'Chúng tôi làm từ các chức năng ưu tiên cao.'),
  ('99000000-0000-0000-0000-000000000038'::uuid, 0, 'phỏng vấn, lấy yêu cầu', '利用者にヒアリングをします。', 'Chúng tôi phỏng vấn người sử dụng.'),
  ('99000000-0000-0000-0000-000000000039'::uuid, 0, 'đồng thuận', 'この内容で合意しました。', 'Chúng ta đã thống nhất với nội dung này.'),
  ('99000000-0000-0000-0000-000000000040'::uuid, 0, 'nghiệp vụ', '現在の業務の流れを教えてください。', 'Hãy cho tôi biết quy trình nghiệp vụ hiện tại.'),

  ('99000000-0000-0000-0000-000000000041'::uuid, 0, 'thiết kế cơ bản, thiết kế tổng thể', '基本設計をレビューします。', 'Chúng ta sẽ review thiết kế cơ bản.'),
  ('99000000-0000-0000-0000-000000000042'::uuid, 0, 'chuyển màn hình', '画面遷移を図で説明します。', 'Tôi giải thích chuyển màn hình bằng sơ đồ.'),
  ('99000000-0000-0000-0000-000000000043'::uuid, 0, 'trường nhập liệu', '必須の入力項目を決めます。', 'Chúng tôi xác định các trường nhập bắt buộc.'),
  ('99000000-0000-0000-0000-000000000044'::uuid, 0, 'đầu ra; xuất dữ liệu', 'CSVで出力できます。', 'Có thể xuất dữ liệu dạng CSV.'),
  ('99000000-0000-0000-0000-000000000045'::uuid, 0, 'xử lý', '登録後の処理を確認します。', 'Chúng tôi xác nhận xử lý sau khi đăng ký.'),
  ('99000000-0000-0000-0000-000000000046'::uuid, 0, 'giao diện, liên kết hệ thống', '外部システムとのインターフェースがあります。', 'Có giao diện liên kết với hệ thống bên ngoài.'),
  ('99000000-0000-0000-0000-000000000047'::uuid, 0, 'review, rà soát', '明日、設計レビューをします。', 'Ngày mai chúng tôi review thiết kế.'),
  ('99000000-0000-0000-0000-000000000048'::uuid, 0, 'sửa đổi', '指摘された部分を修正します。', 'Tôi sửa phần đã được chỉ ra.'),

  ('99000000-0000-0000-0000-000000000049'::uuid, 0, 'yêu cầu thay đổi', '変更要求を受け取りました。', 'Chúng tôi đã nhận yêu cầu thay đổi.'),
  ('99000000-0000-0000-0000-000000000050'::uuid, 0, 'ảnh hưởng', '納期への影響を調べます。', 'Chúng tôi xem xét ảnh hưởng đến hạn giao hàng.'),
  ('99000000-0000-0000-0000-000000000051'::uuid, 0, 'thêm vào', '項目を一つ追加します。', 'Tôi thêm một hạng mục.'),
  ('99000000-0000-0000-0000-000000000052'::uuid, 0, 'xóa bỏ', '使わない機能を削除します。', 'Chúng tôi xóa chức năng không dùng.'),
  ('99000000-0000-0000-0000-000000000053'::uuid, 0, 'điều chỉnh', '日程を調整しましょう。', 'Hãy điều chỉnh lịch trình.'),
  ('99000000-0000-0000-0000-000000000054'::uuid, 0, 'thời hạn', '回答の期限は金曜日です。', 'Hạn phản hồi là thứ Sáu.'),
  ('99000000-0000-0000-0000-000000000055'::uuid, 0, 'phần chênh lệch; khác biệt', '変更前後の差分を確認します。', 'Tôi kiểm tra khác biệt trước và sau thay đổi.'),
  ('99000000-0000-0000-0000-000000000056'::uuid, 0, 'yêu cầu; đề nghị', 'お客様から修正の依頼がありました。', 'Có yêu cầu sửa đổi từ khách hàng.'),

  ('99000000-0000-0000-0000-000000000057'::uuid, 0, 'thiết kế chi tiết', '詳細設計を作成しています。', 'Tôi đang tạo thiết kế chi tiết.'),
  ('99000000-0000-0000-0000-000000000058'::uuid, 0, 'lớp (trong lập trình)', 'このクラスは注文を管理します。', 'Lớp này quản lý đơn hàng.'),
  ('99000000-0000-0000-0000-000000000059'::uuid, 0, 'mô-đun', 'モジュールごとに担当者がいます。', 'Mỗi mô-đun có một người phụ trách.'),
  ('99000000-0000-0000-0000-000000000060'::uuid, 0, 'ngoại lệ', '例外が起きた場合の処理を書きます。', 'Tôi viết xử lý khi xảy ra ngoại lệ.'),
  ('99000000-0000-0000-0000-000000000061'::uuid, 0, 'điều kiện', '条件によって表示を変えます。', 'Tôi thay đổi hiển thị tùy theo điều kiện.'),
  ('99000000-0000-0000-0000-000000000062'::uuid, 0, 'tài liệu đặc tả', '仕様書の最新版を使ってください。', 'Hãy dùng phiên bản mới nhất của tài liệu đặc tả.'),
  ('99000000-0000-0000-0000-000000000063'::uuid, 0, 'triển khai, hiện thực hóa', '来週から実装を始めます。', 'Chúng tôi bắt đầu triển khai từ tuần sau.'),
  ('99000000-0000-0000-0000-000000000064'::uuid, 0, 'giá trị nhập vào', '入力値をチェックします。', 'Tôi kiểm tra giá trị nhập vào.'),

  ('99000000-0000-0000-0000-000000000065'::uuid, 0, 'báo cáo tuần', '週報を毎週金曜日に出します。', 'Tôi nộp báo cáo tuần vào mỗi thứ Sáu.'),
  ('99000000-0000-0000-0000-000000000066'::uuid, 0, 'tiến độ', '進捗は予定どおりです。', 'Tiến độ đúng như kế hoạch.'),
  ('99000000-0000-0000-0000-000000000067'::uuid, 0, 'hoàn thành', 'テストが完了しました。', 'Kiểm thử đã hoàn thành.'),
  ('99000000-0000-0000-0000-000000000068'::uuid, 0, 'vấn đề, hạng mục cần giải quyết', '課題を一覧にまとめます。', 'Tôi tổng hợp các vấn đề vào danh sách.'),
  ('99000000-0000-0000-0000-000000000069'::uuid, 0, 'ứng phó; xử lý', 'すぐに対応します。', 'Chúng tôi sẽ xử lý ngay.'),
  ('99000000-0000-0000-0000-000000000070'::uuid, 0, 'sự chậm trễ', '二日の遅れが出ています。', 'Đang có chậm trễ hai ngày.'),
  ('99000000-0000-0000-0000-000000000071'::uuid, 0, 'dự kiến; kế hoạch', '来週の予定を共有します。', 'Tôi chia sẻ kế hoạch tuần sau.'),
  ('99000000-0000-0000-0000-000000000072'::uuid, 0, 'báo cáo', '部長に結果を報告します。', 'Tôi báo cáo kết quả với trưởng bộ phận.'),

  ('99000000-0000-0000-0000-000000000073'::uuid, 0, 'an ninh thông tin', '情報セキュリティを優先します。', 'Chúng tôi ưu tiên an ninh thông tin.'),
  ('99000000-0000-0000-0000-000000000074'::uuid, 0, 'thông tin cá nhân', '個人情報を外部に出してはいけません。', 'Không được đưa thông tin cá nhân ra bên ngoài.'),
  ('99000000-0000-0000-0000-000000000075'::uuid, 0, 'mã hóa', '重要なデータを暗号化します。', 'Chúng tôi mã hóa dữ liệu quan trọng.'),
  ('99000000-0000-0000-0000-000000000076'::uuid, 0, 'lỗ hổng bảo mật', '脆弱性がないか確認します。', 'Tôi kiểm tra xem có lỗ hổng bảo mật không.'),
  ('99000000-0000-0000-0000-000000000077'::uuid, 0, 'biện pháp đối phó', '対策を今週中に決めます。', 'Chúng tôi sẽ quyết định biện pháp đối phó trong tuần này.'),
  ('99000000-0000-0000-0000-000000000078'::uuid, 0, 'kiểm toán; đánh giá', '年に一度、監査を行います。', 'Mỗi năm một lần chúng tôi tiến hành kiểm toán.'),
  ('99000000-0000-0000-0000-000000000079'::uuid, 0, 'sự cố', '事故が起きたらすぐ連絡してください。', 'Nếu xảy ra sự cố, hãy liên hệ ngay.'),
  ('99000000-0000-0000-0000-000000000080'::uuid, 0, 'kiểm soát truy cập', 'アクセス制御を見直します。', 'Chúng tôi rà soát lại kiểm soát truy cập.'),

  ('99000000-0000-0000-0000-000000000081'::uuid, 0, 'quy ước lập trình', 'コーディング規約を守ってください。', 'Hãy tuân thủ quy ước lập trình.'),
  ('99000000-0000-0000-0000-000000000082'::uuid, 0, 'quy tắc đặt tên', '命名規則を統一します。', 'Chúng tôi thống nhất quy tắc đặt tên.'),
  ('99000000-0000-0000-0000-000000000083'::uuid, 0, 'thụt lề', 'インデントをそろえてください。', 'Hãy căn đều thụt lề.'),
  ('99000000-0000-0000-0000-000000000084'::uuid, 0, 'chú thích mã', '難しい処理にはコメントを付けます。', 'Tôi thêm chú thích cho xử lý khó.'),
  ('99000000-0000-0000-0000-000000000085'::uuid, 0, 'nhánh mã nguồn', '新しいブランチを作りました。', 'Tôi đã tạo nhánh mã nguồn mới.'),
  ('99000000-0000-0000-0000-000000000086'::uuid, 0, 'gộp mã, merge', 'レビュー後にマージします。', 'Chúng tôi merge sau khi review.'),
  ('99000000-0000-0000-0000-000000000087'::uuid, 0, 'xung đột', 'マージの競合を解決します。', 'Tôi giải quyết xung đột khi merge.'),
  ('99000000-0000-0000-0000-000000000088'::uuid, 0, 'review mã nguồn', 'コードレビューをお願いします。', 'Nhờ anh/chị review mã nguồn.'),

  ('99000000-0000-0000-0000-000000000089'::uuid, 0, 'ca kiểm thử', 'テストケースを十件作成しました。', 'Tôi đã tạo mười ca kiểm thử.'),
  ('99000000-0000-0000-0000-000000000090'::uuid, 0, 'kết quả mong đợi', '期待結果を先に書きます。', 'Tôi ghi kết quả mong đợi trước.'),
  ('99000000-0000-0000-0000-000000000091'::uuid, 0, 'kết quả thực tế', '実際の結果を記録してください。', 'Hãy ghi lại kết quả thực tế.'),
  ('99000000-0000-0000-0000-000000000092'::uuid, 0, 'lỗi, sự cố phần mềm', '不具合を一件見つけました。', 'Tôi đã tìm thấy một lỗi.'),
  ('99000000-0000-0000-0000-000000000093'::uuid, 0, 'tái hiện', 'この不具合は再現できますか。', 'Có thể tái hiện lỗi này không?'),
  ('99000000-0000-0000-0000-000000000094'::uuid, 0, 'kiểm thử hồi quy', '修正後に回帰テストをします。', 'Chúng tôi kiểm thử hồi quy sau khi sửa.'),
  ('99000000-0000-0000-0000-000000000095'::uuid, 0, 'môi trường kiểm thử', 'テスト環境を更新しました。', 'Tôi đã cập nhật môi trường kiểm thử.'),
  ('99000000-0000-0000-0000-000000000096'::uuid, 0, 'hạng mục xác nhận', '確認項目に漏れがないか見ます。', 'Tôi kiểm tra xem có sót hạng mục xác nhận không.'),

  ('99000000-0000-0000-0000-000000000097'::uuid, 0, 'chất lượng', '品質を最後まで確認します。', 'Chúng tôi kiểm tra chất lượng đến cuối.'),
  ('99000000-0000-0000-0000-000000000098'::uuid, 0, 'đảm bảo chất lượng', '品質保証チームに相談します。', 'Tôi trao đổi với nhóm đảm bảo chất lượng.'),
  ('99000000-0000-0000-0000-000000000099'::uuid, 0, 'chỉ số', '品質の指標を毎週確認します。', 'Mỗi tuần chúng tôi kiểm tra chỉ số chất lượng.'),
  ('99000000-0000-0000-0000-000000000100'::uuid, 0, 'nguyên nhân', '原因を分析して報告します。', 'Tôi phân tích nguyên nhân và báo cáo.'),
  ('99000000-0000-0000-0000-000000000101'::uuid, 0, 'cải tiến', '次の作業で改善します。', 'Chúng tôi sẽ cải tiến ở công việc tiếp theo.'),
  ('99000000-0000-0000-0000-000000000102'::uuid, 0, 'sản phẩm bàn giao', '成果物の一覧を作ります。', 'Tôi lập danh sách sản phẩm bàn giao.'),
  ('99000000-0000-0000-0000-000000000103'::uuid, 0, 'xác minh', '修正内容を検証しました。', 'Tôi đã xác minh nội dung sửa đổi.'),
  ('99000000-0000-0000-0000-000000000104'::uuid, 0, 'xu hướng', '不具合の傾向を見ます。', 'Chúng tôi xem xu hướng lỗi.'),

  ('99000000-0000-0000-0000-000000000105'::uuid, 0, 'phát hành', '金曜日にリリースします。', 'Chúng tôi phát hành vào thứ Sáu.'),
  ('99000000-0000-0000-0000-000000000106'::uuid, 0, 'phiên bản', '新しいバージョンを準備しました。', 'Tôi đã chuẩn bị phiên bản mới.'),
  ('99000000-0000-0000-0000-000000000107'::uuid, 0, 'triển khai', '本番環境へ展開します。', 'Chúng tôi triển khai lên môi trường production.'),
  ('99000000-0000-0000-0000-000000000108'::uuid, 0, 'bảo trì', '夜間に保守を行います。', 'Chúng tôi bảo trì vào ban đêm.'),
  ('99000000-0000-0000-0000-000000000109'::uuid, 0, 'sao lưu', '作業前にバックアップを取ります。', 'Chúng tôi sao lưu trước khi làm việc.'),
  ('99000000-0000-0000-0000-000000000110'::uuid, 0, 'cập nhật', 'アプリを更新してください。', 'Hãy cập nhật ứng dụng.'),
  ('99000000-0000-0000-0000-000000000111'::uuid, 0, 'thời gian dừng hệ thống', '停止時間は三十分です。', 'Thời gian dừng hệ thống là 30 phút.'),
  ('99000000-0000-0000-0000-000000000112'::uuid, 0, 'thông báo', '利用者に通知を送ります。', 'Tôi gửi thông báo cho người dùng.'),

  ('99000000-0000-0000-0000-000000000113'::uuid, 0, 'bàn giao sản phẩm', '来週、お客様に納品します。', 'Tuần sau chúng tôi bàn giao cho khách hàng.'),
  ('99000000-0000-0000-0000-000000000114'::uuid, 0, 'vận hành', '運用マニュアルを作成します。', 'Tôi tạo hướng dẫn vận hành.'),
  ('99000000-0000-0000-0000-000000000115'::uuid, 0, 'hỗ trợ', 'サポートの窓口を案内します。', 'Tôi hướng dẫn kênh hỗ trợ.'),
  ('99000000-0000-0000-0000-000000000116'::uuid, 0, 'mức độ hài lòng', '満足度のアンケートを送ります。', 'Chúng tôi gửi khảo sát mức độ hài lòng.'),
  ('99000000-0000-0000-0000-000000000117'::uuid, 0, 'phản hồi', 'フィードバックを改善に生かします。', 'Chúng tôi dùng phản hồi để cải tiến.'),
  ('99000000-0000-0000-0000-000000000118'::uuid, 0, 'hợp đồng', '契約の内容を確認します。', 'Tôi xác nhận nội dung hợp đồng.'),
  ('99000000-0000-0000-0000-000000000119'::uuid, 0, 'bàn giao công việc', '担当者に引き継ぎをします。', 'Tôi bàn giao công việc cho người phụ trách.'),
  ('99000000-0000-0000-0000-000000000120'::uuid, 0, 'yêu cầu hỗ trợ, câu hỏi liên hệ', '問い合わせには一日以内に答えます。', 'Chúng tôi trả lời yêu cầu hỗ trợ trong vòng một ngày.')
on conflict (vocabulary_id, order_index) do update set
  meaning_vi = excluded.meaning_vi,
  example_jp = excluded.example_jp,
  example_vi = excluded.example_vi;

insert into grammar_points (
  id, title, explanation, example_jp, example_vi, memory_tip, common_mistake,
  practice_tokens, practice_blank_index, level_id
)
values
  ('97000000-0000-0000-0000-000000000001'::uuid, '〜について', 'Dùng sau danh từ để nói về chủ đề đang trao đổi: “về…”.', 'プロジェクトについて説明します。', 'Tôi sẽ giải thích về dự án.', 'N + について + nói/viết/hỏi/giải thích.', 'Không dùng について ngay sau động từ.', ARRAY['プロジェクト','について','説明します。'], 1, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000002'::uuid, '〜をもとに', 'Diễn tả dùng một thông tin hay tài liệu làm cơ sở để tạo ra việc khác.', '仕様をもとに見積もりを作ります。', 'Chúng tôi lập báo giá dựa trên đặc tả.', 'N + をもとに: dựa trên N.', 'Không dùng để chỉ một hành động diễn ra sau hành động khác.', ARRAY['仕様','をもとに','見積もり','を','作ります。'], 1, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000003'::uuid, '〜ように設定する', 'Dùng để cấu hình hệ thống sao cho đạt được một trạng thái hoặc kết quả mong muốn.', '誰でも使えるように設定します。', 'Tôi cấu hình để ai cũng có thể sử dụng.', 'Thể khả năng hoặc phủ định + ように設定する.', 'Đừng dùng ように với một ý chí trực tiếp như “tôi sẽ làm”.', ARRAY['誰でも','使える','ように','設定します。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000004'::uuid, '〜ことになりました', 'Thông báo một quyết định đã được đưa ra bởi tập thể hoặc hoàn cảnh.', '次の会議は月曜日にすることになりました。', 'Đã quyết định cuộc họp tiếp theo sẽ diễn ra vào thứ Hai.', 'V thể từ điển / ない + ことになりました.', 'Không dùng khi chỉ nói dự định cá nhân; hãy dùng ことにしました.', ARRAY['次の会議は','月曜日に','する','ことになりました。'], 3, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000005'::uuid, '〜ていただけますか', 'Cách nhờ vả lịch sự, phù hợp khi trao đổi với khách hàng hoặc người cấp trên.', '画面のイメージを送っていただけますか。', 'Anh/chị có thể gửi hình mẫu màn hình được không?', 'V thể て + いただけますか.', 'Không thêm ください sau いただけますか.', ARRAY['画面のイメージを','送って','いただけますか。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000006'::uuid, '〜場合は', 'Nêu điều kiện hoặc trường hợp giả định: “trong trường hợp…”.', 'エラーが出た場合は、担当者に連絡してください。', 'Trong trường hợp xảy ra lỗi, hãy liên hệ người phụ trách.', 'V thể thường / N の + 場合は.', 'Không nhầm với とき: 場合 nhấn mạnh trường hợp có điều kiện.', ARRAY['エラーが','出た','場合は、','担当者に','連絡してください。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000007'::uuid, '〜に伴って', 'Diễn tả một thay đổi kéo theo thay đổi khác; thường dùng trong văn phong công việc.', '仕様の変更に伴って、工数も増えます。', 'Cùng với thay đổi đặc tả, khối lượng công việc cũng tăng.', 'N / V từ điển + に伴って.', 'Không dùng cho thay đổi nhỏ, tức thời hay cảm xúc cá nhân.', ARRAY['仕様の変更に','伴って、','工数も','増えます。'], 1, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000008'::uuid, '〜ことができる', 'Dùng để nói khả năng hoặc chức năng có thể thực hiện.', 'この画面で注文を確認することができます。', 'Có thể xác nhận đơn hàng trên màn hình này.', 'V thể từ điển + ことができる.', 'Không ghép ことができる với động từ đã ở thể khả năng.', ARRAY['この画面で','注文を','確認する','ことができます。'], 3, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000009'::uuid, '〜ています', 'Dùng để báo tình trạng đang diễn ra hoặc trạng thái hiện tại trong báo cáo tiến độ.', '今、テストを行っています。', 'Hiện tại, chúng tôi đang thực hiện kiểm thử.', 'V thể て + います.', 'Không dùng thể quá khứ ました khi công việc chưa hoàn thành.', ARRAY['今、','テストを','行っています。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000010'::uuid, '〜なければならない', 'Diễn tả nghĩa vụ bắt buộc: “phải…”.', '個人情報を安全に管理しなければなりません。', 'Phải quản lý thông tin cá nhân an toàn.', 'V thể ない bỏ い + なければなりません.', 'Không dùng với việc chỉ là đề xuất; khi đó dùng ほうがいいです.', ARRAY['個人情報を','安全に','管理しなければ','なりません。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000011'::uuid, '〜ようにしてください', 'Đưa ra chỉ dẫn lịch sự nhằm yêu cầu người nghe duy trì hay thực hiện một việc.', '命名規則を守るようにしてください。', 'Hãy đảm bảo tuân thủ quy tắc đặt tên.', 'V thể từ điển / ない + ようにしてください.', 'Không dùng để yêu cầu một hành động một lần với giọng mạnh; dùng てください khi cần.', ARRAY['命名規則を','守る','ように','してください。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000012'::uuid, '〜かどうか', 'Dùng sau mệnh đề để nói “có hay không”, thường khi kiểm tra hoặc xác nhận.', '不具合が再現するかどうかを確認します。', 'Tôi xác nhận xem lỗi có tái hiện hay không.', 'Mệnh đề thể thường + かどうか.', 'Không dùng cùng từ nghi vấn như いつ/どこ; dùng か thay cho かどうか.', ARRAY['不具合が','再現する','かどうかを','確認します。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000013'::uuid, '〜ために', 'Nêu mục đích khi làm một việc: “để…”.', '品質を上げるために、レビューを増やします。', 'Để nâng chất lượng, chúng tôi tăng số lần review.', 'V thể từ điển / N の + ために.', 'Không dùng ために sau mệnh đề quá khứ.', ARRAY['品質を','上げる','ために、','レビューを','増やします。'], 2, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000014'::uuid, '〜前に', 'Diễn tả một hành động được thực hiện trước hành động khác.', 'リリースの前にバックアップを取ります。', 'Chúng tôi sao lưu trước khi phát hành.', 'V thể từ điển / N の + 前に.', 'Sau 前に, hành động sau phải xảy ra trước hành động trước 前に.', ARRAY['リリースの','前に','バックアップを','取ります。'], 1, (select id from jlpt_levels where code = 'IT')),
  ('97000000-0000-0000-0000-000000000015'::uuid, '〜ていく', 'Dùng để nói một việc sẽ tiếp tục từ hiện tại về sau.', 'お客様の意見をサービス改善に生かしていきます。', 'Chúng tôi sẽ tiếp tục dùng ý kiến khách hàng để cải tiến dịch vụ.', 'V thể て + いく.', 'Không dùng khi chỉ nói một hành động đã hoàn thành.', ARRAY['お客様の意見を','サービス改善に','生かして','いきます。'], 3, (select id from jlpt_levels where code = 'IT'))
on conflict (id) do update set
  title = excluded.title,
  explanation = excluded.explanation,
  example_jp = excluded.example_jp,
  example_vi = excluded.example_vi,
  memory_tip = excluded.memory_tip,
  common_mistake = excluded.common_mistake,
  practice_tokens = excluded.practice_tokens,
  practice_blank_index = excluded.practice_blank_index,
  level_id = excluded.level_id;

-- Mỗi bài hiển thị đúng 8 từ vựng và 1 mẫu câu trong Lesson Runner.
insert into lesson_items (lesson_id, item_type, item_id, order_index)
values
  ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000001'::uuid, 1), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000002'::uuid, 2), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000003'::uuid, 3), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000004'::uuid, 4), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000005'::uuid, 5), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000006'::uuid, 6), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000007'::uuid, 7), ('98000000-0000-0000-0000-000000000001'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000008'::uuid, 8), ('98000000-0000-0000-0000-000000000001'::uuid, 'grammar', '97000000-0000-0000-0000-000000000001'::uuid, 9),
  ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000009'::uuid, 1), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000010'::uuid, 2), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000011'::uuid, 3), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000012'::uuid, 4), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000013'::uuid, 5), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000014'::uuid, 6), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000015'::uuid, 7), ('98000000-0000-0000-0000-000000000002'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000016'::uuid, 8), ('98000000-0000-0000-0000-000000000002'::uuid, 'grammar', '97000000-0000-0000-0000-000000000002'::uuid, 9),
  ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000017'::uuid, 1), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000018'::uuid, 2), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000019'::uuid, 3), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000020'::uuid, 4), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000021'::uuid, 5), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000022'::uuid, 6), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000023'::uuid, 7), ('98000000-0000-0000-0000-000000000003'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000024'::uuid, 8), ('98000000-0000-0000-0000-000000000003'::uuid, 'grammar', '97000000-0000-0000-0000-000000000003'::uuid, 9),
  ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000025'::uuid, 1), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000026'::uuid, 2), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000027'::uuid, 3), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000028'::uuid, 4), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000029'::uuid, 5), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000030'::uuid, 6), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000031'::uuid, 7), ('98000000-0000-0000-0000-000000000004'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000032'::uuid, 8), ('98000000-0000-0000-0000-000000000004'::uuid, 'grammar', '97000000-0000-0000-0000-000000000004'::uuid, 9),
  ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000033'::uuid, 1), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000034'::uuid, 2), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000035'::uuid, 3), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000036'::uuid, 4), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000037'::uuid, 5), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000038'::uuid, 6), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000039'::uuid, 7), ('98000000-0000-0000-0000-000000000005'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000040'::uuid, 8), ('98000000-0000-0000-0000-000000000005'::uuid, 'grammar', '97000000-0000-0000-0000-000000000005'::uuid, 9),
  ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000041'::uuid, 1), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000042'::uuid, 2), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000043'::uuid, 3), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000044'::uuid, 4), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000045'::uuid, 5), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000046'::uuid, 6), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000047'::uuid, 7), ('98000000-0000-0000-0000-000000000006'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000048'::uuid, 8), ('98000000-0000-0000-0000-000000000006'::uuid, 'grammar', '97000000-0000-0000-0000-000000000006'::uuid, 9),
  ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000049'::uuid, 1), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000050'::uuid, 2), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000051'::uuid, 3), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000052'::uuid, 4), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000053'::uuid, 5), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000054'::uuid, 6), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000055'::uuid, 7), ('98000000-0000-0000-0000-000000000007'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000056'::uuid, 8), ('98000000-0000-0000-0000-000000000007'::uuid, 'grammar', '97000000-0000-0000-0000-000000000007'::uuid, 9),
  ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000057'::uuid, 1), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000058'::uuid, 2), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000059'::uuid, 3), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000060'::uuid, 4), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000061'::uuid, 5), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000062'::uuid, 6), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000063'::uuid, 7), ('98000000-0000-0000-0000-000000000008'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000064'::uuid, 8), ('98000000-0000-0000-0000-000000000008'::uuid, 'grammar', '97000000-0000-0000-0000-000000000008'::uuid, 9),
  ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000065'::uuid, 1), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000066'::uuid, 2), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000067'::uuid, 3), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000068'::uuid, 4), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000069'::uuid, 5), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000070'::uuid, 6), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000071'::uuid, 7), ('98000000-0000-0000-0000-000000000009'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000072'::uuid, 8), ('98000000-0000-0000-0000-000000000009'::uuid, 'grammar', '97000000-0000-0000-0000-000000000009'::uuid, 9),
  ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000073'::uuid, 1), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000074'::uuid, 2), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000075'::uuid, 3), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000076'::uuid, 4), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000077'::uuid, 5), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000078'::uuid, 6), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000079'::uuid, 7), ('98000000-0000-0000-0000-000000000010'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000080'::uuid, 8), ('98000000-0000-0000-0000-000000000010'::uuid, 'grammar', '97000000-0000-0000-0000-000000000010'::uuid, 9),
  ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000081'::uuid, 1), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000082'::uuid, 2), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000083'::uuid, 3), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000084'::uuid, 4), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000085'::uuid, 5), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000086'::uuid, 6), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000087'::uuid, 7), ('98000000-0000-0000-0000-000000000011'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000088'::uuid, 8), ('98000000-0000-0000-0000-000000000011'::uuid, 'grammar', '97000000-0000-0000-0000-000000000011'::uuid, 9),
  ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000089'::uuid, 1), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000090'::uuid, 2), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000091'::uuid, 3), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000092'::uuid, 4), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000093'::uuid, 5), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000094'::uuid, 6), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000095'::uuid, 7), ('98000000-0000-0000-0000-000000000012'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000096'::uuid, 8), ('98000000-0000-0000-0000-000000000012'::uuid, 'grammar', '97000000-0000-0000-0000-000000000012'::uuid, 9),
  ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000097'::uuid, 1), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000098'::uuid, 2), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000099'::uuid, 3), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000100'::uuid, 4), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000101'::uuid, 5), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000102'::uuid, 6), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000103'::uuid, 7), ('98000000-0000-0000-0000-000000000013'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000104'::uuid, 8), ('98000000-0000-0000-0000-000000000013'::uuid, 'grammar', '97000000-0000-0000-0000-000000000013'::uuid, 9),
  ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000105'::uuid, 1), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000106'::uuid, 2), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000107'::uuid, 3), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000108'::uuid, 4), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000109'::uuid, 5), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000110'::uuid, 6), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000111'::uuid, 7), ('98000000-0000-0000-0000-000000000014'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000112'::uuid, 8), ('98000000-0000-0000-0000-000000000014'::uuid, 'grammar', '97000000-0000-0000-0000-000000000014'::uuid, 9),
  ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000113'::uuid, 1), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000114'::uuid, 2), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000115'::uuid, 3), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000116'::uuid, 4), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000117'::uuid, 5), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000118'::uuid, 6), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000119'::uuid, 7), ('98000000-0000-0000-0000-000000000015'::uuid, 'vocabulary', '99000000-0000-0000-0000-000000000120'::uuid, 8), ('98000000-0000-0000-0000-000000000015'::uuid, 'grammar', '97000000-0000-0000-0000-000000000015'::uuid, 9)
on conflict (lesson_id, item_type, item_id) do update set
  order_index = excluded.order_index;

insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
values
  ('95000000-0000-0000-0000-000000000001'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000001'::uuid, '[{"speaker":"A","jp":"今回のプロジェクトの目的は何ですか。"},{"speaker":"B","jp":"注文の確認を早くすることです。"},{"speaker":"A","jp":"納期はいつですか。"},{"speaker":"B","jp":"九月末を予定しています。"}]'::jsonb, 'プロジェクトの目的は何ですか。', '["注文確認を早くすること","予算を増やすこと","会議を減らすこと","サーバーを交換すること"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000002'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000002'::uuid, '[{"speaker":"A","jp":"見積もりはできましたか。"},{"speaker":"B","jp":"はい。開発の工数は二十人日です。"},{"speaker":"A","jp":"お客様への提出はいつですか。"},{"speaker":"B","jp":"明日の午前中です。"}]'::jsonb, '見積もりはいつ提出しますか。', '["明日の午前中","今日の午後","来週の月曜日","九月末"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000003'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000003'::uuid, '[{"speaker":"A","jp":"開発環境に接続できましたか。"},{"speaker":"B","jp":"まだです。アカウントの権限がありません。"},{"speaker":"A","jp":"分かりました。管理者に依頼します。"}]'::jsonb, 'Bさんはなぜ接続できませんか。', '["アカウントの権限がないから","サーバーが止まったから","パスワードを忘れたから","リポジトリがないから"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000004'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000004'::uuid, '[{"speaker":"A","jp":"今日の決定事項を確認します。"},{"speaker":"B","jp":"画面の案は来週までに作ることになりました。"},{"speaker":"A","jp":"議事録は誰が共有しますか。"},{"speaker":"B","jp":"私が会議のあとで送ります。"}]'::jsonb, '議事録を共有するのは誰ですか。', '["Bさん","Aさん","お客様","管理者"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000005'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000005'::uuid, '[{"speaker":"A","jp":"利用者は検索結果をどう見たいですか。"},{"speaker":"B","jp":"新しい順に見たいそうです。"},{"speaker":"A","jp":"分かりました。優先順位は高いですか。"},{"speaker":"B","jp":"はい、最初のリリースに必要です。"}]'::jsonb, '検索結果はどのように表示しますか。', '["新しい順","古い順","名前順","価格順"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000006'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000006'::uuid, '[{"speaker":"A","jp":"この入力項目は必須ですか。"},{"speaker":"B","jp":"はい。空の場合はエラーメッセージを表示します。"},{"speaker":"A","jp":"画面遷移図にも書いておきます。"}]'::jsonb, '入力項目が空の場合、どうしますか。', '["エラーメッセージを表示する","自動的に登録する","画面を閉じる","メールを送る"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000007'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000007'::uuid, '[{"speaker":"A","jp":"お客様から変更要求が来ました。"},{"speaker":"B","jp":"どんな影響がありますか。"},{"speaker":"A","jp":"工数が三人日増える見込みです。"},{"speaker":"B","jp":"では、承認をお願いしましょう。"}]'::jsonb, '変更によって何が増えますか。', '["工数","利用者","サーバー","会議室"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000008'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000008'::uuid, '[{"speaker":"A","jp":"例外が起きたときの処理はありますか。"},{"speaker":"B","jp":"はい。エラー画面を表示して、ログを残します。"},{"speaker":"A","jp":"仕様書にも追加してください。"}]'::jsonb, '例外が起きたとき、何を残しますか。', '["ログ","見積書","議事録","アンケート"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000009'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000009'::uuid, '[{"speaker":"A","jp":"今週の進捗はどうですか。"},{"speaker":"B","jp":"予定した画面は完了しました。"},{"speaker":"A","jp":"課題はありますか。"},{"speaker":"B","jp":"テスト環境の準備が少し遅れています。"}]'::jsonb, '少し遅れているのは何ですか。', '["テスト環境の準備","画面の作成","週報の提出","お客様の承認"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000010'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000010'::uuid, '[{"speaker":"A","jp":"個人情報はどこに保存しますか。"},{"speaker":"B","jp":"暗号化してデータベースに保存します。"},{"speaker":"A","jp":"アクセスできる人も制限してください。"}]'::jsonb, '個人情報をどのように保存しますか。', '["暗号化して保存する","紙に印刷して保存する","メールで送る","誰でも見られる場所に置く"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000011'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000011'::uuid, '[{"speaker":"A","jp":"このプルリクエストを見ましたか。"},{"speaker":"B","jp":"はい。インデントがそろっていません。"},{"speaker":"A","jp":"コメントで伝えてください。"},{"speaker":"B","jp":"分かりました。修正後にもう一度レビューします。"}]'::jsonb, 'Bさんは何を指摘しましたか。', '["インデント","納期","予算","サーバー"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000012'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000012'::uuid, '[{"speaker":"A","jp":"この不具合は再現しますか。"},{"speaker":"B","jp":"はい。同じ入力値なら再現します。"},{"speaker":"A","jp":"期待結果と実際の結果をテストケースに書いてください。"}]'::jsonb, 'Bさんはテストケースに何を書きますか。', '["期待結果と実際の結果","見積もりと予算","議題と参加者","契約と納品日"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000013'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000013'::uuid, '[{"speaker":"A","jp":"今月の品質指標はどうですか。"},{"speaker":"B","jp":"不具合の件数は先月より減りました。"},{"speaker":"A","jp":"よかったです。原因分析も報告書に入れましょう。"}]'::jsonb, '不具合の件数はどうなりましたか。', '["先月より減った","先月より増えた","変わらなかった","まだ分からない"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000014'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000014'::uuid, '[{"speaker":"A","jp":"リリース前に何をしますか。"},{"speaker":"B","jp":"まずバックアップを取ります。"},{"speaker":"A","jp":"停止時間の通知は送りましたか。"},{"speaker":"B","jp":"はい、利用者に送りました。"}]'::jsonb, 'リリース前に最初に何をしますか。', '["バックアップを取る","新しい契約を結ぶ","議事録を作る","画面を設計する"]'::jsonb, 0),
  ('95000000-0000-0000-0000-000000000015'::uuid, (select id from jlpt_levels where code = 'IT'), '98000000-0000-0000-0000-000000000015'::uuid, '[{"speaker":"A","jp":"納品後のサポートはどうしますか。"},{"speaker":"B","jp":"問い合わせ窓口を案内します。"},{"speaker":"A","jp":"お客様のフィードバックも集めましょう。"},{"speaker":"B","jp":"次の改善に生かします。"}]'::jsonb, '集めたフィードバックを何に使いますか。', '["次の改善","サーバーの停止","会議の中止","予算の削除"]'::jsonb, 0)
on conflict (id) do update set
  level_id = excluded.level_id,
  lesson_id = excluded.lesson_id,
  turns = excluded.turns,
  question_ja = excluded.question_ja,
  options = excluded.options,
  correct_index = excluded.correct_index;
