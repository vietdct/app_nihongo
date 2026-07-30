// AI Pronunciation Feedback — nghe file audio người học ghi âm khi luyện
// Shadowing (`KaiwaShadowingScreen`), so với câu mẫu, trả về nhận xét CHỦ
// QUAN của AI (không phải điểm đo phoneme/ngữ điệu khoa học — app chưa tích
// hợp dịch vụ chấm phát âm chuyên dụng như Azure Pronunciation Assessment).
// Chỉ dùng Gemini vì đây là request có audio — Claude trong kiến trúc app
// hiện tại chỉ dùng cho text nên KHÔNG có fallback Anthropic ở function này,
// khác các ai-*-tutor khác.
//
// QUAN TRỌNG — model KHÔNG dùng chung biến GEMINI_MODEL với các function
// khác (ai-kaiwa-chat/ai-kaiwa-tutor/...): thực nghiệm cho thấy
// gemini-3.1-flash-lite (model rẻ nhất, mặc định của các function kia) BỊA
// RA transcript khớp y hệt câu mẫu + khen "rất tốt" ngay cả với audio im
// lặng hoàn toàn hoặc tiếng bíp không phải giọng nói — vi phạm trực tiếp yêu
// cầu honest data. Test chéo 4 case (im lặng/tiếng bíp/nói đúng/nói sai) cho
// thấy gemini-3.1-pro-preview là model duy nhất xử lý đúng cả 4 case, nên
// dùng riêng 1 biến PRONUNCIATION_GEMINI_MODEL cho function này để tránh
// vô tình đổi luôn model (và chi phí) của các tính năng AI khác đang ổn định.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  AiGuardError,
  enforceAiQuota,
  guardErrorBody,
  logAiUsage,
  readJsonBody,
  requireEnum,
  requireString,
} from "../_shared/ai_guard.ts";
import { CORS_HEADERS } from "../_shared/cors.ts";

const GOOGLE_AI_API_KEY = Deno.env.get("GOOGLE_AI_API_KEY");
const GEMINI_MODEL = Deno.env.get("PRONUNCIATION_GEMINI_MODEL") ?? "gemini-3.1-pro-preview";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

// Giới hạn kích thước audio nhận vào — 1 câu shadowing chỉ vài giây, chặn
// request bất thường để tránh tốn token audio ngoài ý muốn.
const MAX_AUDIO_BYTES = 6 * 1024 * 1024;

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    heardText: {
      type: "string",
      description: "Những gì bạn nghe được từ audio, viết bằng tiếng Nhật (kana/kanji tùy audio). Để chuỗi rỗng nếu không nghe rõ hoặc audio im lặng — KHÔNG đoán bừa.",
    },
    impression: {
      type: "string",
      enum: ["rat_tot", "kha_tot", "can_luyen_them", "chua_ro"],
      description: "Cảm nhận CHỦ QUAN về mức độ gần với câu mẫu (phát âm + ngữ điệu tổng thể, không phải điểm đo khoa học). 'chua_ro' nếu audio không nghe được hoặc gần như im lặng.",
    },
    comment: {
      type: "string",
      description: "Nhận xét ngắn gọn 1-3 câu, tiếng Việt, giọng khích lệ. Nếu có từ/âm cụ thể nghe chưa chuẩn thì chỉ ra, nếu không có gì đặc biệt thì khen ngắn gọn. Nếu audio không nghe được thì nói rõ và gợi ý ghi âm lại gần mic hơn.",
    },
  },
  required: ["heardText", "impression", "comment"],
};

