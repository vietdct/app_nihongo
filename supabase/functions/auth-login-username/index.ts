// Đăng nhập bằng username — thay cho việc client tự gọi RPC
// get_email_by_username rồi signInWithPassword. Trước đây RPC đó cấp quyền
// cho anon nên ai cũng dò được email ứng với 1 username (không cần mật
// khẩu) — lỗ hổng lộ email. Giờ việc tra email + xác thực mật khẩu đều
// chạy trong Edge Function bằng service role key; client chỉ nhận lại
// access/refresh token (không bao giờ thấy email) rồi tự setSession().
// Luôn trả lỗi CHUNG "sai tên đăng nhập hoặc mật khẩu" cho cả 2 trường hợp
// (username không tồn tại / mật khẩu sai) để không lộ username nào tồn tại.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  AiGuardError,
  guardErrorBody,
  readJsonBody,
  requireString,
} from "../_shared/ai_guard.ts";
import { CORS_HEADERS } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "content-type": "application/json" },
  });
}

function invalidCredentials(): Response {
  return jsonResponse(
    { error: "Sai tên đăng nhập hoặc mật khẩu.", code: "INVALID_CREDENTIALS" },
    401,
  );
}

// Giới hạn theo IP chặn dò username hàng loạt từ 1 nguồn; giới hạn theo
// username chặn brute-force mật khẩu nhắm vào 1 tài khoản cụ thể dù request
// đến từ nhiều IP khác nhau.
const IP_MINUTE_LIMIT = 10;
const IP_DAILY_LIMIT = 50;
const USERNAME_MINUTE_LIMIT = 5;
const USERNAME_DAILY_LIMIT = 20;

function clientIp(req: Request): string {
  const forwardedFor = req.headers.get("x-forwarded-for");
  if (forwardedFor) return forwardedFor.split(",")[0].trim();
  return req.headers.get("cf-connecting-ip") ?? "unknown";
}

interface LoginAttemptResult {
  allowed: boolean;
  code?: string;
  limit?: number;
  used?: number;
  retry_after?: string;
}

async function consumeLoginAttempt(
  // deno-lint-ignore no-explicit-any
  admin: any,
  identifier: string,
  minuteLimit: number,
  dailyLimit: number,
): Promise<LoginAttemptResult> {
  const { data, error } = await admin.rpc("consume_login_attempt", {
    p_identifier: identifier,
    p_minute_limit: minuteLimit,
    p_daily_limit: dailyLimit,
  });

  if (error || data === null || typeof data !== "object") {
    console.error("consume_login_attempt failed:", error?.message ?? data);
    throw new AiGuardError(
      "Không kiểm tra được giới hạn đăng nhập, vui lòng thử lại.",
      503,
      "LOGIN_RATE_LIMIT_UNAVAILABLE",
    );
  }

  return data as LoginAttemptResult;
}

function rateLimited(result: LoginAttemptResult): Response {
  return jsonResponse(
    {
      error: "Bạn thao tác quá nhanh, vui lòng thử lại sau.",
      code: result.code ?? "LOGIN_RATE_LIMIT_EXCEEDED",
      limit: result.limit,
      used: result.used,
      retryAfter: result.retry_after,
    },
    429,
  );
}

// Sàn thời gian tối thiểu cho một lượt đăng nhập thất bại. Nếu không tìm
// thấy username, request trả lời gần như ngay lập tức trong khi nhánh sai
// mật khẩu phải chờ round-trip signInWithPassword (thường lâu hơn) — chênh
// lệch đó đủ để dò xem 1 username có tồn tại hay không. Đợi thêm cho đủ
// mốc này ở mọi nhánh thất bại để san bằng thời gian phản hồi.
const MIN_FAILURE_RESPONSE_MS = 400;

async function equalizeFailureTiming(startedAt: number): Promise<void> {
  const elapsed = Date.now() - startedAt;
  const remaining = MIN_FAILURE_RESPONSE_MS - elapsed;
  if (remaining > 0) {
    await new Promise((resolve) => setTimeout(resolve, remaining));
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const requestStartedAt = Date.now();

  try {
    const body = await readJsonBody(req, 4 * 1024);
    const username = requireString(body.username, "username", 30);
    const password = requireString(body.password, "password", 128, {
      trim: false,
    });

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const ipCheck = await consumeLoginAttempt(
      admin,
      `ip:${clientIp(req)}`,
      IP_MINUTE_LIMIT,
      IP_DAILY_LIMIT,
    );
    if (!ipCheck.allowed) return rateLimited(ipCheck);

    const usernameCheck = await consumeLoginAttempt(
      admin,
      `username:${username.toLowerCase()}`,
      USERNAME_MINUTE_LIMIT,
      USERNAME_DAILY_LIMIT,
    );
    if (!usernameCheck.allowed) return rateLimited(usernameCheck);

    const { data: email, error: lookupError } = await admin.rpc(
      "get_email_by_username",
      { p_username: username },
    );

    if (lookupError) {
      console.error("get_email_by_username failed:", lookupError.message);
      return jsonResponse({ error: "Lỗi máy chủ, vui lòng thử lại." }, 500);
    }
    if (!email) {
      await equalizeFailureTiming(requestStartedAt);
      return invalidCredentials();
    }

    const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    const { data: signInData, error: signInError } = await authClient.auth
      .signInWithPassword({ email, password });

    if (signInError || !signInData.session) {
      await equalizeFailureTiming(requestStartedAt);
      return invalidCredentials();
    }

    return jsonResponse(
      {
        accessToken: signInData.session.access_token,
        refreshToken: signInData.session.refresh_token,
      },
      200,
    );
  } catch (e) {
    if (e instanceof AiGuardError) {
      return jsonResponse(guardErrorBody(e), e.status);
    }
    console.error(e);
    return jsonResponse({ error: "Lỗi không xác định." }, 500);
  }
});
