-- Task 6 (docs/JLPT_MOCK_EXAM_DESIGN.md §8, §20): soạn 1 đoạn văn đọc hiểu
-- N5 mẫu (tự viết, không copy đề thật — tránh vấn đề bản quyền) + thêm
-- section "reading" vào blueprint N5 full_exam đã seed ở migration trước
-- (không tạo blueprint mới, chỉ nối thêm phần tử vào jsonb `sections`).

insert into reading_passages (level_id, title, body_ja, questions)
select
  id,
  '山田さんの一日',
  '山田さんは会社員です。毎朝七時に起きます。朝ごはんを食べてから、電車で会社へ行きます。会社は九時から六時までです。仕事の後、よく友達とレストランで晩ごはんを食べます。土曜日と日曜日は休みですから、家でゆっくり休みます。',
  '[
    {
      "question_ja": "山田さんは何時に起きますか。",
      "options": ["六時", "七時", "八時", "九時"],
      "correct_index": 1
    },
    {
      "question_ja": "山田さんはどうやって会社へ行きますか。",
      "options": ["バス", "電車", "車", "歩いて"],
      "correct_index": 1
    },
    {
      "question_ja": "山田さんは仕事の後、よく何をしますか。",
      "options": ["家で休みます", "友達とレストランで晩ごはんを食べます", "買い物をします", "勉強します"],
      "correct_index": 1
    }
  ]'::jsonb
from jlpt_levels where code = 'N5';

update jlpt_exam_blueprints
set sections = sections || '[{"type": "reading", "question_count": 3, "time_minutes": 10}]'::jsonb
where mode = 'full_exam'
  and level_id = (select id from jlpt_levels where code = 'N5');
