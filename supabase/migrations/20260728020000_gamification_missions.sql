-- Gamification: "Today's Mission" thật thay cho tick tay tạm thời trên Home
-- (trước đây CHƯA nối dữ liệu thật, xem comment cũ ở home_screen.dart) —
-- cho cả 4 mục: Từ vựng/Kanji/Quiz/Kaiwa. Thuần đọc/ghi Postgres, không gọi
-- AI nào — không tốn token.

-- (1) `updated_at` trên 2 bảng progress trước đây chỉ được set 1 lần lúc
-- INSERT (default now()), không bao giờ đổi khi UPDATE (app không tự truyền
-- cột này) — không dùng được để biết "hôm nay đã học". Thêm trigger để cột
-- này phản ánh đúng nghĩa "lần chạm gần nhất".
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_user_vocab_progress_updated_at
  before update on user_vocab_progress
  for each row execute function set_updated_at();

create trigger trg_user_kanji_progress_updated_at
  before update on user_kanji_progress
  for each row execute function set_updated_at();

-- (2) profiles: Quiz không có bảng log buổi làm bài nào khác nên cần 1 mốc
-- thời gian riêng để biết "đã hoàn thành 1 bài hôm nay" + JSON đánh dấu
-- ngày đã thưởng XP cho từng mission (vocab/kanji/quiz/kaiwa) — tránh cộng
-- XP nhiều lần trong cùng 1 ngày khi Home tải lại.
alter table profiles
  add column last_quiz_completed_at timestamptz,
  add column mission_xp_dates jsonb not null default '{}';
