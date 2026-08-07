-- Xoá feature "review_coach" khỏi bảng giới hạn của consume_ai_quota —
-- AI Review Coach đã bị gỡ khỏi app (UI + Edge Function) theo quyết định
-- người dùng 2026-08-07, feature key không còn được gọi từ đâu nữa.
create or replace function consume_ai_quota(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_minute_limit integer;
  v_daily_limit integer;
  v_now timestamptz := clock_timestamp();
  v_minute_start timestamptz := date_trunc('minute', v_now);
  v_day_start timestamptz := date_trunc('day', v_now at time zone 'UTC') at time zone 'UTC';
  v_minute_count integer;
  v_daily_count integer;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select limits.minute_limit, limits.daily_limit
  into v_minute_limit, v_daily_limit
  from (
    values
      ('kaiwa_chat', 4, 10),
      ('grammar_tutor', 8, 20),
      ('kanji_tutor', 8, 20),
      ('kaiwa_tutor', 8, 20),
      ('lesson_mission', 4, 10),
      ('pronunciation', 1, 10),
      ('study_report', 2, 5)
  ) as limits(feature, minute_limit, daily_limit)
  where limits.feature = p_feature;

  if v_minute_limit is null then
    raise exception 'unknown AI feature: %', p_feature using errcode = '22023';
  end if;

  -- Tuần tự hóa các request cùng user + feature để không vượt giới hạn khi
  -- người dùng gửi nhiều request đồng thời.
  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':' || p_feature, 0));

  -- Dọn dữ liệu cũ của chính user này; giữ 7 ngày để đủ quan sát vận hành
  -- nhưng không để các bucket theo phút tăng vô hạn.
  delete from ai_usage_counters
  where user_id = v_user_id
    and window_start < v_day_start - interval '7 days';

  select request_count into v_minute_count
  from ai_usage_counters
  where user_id = v_user_id
    and feature = p_feature
    and window_type = 'minute'
    and window_start = v_minute_start;

  v_minute_count := coalesce(v_minute_count, 0);
  if v_minute_count >= v_minute_limit then
    return jsonb_build_object(
      'allowed', false,
      'code', 'AI_RATE_LIMIT_EXCEEDED',
      'limit', v_minute_limit,
      'used', v_minute_count,
      'retry_after', v_minute_start + interval '1 minute'
    );
  end if;

  select request_count into v_daily_count
  from ai_usage_counters
  where user_id = v_user_id
    and feature = p_feature
    and window_type = 'day'
    and window_start = v_day_start;

  v_daily_count := coalesce(v_daily_count, 0);
  if v_daily_count >= v_daily_limit then
    return jsonb_build_object(
      'allowed', false,
      'code', 'AI_DAILY_QUOTA_EXCEEDED',
      'limit', v_daily_limit,
      'used', v_daily_count,
      'retry_after', v_day_start + interval '1 day'
    );
  end if;

  insert into ai_usage_counters (
    user_id, feature, window_type, window_start, request_count
  ) values (
    v_user_id, p_feature, 'minute', v_minute_start, 1
  )
  on conflict (user_id, feature, window_type, window_start)
  do update set
    request_count = ai_usage_counters.request_count + 1,
    updated_at = v_now
  returning request_count into v_minute_count;

  insert into ai_usage_counters (
    user_id, feature, window_type, window_start, request_count
  ) values (
    v_user_id, p_feature, 'day', v_day_start, 1
  )
  on conflict (user_id, feature, window_type, window_start)
  do update set
    request_count = ai_usage_counters.request_count + 1,
    updated_at = v_now
  returning request_count into v_daily_count;

  return jsonb_build_object(
    'allowed', true,
    'minute_limit', v_minute_limit,
    'minute_used', v_minute_count,
    'daily_limit', v_daily_limit,
    'daily_used', v_daily_count
  );
end;
$$;
