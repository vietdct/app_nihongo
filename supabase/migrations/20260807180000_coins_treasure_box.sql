-- Coins + Rương phần thưởng (Thành tích — "Sắp ra mắt" trước đây, xem
-- docs/REVIEW_DESIGN.md §11/§16 câu hỏi #4). Quyết định phạm vi 2026-08-07:
-- Coin không phải bộ đếm riêng cộng dồn thủ công ở từng nơi cộng XP (dễ mất
-- số do làm tròn xuống mỗi lần cộng lẻ) — Coin "ăn theo XP" được tính trực
-- tiếp từ `xp` (floor(xp/10)) mỗi lần đọc, cộng thêm `bonus_coins` (thưởng
-- từ rương, không tính vào XP). Vì vậy KHÔNG cần sửa bất kỳ nơi cộng XP nào.
--
-- Rương mở theo mốc `profiles.streak_count` (3/7/14/30/60/100 ngày — cùng
-- cột streak đã dùng cho huy hiệu, không tạo hệ streak riêng). Cấp rương và
-- mở rương đều qua SECURITY DEFINER RPC (cùng pattern consume_ai_quota) vì
-- đây là lần đầu client có thể "yêu cầu" một khoản thưởng cụ thể — không thể
-- để client tự ghi milestone/reward_coins trực tiếp (có thể giả mốc streak
-- cao để ăn thưởng lớn).

alter table profiles add column bonus_coins integer not null default 0 check (bonus_coins >= 0);

create table treasure_boxes (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  milestone     integer not null,
  reward_coins  integer,
  opened_at     timestamptz,
  created_at    timestamptz not null default now(),
  unique (user_id, milestone)
);

create index ix_treasure_boxes_user on treasure_boxes (user_id, opened_at);

alter table treasure_boxes enable row level security;

-- Chỉ cho đọc trực tiếp (hiển thị rương đang chờ mở); ghi/cập nhật chỉ qua
-- 2 RPC bên dưới (không có policy insert/update nào cho authenticated).
create policy "treasure_boxes_select_own" on treasure_boxes
  for select using (auth.uid() = user_id);

create or replace function claim_treasure_milestones()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_streak integer;
  v_milestones integer[] := array[3, 7, 14, 30, 60, 100];
  v_milestone integer;
  v_claimed integer[] := array[]::integer[];
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select streak_count into v_streak from profiles where id = v_user_id;
  v_streak := coalesce(v_streak, 0);

  foreach v_milestone in array v_milestones loop
    if v_streak >= v_milestone then
      insert into treasure_boxes (user_id, milestone)
      values (v_user_id, v_milestone)
      on conflict (user_id, milestone) do nothing;
      if found then
        v_claimed := array_append(v_claimed, v_milestone);
      end if;
    end if;
  end loop;

  return jsonb_build_object('claimed_milestones', to_jsonb(v_claimed));
end;
$$;

revoke all on function claim_treasure_milestones() from public, anon;
grant execute on function claim_treasure_milestones() to authenticated;

create or replace function open_treasure_box(p_box_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_milestone integer;
  v_opened_at timestamptz;
  v_reward integer;
  v_min integer;
  v_max integer;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select milestone, opened_at into v_milestone, v_opened_at
  from treasure_boxes
  where id = p_box_id and user_id = v_user_id
  for update;

  if v_milestone is null then
    raise exception 'treasure box not found' using errcode = '22023';
  end if;
  if v_opened_at is not null then
    raise exception 'treasure box already opened' using errcode = '22023';
  end if;

  select reward.min_coins, reward.max_coins
  into v_min, v_max
  from (
    values
      (3, 20, 40),
      (7, 50, 80),
      (14, 80, 120),
      (30, 150, 250),
      (60, 300, 450),
      (100, 500, 700)
  ) as reward(milestone, min_coins, max_coins)
  where reward.milestone = v_milestone;

  v_reward := v_min + floor(random() * (v_max - v_min + 1))::integer;

  update treasure_boxes
  set reward_coins = v_reward, opened_at = clock_timestamp()
  where id = p_box_id;

  update profiles set bonus_coins = bonus_coins + v_reward where id = v_user_id;

  return jsonb_build_object('reward_coins', v_reward, 'milestone', v_milestone);
end;
$$;

revoke all on function open_treasure_box(uuid) from public, anon;
grant execute on function open_treasure_box(uuid) to authenticated;