function buildSystemPrompt(targetJp: string): string {
  return `Bạn là giáo viên tiếng Nhật, đang nghe 1 đoạn audio ngắn người học Việt Nam ghi âm khi luyện nói theo câu mẫu (kiểu Shadowing).

CÂU MẪU NGƯỜI HỌC ĐANG LUYỆN NÓI THEO: 「${targetJp}」

Nhiệm vụ: nghe audio đính kèm, so với câu mẫu trên, rồi trả về đúng cấu trúc JSON yêu cầu.

QUY TẮC BẮT BUỘC:
- Đây là NHẬN XÉT CHỦ QUAN của bạn khi nghe qua audio nén, KHÔNG PHẢI phép đo phoneme/ngữ điệu khoa học chính xác — tuyệt đối không dùng số phần trăm hay điểm số cụ thể trong "comment", chỉ dùng "impression" (4 mức đã định nghĩa) + nhận xét định tính.
- "heardText" phải là điều bạn THỰC SỰ nghe thấy — nếu không rõ hoặc audio gần như im lặng/nhiễu, để chuỗi rỗng và impression = "chua_ro", KHÔNG bịa ra 1 câu nghe giống câu mẫu chỉ vì biết trước đáp án.
- Giọng điệu khích lệ, phù hợp người mới học, không chê bai nặng nề.
- Luôn phản hồi đúng cấu trúc JSON, không kèm văn bản thừa.`;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "content-type": "application/json" },
  });
}

interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
}

async function callGemini(
  targetJp: string,
  audioBase64: string,
  mimeType: string,
  model: string,
): Promise<{ result: Record<string, unknown>; usage: TokenUsage }> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GOOGLE_AI_API_KEY}`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: [{
          role: "user",
          parts: [
            { inlineData: { mimeType, data: audioBase64 } },
            { text: "Hãy nghe audio trên và nhận xét theo đúng vai trò đã mô tả." },
          ],
        }],
        systemInstruction: { parts: [{ text: buildSystemPrompt(targetJp) }] },
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RESPONSE_SCHEMA,
        },
      }),
    },
  );

  if (!res.ok) {
    throw new Error(`gemini ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error("gemini: phản hồi rỗng");
  return {
    result: JSON.parse(text),
    usage: {
      inputTokens: data.usageMetadata?.promptTokenCount ?? 0,
      outputTokens: data.usageMetadata?.candidatesTokenCount ?? 0,
    },
  };
}

function friendlyError(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes("RESOURCE_EXHAUSTED") || msg.includes("quota")) {
    return "Đã hết quota AI miễn phí hôm nay, vui lòng thử lại sau.";
  }
  if (msg.includes("INVALID_ARGUMENT")) {
    return "Không đọc được file audio, vui lòng ghi âm lại.";
  }
  return "Lỗi gọi AI, vui lòng thử lại.";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Thiếu Authorization header" }, 401);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData?.user) {
      return jsonResponse({ error: "Không xác thực được người dùng" }, 401);
    }

    if (!GOOGLE_AI_API_KEY) {
      return jsonResponse({ error: "Server chưa cấu hình GOOGLE_AI_API_KEY" }, 500);
    }

    const body = await readJsonBody(req, 9 * 1024 * 1024);
    const targetJp = requireString(body.targetJp, "targetJp", 1000);
    const mimeType = requireEnum(body.mimeType, "mimeType", ["audio/wav"]);
    const audioBase64 = requireString(
      body.audioBase64,
      "audioBase64",
      Math.ceil(MAX_AUDIO_BYTES * 4 / 3) + 4,
    );
    if (!/^[A-Za-z0-9+/]*={0,2}$/.test(audioBase64) || audioBase64.length % 4 !== 0) {
      throw new AiGuardError(
        "Dữ liệu audio base64 không hợp lệ.",
        400,
        "INVALID_REQUEST",
        { field: "audioBase64" },
      );
    }
    const padding = audioBase64.endsWith("==") ? 2 : audioBase64.endsWith("=") ? 1 : 0;
    const decodedBytes = audioBase64.length * 3 / 4 - padding;
    if (decodedBytes > MAX_AUDIO_BYTES) {
      throw new AiGuardError(
        "File audio quá lớn.",
        413,
        "REQUEST_TOO_LARGE",
        { maxBytes: MAX_AUDIO_BYTES },
      );
    }

    await enforceAiQuota(supabase, "pronunciation");

    const { result, usage } = await callGemini(targetJp, audioBase64, mimeType, GEMINI_MODEL);

    await logAiUsage(supabase, {
      feature: "pronunciation",
      provider: "gemini",
      model: GEMINI_MODEL,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
    });

    return jsonResponse(result, 200);
  } catch (e) {
    if (e instanceof AiGuardError) {
      return jsonResponse(guardErrorBody(e), e.status);
    }
    console.error(e);
    return jsonResponse({ error: friendlyError(e) }, 502);
  }
});
