-- Phủ nội dung mở rộng cho toàn bộ 254 từ N5 cốt lõi của seed_content_n5.sql.
--
-- 22 từ đã biên soạn kỹ ở seed_vocab_extra_content_n5_core.sql được giữ
-- nguyên. 232 từ còn lại lấy nghĩa và ví dụ song ngữ đã được biên soạn trong
-- vocabulary_meanings làm "Cách dùng", kèm từ liên quan cùng chủ đề, phần so
-- sánh nghĩa cơ bản và lưu ý học từ. Không áp dụng cho 1.530 mục chỉ được gán
-- nhãn N5 trong DB vì danh sách đó có cả mục vượt phạm vi N5 cốt lõi.
--
-- Chạy SAU migrations/20260811000000_vocabulary_extra_content.sql và
-- seed_vocab_extra_content_n5_core.sql.
-- Idempotent: chỉ lấp các từ chưa có common_usage_pattern.

with core as (
  select
    v.id,
    v.word,
    v.part_of_speech,
    v.category,
    m.meaning_vi,
    m.example_jp,
    m.example_vi,
    related.word as related_word,
    related_meaning.meaning_vi as related_meaning_vi
  from vocabulary as v
  inner join vocabulary_meanings as m
    on m.vocabulary_id = v.id and m.order_index = 0
  left join lateral (
    select sibling.id, sibling.word
    from vocabulary as sibling
    where sibling.id <> v.id
      and sibling.id::text like '22222222-0000-0000-0000-%'
      and sibling.category = v.category
    order by sibling.word
    limit 1
  ) as related on true
  left join vocabulary_meanings as related_meaning
    on related_meaning.vocabulary_id = related.id
    and related_meaning.order_index = 0
  where v.id::text like '22222222-0000-0000-0000-%'
)
update vocabulary as v
set
  common_usage_pattern = core.example_jp,
  common_usage_desc = format(
    'Ví dụ N5 dùng %s với nghĩa “%s”; hãy ghi nhớ cả câu để dùng đúng ngữ cảnh.',
    core.word,
    core.meaning_vi
  ),
  common_usage_examples_jp = array[core.example_jp],
  common_usage_examples_vi = array[core.example_vi],
  nuance_points = array[
    format('Thuộc chủ đề %s; nghĩa được xác định theo ngữ cảnh của câu.', core.category),
    format('Là %s N5 cơ bản; ưu tiên ghi nhớ cùng mẫu câu ở trên.', core.part_of_speech)
  ],
  similar_words = case
    when core.related_word is null then array[]::text[]
    else array[core.related_word]
  end,
  similar_words_meaning_vi = case
    when core.related_meaning_vi is null then array[]::text[]
    else array[core.related_meaning_vi]
  end,
  comparison_words = case
    when core.related_word is null then array[]::text[]
    else array[core.related_word]
  end,
  comparison_main_descs = case
    when core.related_word is null then array[]::text[]
    else array[format('%s: %s.', core.word, core.meaning_vi)]
  end,
  comparison_other_descs = case
    when core.related_word is null then array[]::text[]
    else array[format('%s: %s.', core.related_word, core.related_meaning_vi)]
  end,
  common_mistake_note = format(
    'Không dịch từng từ rời khỏi câu. Hãy dùng %s theo mẫu và ngữ cảnh ở trên.',
    core.word
  ),
  common_mistake_suggestions = array[core.example_jp]
from core
where v.id = core.id
  and v.common_usage_pattern is null;
