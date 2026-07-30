-- auth-login-username là endpoint công khai (verify_jwt = false) nên bất kỳ
-- ai cũng gọi được không giới hạn, có thể brute-force mật khẩu theo username
-- hoặc dò username tồn tại qua nhiều lần thử. Thêm rate limit theo cả IP và
-- username (mỗi bên một cửa sổ phút/ngày riêng), tương tự pattern
-- consume_ai_quota nhưng không cần auth.uid() vì request chưa đăng nhập.

create table auth_login_attempts (
  identifier    text        not null,
  window_type   text        not null check (window_type in ('minute', 'day')),
  window_start  timestamptz not null,
  request_count integer     not null default 0 check (request_count >= 0),
  updated_at    timestamptz not null default now(),
  primary key (identifier, window_type, window_start)
);

create index ix_auth_login_attempts_cleanup on auth_login_attempts (window_start);

alter table auth_login_attempts enable row level security;

-- Không tạo policy: bảng chỉ được truy cập qua SECURITY DEFINER RPC bên dưới.
revoke all on table auth_login_attempts from anon, authenticated;

-- p_minute_limit/p_daily_limit do Edge Function (service_role, code tin cậy)
-- truyền vào cố định; không phải giá trị từ client.
create or replace function consume_login_attempt(
  p_identifier text,
  p_minute_limit integer,
  p_daily_limit integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_minute_start timestamptz := date_trunc('minute', v_now);
  v_day_start timestamptz := date_trunc('day', v_now at time zone 'UTC') at time zone 'UTC';
  v_minute_count integer;
  v_daily_count integer;
begin
  if p_identifier is null or length(p_identifier) = 0 then
    raise exception 'identifier required' using errcode = '22023';
  end if;

  -- Tuần tự hóa các request cùng identifier để không vượt giới hạn khi
  -- nhiều request chạy đồng thời.
  perform pg_advisory_xact_lock(hashtextextended(p_identifier, 0));

  -- Dọn dữ liệu cũ của chính identifier này; giữ 7 ngày để đủ quan sát vận
  -- hành nhưng không để các bucket theo phút tăng vô hạn.
  delete from auth_login_attempts
  where identifier = p_identifier
    and window_start < v_day_start - interval '7 days';

  select request_count into v_minute_count
  from auth_login_attempts
  where identifier = p_identifier
    and window_type = 'minute'
    and window_start = v_minute_start;

  v_minute_count := coalesce(v_minute_count, 0);
  if v_minute_count >= p_minute_limit then
    return jsonb_build_object(
      'allowed', false,
      'code', 'LOGIN_RATE_LIMIT_EXCEEDED',
      'limit', p_minute_limit,
      'used', v_minute_count,
      'retry_after', v_minute_start + interval '1 minute'
    );
  end if;

  select request_count into v_daily_count
  from auth_login_attempts
  where identifier = p_identifier
    and window_type = 'day'
    and window_start = v_day_start;

  v_daily_count := coalesce(v_daily_count, 0);
  if v_daily_count >= p_daily_limit then
    return jsonb_build_object(
      'allowed', false,
      'code', 'LOGIN_DAILY_LIMIT_EXCEEDED',
      'limit', p_daily_limit,
      'used', v_daily_count,
      'retry_after', v_day_start + interval '1 day'
    );
  end if;

  insert into auth_login_attempts (identifier, window_type, window_start, request_count)
  values (p_identifier, 'minute', v_minute_start, 1)
  on conflict (identifier, window_type, window_start)
  do update set
    request_count = auth_login_attempts.request_count + 1,
    updated_at = v_now
  returning request_count into v_minute_count;

  insert into auth_login_attempts (identifier, window_type, window_start, request_count)
  values (p_identifier, 'day', v_day_start, 1)
  on conflict (identifier, window_type, window_start)
  do update set
    request_count = auth_login_attempts.request_count + 1,
    updated_at = v_now
  returning request_count into v_daily_count;

  return jsonb_build_object(
    'allowed', true,
    'minute_limit', p_minute_limit,
    'minute_used', v_minute_count,
    'daily_limit', p_daily_limit,
    'daily_used', v_daily_count
  );
end;
$$;

revoke all on function consume_login_attempt(text, integer, integer) from public, anon, authenticated;
grant execute on function consume_login_attempt(text, integer, integer) to service_role;
