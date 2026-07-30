// AI Kanji Tutor — proxy an toàn tới Google Gemini (primary) + Anthropic
// (fallback), cùng kiến trúc với ai-kaiwa-chat nhưng schema nhẹ hơn nhiều:
// đây là hỏi-đáp nhanh về 1 chữ Hán cụ thể (không chấm điểm phát âm, không
// cần lưu hội thoại). Dữ liệu thật của chữ Hán (on/kun/Hán Việt/nghĩa...)
// được app gửi kèm và AI bị ép chỉ dùng đúng dữ liệu đó — không tự đổi
// sang cách đọc khác dù "biết" cách đọc khác, tránh bịa thông tin sai.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  AiGuardError,
  enforceAiQuota,
  guardErrorBody,
  optionalString,
  readJsonBody,
  requireObject,
  requireString,
  validateHistory,
  validateStringArray,
} from "../_shared/ai_guard.ts";
import { CORS_HEADERS } from "../_shared/cors.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-haiku-4-5-20251001";
const GOOGLE_AI_API_KEY = Deno.env.get("GOOGLE_AI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.1-flash-lite";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

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
      description: "2-3 câu hỏi gợi ý tiếp theo, ngắn gọn, xoay quanh chính chữ Hán đang hỏi (VD mẹo nhớ khác, từ ví dụ khác, dễ nhầm với chữ nào).",
    },
  },
  required: ["reply", "suggestedQuestions"],
};

interface KanjiContext {
  character: string;
  hanViet: string[];
  meaningVi: string[];
  onyomi: string[];
  kunyomi: string[];
  mnemonic: string | null;
  exampleJp: string | null;
  exampleVi: string | null;
  relatedVocab: string[];
  familyParents: string[];
  familyChildren: string[];
}

function buildSystemPrompt(k: KanjiContext): string {
  return `Bạn là gia sư tiếng Nhật, đang giúp người học Việt Nam hiểu chữ Hán "${k.character}".

DỮ LIỆU THẬT của chữ này (đây là NGUỒN DUY NHẤT bạn được dùng để nói về on/kun/Hán Việt/nghĩa — TUYỆT ĐỐI không tự đổi sang cách đọc hoặc nghĩa khác dù bạn biết cách đọc khác, vì app đã kiểm chứng đúng dữ liệu này):
- Hán Việt: ${k.hanViet.join('、') || '(chưa có)'}
- Nghĩa: ${k.meaningVi.join('、') || '(chưa có)'}
- Onyomi: ${k.onyomi.join('、') || '(chưa có)'}
- Kunyomi: ${k.kunyomi.join('、') || '(chưa có)'}
- Mẹo ghi nhớ hiện có trong app: ${k.mnemonic ?? '(chưa có)'}
- Ví dụ: ${k.exampleJp ?? '(chưa có)'}${k.exampleVi ? ` — ${k.exampleVi}` : ''}
- Từ vựng chứa chữ này: ${k.relatedVocab.join('、') || '(chưa có)'}
- Chữ ghép nên chữ này (bộ thủ): ${k.familyParents.join('、') || '(không có quan hệ đã biết)'}
- Chữ khác dùng chữ này làm bộ: ${k.familyChildren.join('、') || '(không có quan hệ đã biết)'}

QUY TẮC:
- Trả lời đúng trọng tâm câu hỏi, tiếng Việt tự nhiên, ngắn gọn (2-5 câu), phù hợp người mới học.
- Có thể gợi ý mẹo ghi nhớ MỚI (khác mẹo đã có) nếu người học hỏi, miễn là không mâu thuẫn với on/kun/nghĩa thật ở trên.
- Nếu người học hỏi điều gì đó KHÔNG có trong dữ liệu trên và bạn không chắc chắn, hãy nói rõ là không chắc thay vì bịa.
- Nếu câu hỏi không liên quan gì tới chữ Hán/tiếng Nhật, lịch sự từ chối và hướng người học quay lại chủ đề chữ "${k.character}".
- Luôn kèm 2-3 suggestedQuestions liên quan tới chữ này để người học bấm hỏi tiếp.
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
        name: "kanji_tutor_response",
        description: "Câu trả lời cho câu hỏi của người học về chữ Hán, kèm câu hỏi gợi ý tiếp theo.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "kanji_tutor_response" },
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

    const body = await readJsonBody(req);
    const kanjiBody = requireObject(body.kanji, "kanji");
    const kanji: KanjiContext = {
      character: requireString(kanjiBody.character, "kanji.character", 8),
      hanViet: validateStringArray(kanjiBody.hanViet ?? [], "kanji.hanViet", 12, 64),
      meaningVi: validateStringArray(kanjiBody.meaningVi ?? [], "kanji.meaningVi", 20, 160),
      onyomi: validateStringArray(kanjiBody.onyomi ?? [], "kanji.onyomi", 20, 80),
      kunyomi: validateStringArray(kanjiBody.kunyomi ?? [], "kanji.kunyomi", 20, 80),
      mnemonic: optionalString(kanjiBody.mnemonic, "kanji.mnemonic", 2000),
      exampleJp: optionalString(kanjiBody.exampleJp, "kanji.exampleJp", 1000),
      exampleVi: optionalString(kanjiBody.exampleVi, "kanji.exampleVi", 1000),
      relatedVocab: validateStringArray(kanjiBody.relatedVocab ?? [], "kanji.relatedVocab", 30, 160),
      familyParents: validateStringArray(kanjiBody.familyParents ?? [], "kanji.familyParents", 20, 8),
      familyChildren: validateStringArray(kanjiBody.familyChildren ?? [], "kanji.familyChildren", 20, 8),
    };
    const history = validateHistory(body.history, { maxTurns: 20, maxContentLength: 1000 });
    const message = requireString(body.message, "message", 1000);

    await enforceAiQuota(supabase, "kanji_tutor");

    const systemPrompt = buildSystemPrompt(kanji);

    const messages: ChatMessage[] = [];
    for (const turn of (history ?? [])) {
      messages.push({ role: turn.role === "ai" ? "ai" : "user", content: turn.content });
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
    if (e instanceof AiGuardError) {
      return jsonResponse(guardErrorBody(e), e.status);
    }
    console.error(e);
    return jsonResponse({ error: "Lỗi không xác định." }, 500);
  }
});
