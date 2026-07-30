// AI Kaiwa Tutor — proxy an toàn tới Google Gemini (primary) + Anthropic
// (fallback), cùng kiến trúc với ai-kanji-tutor/ai-grammar-tutor: hỏi-đáp
// nhanh về 1 CÂU cụ thể người học đã nói trong hội thoại + feedback AI đã
// chấm cho câu đó (không lưu lịch sử, không phải hội thoại nhập vai — đây là
// nơi hỏi sâu thêm "vì sao sai", khác `ai-kaiwa-chat` chỉ đóng vai nhân vật).
// AI bị ép giữ nguyên nội dung feedback đã chấm — không tự đổi ý ngược lại
// những gì app đã hiển thị cho người học.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-haiku-4-5-20251001";
const GOOGLE_AI_API_KEY = Deno.env.get("GOOGLE_AI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.1-flash-lite";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    reply: {
      type: "string",
      description: "Câu trả lời bằng tiếng Việt, ngắn gọn (2-5 câu), đúng trọng tâm câu hỏi, dễ hiểu với người mới học tiếng Nhật.",
    },
    suggestedQuestions: {
      type: "array",
      items: { type: "string" },
      description: "2-3 câu hỏi gợi ý tiếp theo, ngắn gọn, xoay quanh chính câu nói đang hỏi (VD cách nói lịch sự hơn, mẫu câu tương tự, vì sao dùng trợ từ này).",
    },
  },
  required: ["reply", "suggestedQuestions"],
};

interface TurnContext {
  originalSentence: string;
  betterPhrasing: string | null;
  explanation: string | null;
  commonMistake: string | null;
  grammarNote: string | null;
  vocabularyNote: string | null;
  politenessNote: string | null;
  personaName: string;
  scenarioTitle: string;
}

function buildSystemPrompt(t: TurnContext): string {
  return `Bạn là gia sư tiếng Nhật, đang giúp người học Việt Nam hiểu rõ hơn về 1 câu họ vừa nói trong buổi hội thoại luyện tập với AI Kaiwa (nhân vật "${t.personaName}", tình huống "${t.scenarioTitle}").

CÂU NGƯỜI HỌC ĐÃ NÓI: 「${t.originalSentence}」

FEEDBACK APP ĐÃ CHẤM CHO CÂU NÀY (đây là NGUỒN DUY NHẤT, đã hiển thị cho người học — TUYỆT ĐỐI không nói ngược lại hay phủ nhận feedback này, chỉ được giải thích/mở rộng thêm):
- Câu tự nhiên hơn: ${t.betterPhrasing ?? '(không có, câu gốc đã ổn)'}
- Giải thích: ${t.explanation ?? '(chưa có)'}
- Lỗi thường gặp liên quan: ${t.commonMistake ?? '(chưa có)'}
- Nhận xét ngữ pháp: ${t.grammarNote ?? '(chưa có)'}
- Nhận xét từ vựng: ${t.vocabularyNote ?? '(chưa có)'}
- Nhận xét độ lịch sự: ${t.politenessNote ?? '(chưa có)'}

QUY TẮC:
- Trả lời đúng trọng tâm câu hỏi, tiếng Việt tự nhiên, ngắn gọn (2-5 câu), phù hợp người mới học.
- Có thể đưa thêm ví dụ câu tương tự, cách nói khác cùng nghĩa, hoặc giải thích sâu hơn về ngữ pháp/trợ từ liên quan.
- Nếu người học hỏi điều gì đó KHÔNG có trong feedback trên và bạn không chắc chắn, hãy nói rõ là không chắc thay vì bịa.
- Nếu câu hỏi không liên quan gì tới câu nói/tiếng Nhật đang bàn, lịch sự từ chối và hướng người học quay lại chủ đề.
- Luôn kèm 2-3 suggestedQuestions liên quan tới câu này để người học bấm hỏi tiếp.
- Luôn phản hồi đúng cấu trúc JSON được yêu cầu, không kèm văn bản thừa.`;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "content-type": "application/json" },
  });
}

interface ChatMessage {
  role: string; // 'user' | 'ai'
  content: string;
}

async function callAnthropic(systemPrompt: string, messages: ChatMessage[]): Promise<Record<string, unknown>> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 512,
      system: systemPrompt,
      messages: messages.map((m) => ({ role: m.role === "ai" ? "assistant" : "user", content: m.content })),
      tools: [{
        name: "kaiwa_tutor_response",
        description: "Câu trả lời cho câu hỏi của người học về câu họ vừa nói, kèm câu hỏi gợi ý tiếp theo.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "kaiwa_tutor_response" },
    }),
  });

  if (!res.ok) {
    throw new Error(`anthropic ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const toolUse = data.content?.find((c: { type: string }) => c.type === "tool_use");
  if (!toolUse) throw new Error("anthropic: không có tool_use trong phản hồi");
  return toolUse.input;
}

async function callGemini(systemPrompt: string, messages: ChatMessage[]): Promise<Record<string, unknown>> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GOOGLE_AI_API_KEY}`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: messages.map((m) => ({ role: m.role === "ai" ? "model" : "user", parts: [{ text: m.content }] })),
        systemInstruction: { parts: [{ text: systemPrompt }] },
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
  return JSON.parse(text);
}

function friendlyError(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes("credit balance is too low")) {
    return "Tài khoản Anthropic hết credit — vào console.anthropic.com > Plans & Billing để nạp thêm.";
  }
  if (msg.includes("RESOURCE_EXHAUSTED") || msg.includes("quota")) {
    return "Đã hết quota AI miễn phí hôm nay, vui lòng thử lại sau.";
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

    if (!ANTHROPIC_API_KEY && !GOOGLE_AI_API_KEY) {
      return jsonResponse({ error: "Server chưa cấu hình ANTHROPIC_API_KEY hoặc GOOGLE_AI_API_KEY" }, 500);
    }

    const body = await req.json();
    const { turn, history, message } = body as { turn: TurnContext; history: ChatMessage[]; message: string };

    const systemPrompt = buildSystemPrompt(turn);

    const messages: ChatMessage[] = [];
    for (const t of (history ?? [])) {
      messages.push({ role: t.role === "ai" ? "ai" : "user", content: t.content });
    }
    messages.push({ role: "user", content: message });

    let result: Record<string, unknown> | null = null;
    let provider = "gemini";
    let geminiErr: unknown = null;

    if (GOOGLE_AI_API_KEY) {
      try {
        result = await callGemini(systemPrompt, messages);
      } catch (e) {
        geminiErr = e;
        console.error("Gemini failed:", e);
      }
    }

    if (result === null && ANTHROPIC_API_KEY) {
      try {
        provider = "anthropic";
        result = await callAnthropic(systemPrompt, messages);
      } catch (e) {
        console.error("Anthropic fallback also failed:", e);
        return jsonResponse({ error: friendlyError(e) }, 502);
      }
    }

    if (result === null) {
      return jsonResponse({ error: friendlyError(geminiErr) }, 502);
    }

    return jsonResponse({ ...result, _provider: provider }, 200);
  } catch (e) {
    console.error(e);
    return jsonResponse({ error: "Lỗi không xác định." }, 500);
  }
});
