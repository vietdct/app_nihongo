-- Phủ nội dung mở rộng cho toàn bộ 1.160 từ N2 của seed_content_n2_vocab.sql
-- (Mimikara N2, chia 15 từ/ngày học).
--
-- PDF N2 chỉ cung cấp từ, cách đọc và nghĩa; không có ví dụ câu hoặc từ loại.
-- Seed dùng đúng nghĩa gốc cùng ngày học, không tự tạo ví dụ tiếng Nhật hay
-- sửa các nghĩa có thể lỗi trong PDF. Từ liên quan là một từ khác cùng ngày
-- học; phần so sánh chỉ đối chiếu nghĩa gốc của hai từ. Idempotent: chỉ lấp
-- các từ chưa có common_usage_pattern.
--
-- Chạy SAU migration 20260811000000_vocabulary_extra_content.sql.

with source as (
  select
    v.id,
    v.word,
    v.reading,
    meaning.meaning_vi,
    lesson.title as lesson_title,
    related.word as related_word,
    related.meaning_vi as related_meaning_vi
  from vocabulary as v
  inner join vocabulary_meanings as meaning
    on meaning.vocabulary_id = v.id and meaning.order_index = 0
  inner join lateral (
    select lesson_item.lesson_id
    from lesson_items as lesson_item
    where lesson_item.item_type = 'vocabulary'
      and lesson_item.item_id = v.id
    order by lesson_item.order_index
    limit 1
  ) as item on true
  inner join lessons as lesson on lesson.id = item.lesson_id
  left join lateral (
    select sibling.word, sibling_meaning.meaning_vi
    from lesson_items as sibling_item
    inner join vocabulary as sibling
      on sibling.id = sibling_item.item_id
    inner join vocabulary_meanings as sibling_meaning
      on sibling_meaning.vocabulary_id = sibling.id
      and sibling_meaning.order_index = 0
    where sibling_item.lesson_id = item.lesson_id
      and sibling_item.item_type = 'vocabulary'
      and sibling.id <> v.id
    order by sibling_item.order_index
    limit 1
  ) as related on true
  where v.level_id = (select id from jlpt_levels where code = 'N2')
)
update vocabulary as v
set
  common_usage_pattern = format('%s（%s）', source.word, source.reading),
  common_usage_desc = format(
    '%s — nghĩa cơ bản: “%s”. Học cùng ngữ cảnh của %s.',
    source.word,
    source.meaning_vi,
    source.lesson_title
  ),
  common_usage_examples_jp = array[]::text[],
  common_usage_examples_vi = array[]::text[],
  nuance_points = array[
    format('Từ vựng thuộc %s.', source.lesson_title),
    format('Ghi nhớ cách đọc “%s” cùng nghĩa “%s”.', source.reading, source.meaning_vi)
  ],
  similar_words = case
    when source.related_word is null then array[]::text[]
    else array[source.related_word]
  end,
  similar_words_meaning_vi = case
    when source.related_meaning_vi is null then array[]::text[]
    else array[source.related_meaning_vi]
  end,
  comparison_words = case
    when source.related_word is null then array[]::text[]
    else array[source.related_word]
  end,
  comparison_main_descs = case
    when source.related_word is null then array[]::text[]
    else array[format('%s: %s.', source.word, source.meaning_vi)]
  end,
  comparison_other_descs = case
    when source.related_word is null then array[]::text[]
    else array[format('%s: %s.', source.related_word, source.related_meaning_vi)]
  end,
  common_mistake_note = format(
    'Không dịch tách rời khỏi ngày học. Hãy ghi nhớ %s cùng cách đọc và nghĩa gốc.',
    source.word
  ),
  common_mistake_suggestions = array[
    format('%s（%s）', source.word, source.reading),
    source.meaning_vi
  ]
from source
where v.id = source.id
  and v.common_usage_pattern is null;
