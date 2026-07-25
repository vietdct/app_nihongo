// AI Kaiwa — proxy an toàn tới Google Gemini (primary) + Anthropic (fallback).
// Nhận persona/scenario/lịch sử hội thoại từ app, trả về câu trả lời tiếng
// Nhật của AI kèm đánh giá lượt nói vừa rồi của người học (structured output
// đảm bảo JSON hợp lệ). Nếu Gemini lỗi (hết quota, rate limit...) và có
// cấu hình ANTHROPIC_API_KEY, tự động thử lại bằng Anthropic trước khi báo lỗi.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-haiku-4-5-20251001";
const GOOGLE_AI_API_KEY = Deno.env.get("GOOGLE_AI_API_KEY");
// Ghim cứng tên model cụ thể (thay vì alias "latest") để kiểm soát chi phí —
// alias có thể tự nhảy sang bản đắt hơn khi Google đổi model mặc định.
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.1-flash-lite";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Dùng chung cho cả Anthropic (bọc trong tool) và Gemini (responseSchema trực tiếp).
const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    reply_jp: { type: "string", description: "Câu trả lời bằng tiếng Nhật, đúng vai và mức lịch sự." },
    reply_furigana: { type: "string", description: "reply_jp với furigana dạng 漢字(かんじ) trên mọi chữ Hán, giữ nguyên kana/dấu câu." },
    reply_translation_vi: { type: "string", description: "Bản dịch tiếng Việt tự nhiên của reply_jp." },
    feedback: {
      type: "object",
      properties: {
        rating: { type: "integer", description: "1-5 sao; 0 nếu đây là tin nhắn mở đầu chưa có câu để chấm." },
        naturalness: { type: "string", description: "Nhận xét ngắn về độ tự nhiên." },
        grammar: { type: "string", description: "Nhận xét ngắn về ngữ pháp." },
        vocabulary: { type: "string", description: "Nhận xét ngắn về từ vựng." },
        politeness: { type: "string", description: "Nhận xét ngắn về mức độ lịch sự." },
        native_likeness: { type: "string", description: "Có giống người Nhật bản xứ nói không." },
        explanation: { type: "string", description: "Giải thích lỗi sai bằng tiếng Việt dễ hiểu (nếu có)." },
        common_mistake: { type: "string", description: "Lỗi người Việt hay mắc liên quan (nếu có)." },
        better_phrasing: { type: "string", description: "Gợi ý câu nói tự nhiên hơn bằng tiếng Nhật (nếu có)." },
      },
      required: [
        "rating", "naturalness", "grammar", "vocabulary", "politeness",
        "native_likeness", "explanation", "common_mistake", "better_phrasing",
      ],
    },
  },
  required: ["reply_jp", "reply_furigana", "reply_translation_vi", "feedback"],
};

interface PromptParams {
  personaName: string;
  personaRole: string;
  personaPersonality: string;
  politenessLevel: string;
  scenarioTitle: string;
  scenarioContext: string;
  jlptLevel: string;
  hasUserMessage: boolean;
}

function buildSystemPrompt(p: PromptParams): string {
  return `Bạn là ${p.personaName}, đóng vai "${p.personaRole}" trong một cuộc hội thoại luyện nói tiếng Nhật với người học Việt Nam trình độ ${p.jlptLevel}.
Tính cách: ${p.personaPersonality}
Mức độ lịch sự: ${p.politenessLevel} (casual = thông tục/tameguchi, polite = です/ます, keigo = kính ngữ)
Tình huống: ${p.scenarioTitle} — ${p.scenarioContext}

QUY TẮC:
- Luôn trả lời bằng tiếng Nhật tự nhiên, đúng vai, đúng mức lịch sự, độ khó phù hợp trình độ ${p.jlptLevel}.
- Chủ động hỏi lại hoặc dẫn dắt để hội thoại tiếp tục tự nhiên, không kết thúc quá sớm, không lặp lại câu hỏi cũ.
- has_user_message = ${p.hasUserMessage}. Nếu true, hãy đánh giá câu người học vừa gửi: độ tự nhiên, ngữ pháp, từ vựng, độ lịch sự, mức giống người Nhật bản xứ; giải thích lỗi sai bằng tiếng Việt dễ hiểu, nêu lỗi người Việt hay mắc liên quan nếu có, và gợi ý câu nói tự nhiên hơn. Nếu câu đã tốt, vẫn chấm điểm cao và khen ngắn gọn thay vì bịa lỗi.
- Nếu has_user_message = false (tin nhắn mở đầu cuộc hội thoại), đặt rating = 0 và để các trường feedback còn lại là chuỗi rỗng "".
- Mỗi trường feedback tối đa 1-2 câu ngắn, đi thẳng vào trọng tâm — không lặp lại nội dung giữa các trường, không viết dài dòng.
- Luôn phản hồi đúng theo cấu trúc JSON được yêu cầu, không kèm văn bản thừa.`;
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
      max_tokens: 1024,
      system: systemPrompt,
      messages: messages.map((m) => ({ role: m.role === "ai" ? "assistant" : "user", content: m.content })),
      tools: [{
        name: "kaiwa_response",
        description: "Câu trả lời tiếng Nhật của nhân vật AI kèm đánh giá lượt nói vừa rồi của người học.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "kaiwa_response" },
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
    const {
      personaName, personaRole, personaPersonality, politenessLevel,
      scenarioTitle, scenarioContext, jlptLevel, history, message,
    } = body;

    const hasUserMessage = typeof message === "string" && message.trim().length > 0;

    const systemPrompt = buildSystemPrompt({
      personaName, personaRole, personaPersonality, politenessLevel,
      scenarioTitle, scenarioContext, jlptLevel, hasUserMessage,
    });

    const messages: ChatMessage[] = [];
    for (const turn of (history ?? [])) {
      messages.push({ role: turn.role === "ai" ? "ai" : "user", content: turn.content });
    }
    messages.push({
      role: "user",
      content: hasUserMessage
        ? message
        : "(Hãy bắt đầu cuộc hội thoại bằng cách chào hỏi theo đúng vai của bạn.)",
    });

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
