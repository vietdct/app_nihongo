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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const body = await readJsonBody(req, 4 * 1024);
    const username = requireString(body.username, "username", 30);
    const password = requireString(body.password, "password", 128);

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: email, error: lookupError } = await admin.rpc(
      "get_email_by_username",
      { p_username: username },
    );

    if (lookupError) {
      console.error("get_email_by_username failed:", lookupError.message);
      return jsonResponse({ error: "Lỗi máy chủ, vui lòng thử lại." }, 500);
    }
    if (!email) {
      return invalidCredentials();
    }

    const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    const { data: signInData, error: signInError } = await authClient.auth
      .signInWithPassword({ email, password });

    if (signInError || !signInData.session) {
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
