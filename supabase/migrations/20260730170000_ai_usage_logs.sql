-- Ghi log token/chi phí thật sự của từng lượt gọi AI, theo feature + provider
-- + model. Mục đích: có dữ liệu thật để quyết định cắt giảm chi phí (feature
-- nào tốn nhất, model nào nên đổi) thay vì đoán. Khác với ai_usage_counters
-- (chỉ đếm số request để giới hạn rate/quota) — bảng này lưu token thật.

create table ai_usage_logs (
  id            bigint      generated always as identity primary key,
  user_id       uuid        not null references auth.users(id) on delete cascade,
  feature       text        not null,
  provider      text        not null,
  model         text        not null,
  input_tokens  integer     not null default 0 check (input_tokens >= 0),
  output_tokens integer     not null default 0 check (output_tokens >= 0),
  created_at    timestamptz not null default now()
);

create index ix_ai_usage_logs_feature_created on ai_usage_logs (feature, created_at);

alter table ai_usage_logs enable row level security;

-- Không tạo policy: bảng chỉ được ghi qua SECURITY DEFINER RPC bên dưới;
-- đọc để phân tích chi phí thực hiện trực tiếp bằng service role (Supabase
-- dashboard / SQL editor), không qua client app.
revoke all on table ai_usage_logs from anon, authenticated;

create or replace function log_ai_usage(
  p_feature text,
  p_provider text,
  p_model text,
  p_input_tokens integer,
  p_output_tokens integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  insert into ai_usage_logs (
    user_id, feature, provider, model, input_tokens, output_tokens
  ) values (
    v_user_id, p_feature, p_provider, p_model,
    greatest(coalesce(p_input_tokens, 0), 0),
    greatest(coalesce(p_output_tokens, 0), 0)
  );
end;
$$;

revoke all on function log_ai_usage(text, text, text, integer, integer) from public, anon;
grant execute on function log_ai_usage(text, text, text, integer, integer) to authenticated;

-- Tổng hợp nhanh theo ngày/feature/provider để so sánh chi phí — dùng khi
-- soát lại token/chi phí thay vì phải tự viết group-by mỗi lần.
create or replace view ai_usage_daily_summary as
select
  date_trunc('day', created_at) as day,
  feature,
  provider,
  model,
  count(*) as request_count,
  sum(input_tokens) as total_input_tokens,
  sum(output_tokens) as total_output_tokens
from ai_usage_logs
group by 1, 2, 3, 4;

revoke all on ai_usage_daily_summary from anon, authenticated;
