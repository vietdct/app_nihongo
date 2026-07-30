// AI Lesson Mission (Apply — pha 4/5 của Lesson Module) — proxy an toàn tới
// Google Gemini (primary) + Anthropic (fallback), cùng kiến trúc dual-provider
// đã dùng ở ai-kaiwa-chat. Khác Kaiwa tự do: AI đóng vai bạn trò chuyện và
// chủ động dẫn dắt để người học có cơ hội dùng ĐÚNG các từ vựng/mẫu ngữ pháp
// mục tiêu của bài học vừa xong — mỗi lượt trả về những mục tiêu người học
// vừa dùng đúng trong câu của họ để app tự tổng hợp tiến độ (không tự chấm
// "hoàn thành" bằng 1 lệnh gọi AI riêng — cộng dồn từ dữ liệu thật từng lượt).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  AiGuardError,
  enforceAiQuota,
  guardErrorBody,
  logAiUsage,
  optionalString,
  readJsonBody,
  requireEnum,
  requireObject,
  requireString,
  validateHistory,
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
    reply_jp: { type: "string", description: "Câu trả lời bằng tiếng Nhật, tự nhiên, đúng vai người bạn thân thiện." },
    reply_furigana: { type: "string", description: "reply_jp với furigana dạng 漢字(かんじ) trên mọi chữ Hán, giữ nguyên kana/dấu câu." },
    reply_translation_vi: { type: "string", description: "Bản dịch tiếng Việt tự nhiên của reply_jp." },
    suggested_reply_jp: {
      type: "string",
      description: "1 câu trả lời mẫu bằng tiếng Nhật mà người học có thể dùng để đáp lại, ƯU TIÊN lồng vào đó những từ vựng/mẫu ngữ pháp mục tiêu CHƯA được dùng, để gợi ý cách hoàn thành nhiệm vụ.",
    },
    suggested_reply_vi: { type: "string", description: "Bản dịch tiếng Việt của suggested_reply_jp." },
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
    used_vocab: {
      type: "array",
      items: { type: "string" },
      description: "Danh sách các từ trong target_vocab (nguyên văn chữ Nhật) mà người học VỪA dùng ĐÚNG NGHĨA trong tin nhắn họ mới gửi. Mảng rỗng nếu chưa có tin nhắn hoặc không dùng từ nào.",
    },
    used_grammar: {
      type: "array",
      items: { type: "string" },
      description: "Danh sách các mẫu trong target_grammar (nguyên văn title) mà người học VỪA dùng ĐÚNG trong tin nhắn họ mới gửi. Mảng rỗng nếu chưa có tin nhắn hoặc không dùng mẫu nào.",
    },
  },
  required: [
    "reply_jp", "reply_furigana", "reply_translation_vi",
    "suggested_reply_jp", "suggested_reply_vi", "feedback",
    "used_vocab", "used_grammar",
  ],
};

interface TargetVocab { jp: string; meaningVi: string }
interface TargetGrammar { title: string; meaningVi: string }

interface PromptParams {
  lessonTitle: string;
  jlptLevel: string;
  targetVocab: TargetVocab[];
  targetGrammar: TargetGrammar[];
  hasUserMessage: boolean;
}

function buildSystemPrompt(p: PromptParams): string {
  const vocabList = p.targetVocab.map((v) => `- ${v.jp} (${v.meaningVi})`).join("\n");
  const grammarList = p.targetGrammar.map((g) => `- ${g.title} (${g.meaningVi})`).join("\n");

  return `Bạn là một người bạn Nhật thân thiện, kiên nhẫn, đang trò chuyện tự nhiên với người học Việt Nam trình độ ${p.jlptLevel} để giúp họ ÔN LẠI bài học "${p.lessonTitle}" vừa học xong.

NHIỆM VỤ (Mission Challenge): dẫn dắt hội thoại xoay quanh chủ đề của bài học sao cho người học có cơ hội TỰ dùng các từ vựng và mẫu ngữ pháp mục tiêu dưới đây. Không liệt kê chúng ra hay yêu cầu trực tiếp "hãy dùng từ X" — hãy đặt câu hỏi/tình huống khiến từ đó là câu trả lời tự nhiên nhất.

Từ vựng mục tiêu:
${vocabList}

Mẫu ngữ pháp mục tiêu:
${grammarList}

QUY TẮC:
- Luôn trả lời bằng tiếng Nhật tự nhiên, độ khó phù hợp trình độ ${p.jlptLevel}, giọng điệu thân thiện như bạn bè (không quá trang trọng).
- has_user_message = ${p.hasUserMessage}. Nếu true: (1) chấm lượt nói vừa rồi giống hệt cách chấm hội thoại tự do — độ tự nhiên/ngữ pháp/từ vựng/lịch sự/giống người bản xứ, giải thích lỗi bằng tiếng Việt dễ hiểu, gợi ý câu tự nhiên hơn nếu cần; (2) xét CHÍNH XÁC câu người học vừa gửi (không xét các câu trước đó) rồi liệt kê vào used_vocab/used_grammar những mục tiêu họ đã dùng ĐÚNG — không đoán, không tính nếu dùng sai nghĩa/sai ngữ pháp.
- Nếu has_user_message = false (tin nhắn mở đầu), đặt rating = 0, các trường feedback còn lại là chuỗi rỗng "", used_vocab và used_grammar đều là mảng rỗng — mở đầu bằng 1 câu chào/dẫn dắt tự nhiên vào chủ đề bài học.
- Mỗi trường feedback tối đa 1-2 câu ngắn, đi thẳng vào trọng tâm.
- Luôn kèm suggested_reply_jp ưu tiên gợi ý cách dùng các mục tiêu CHƯA xuất hiện trong used_vocab/used_grammar tính đến lượt này, kèm suggested_reply_vi.
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

interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
}

interface AiCallResult {
  result: Record<string, unknown>;
  usage: TokenUsage;
}

async function callAnthropic(systemPrompt: string, messages: ChatMessage[]): Promise<AiCallResult> {
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
        name: "lesson_mission_response",
        description: "Câu trả lời tiếng Nhật của người bạn AI kèm đánh giá lượt nói vừa rồi và tiến độ mục tiêu Mission Challenge.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "lesson_mission_response" },
    }),
  });

  if (!res.ok) {
    throw new Error(`anthropic ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const toolUse = data.content?.find((c: { type: string }) => c.type === "tool_use");
  if (!toolUse) throw new Error("anthropic: không có tool_use trong phản hồi");
  return {
    result: toolUse.input,
    usage: {
      inputTokens: data.usage?.input_tokens ?? 0,
      outputTokens: data.usage?.output_tokens ?? 0,
    },
  };
}

async function callGemini(systemPrompt: string, messages: ChatMessage[]): Promise<AiCallResult> {
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
    const lessonTitle = requireString(body.lessonTitle, "lessonTitle", 160);
    const jlptLevel = requireEnum(body.jlptLevel, "jlptLevel", ["N5", "N4", "N3", "N2", "N1"]);
    if (!Array.isArray(body.targetVocab) || body.targetVocab.length > 30) {
      throw new AiGuardError(
        "Trường targetVocab phải là mảng tối đa 30 phần tử.",
        400,
        "INVALID_REQUEST",
        { field: "targetVocab" },
      );
    }
    const targetVocab: TargetVocab[] = body.targetVocab.map((item, index) => {
      const value = requireObject(item, `targetVocab[${index}]`);
      return {
        jp: requireString(value.jp, `targetVocab[${index}].jp`, 120),
        meaningVi: requireString(value.meaningVi, `targetVocab[${index}].meaningVi`, 300),
      };
    });
    if (!Array.isArray(body.targetGrammar) || body.targetGrammar.length > 20) {
      throw new AiGuardError(
        "Trường targetGrammar phải là mảng tối đa 20 phần tử.",
        400,
        "INVALID_REQUEST",
        { field: "targetGrammar" },
      );
    }
    const targetGrammar: TargetGrammar[] = body.targetGrammar.map((item, index) => {
      const value = requireObject(item, `targetGrammar[${index}]`);
      return {
        title: requireString(value.title, `targetGrammar[${index}].title`, 160),
        meaningVi: requireString(value.meaningVi, `targetGrammar[${index}].meaningVi`, 1000),
      };
    });
    const history = validateHistory(body.history, { maxTurns: 10, maxContentLength: 1000 });
    const message = optionalString(body.message, "message", 1000);
    const hasUserMessage = message !== null && message.length > 0;

    await enforceAiQuota(supabase, "lesson_mission");

    const systemPrompt = buildSystemPrompt({
      lessonTitle,
      jlptLevel,
      targetVocab,
      targetGrammar,
      hasUserMessage,
    });

    const messages: ChatMessage[] = [];
    for (const turn of (history ?? [])) {
      messages.push({ role: turn.role === "ai" ? "ai" : "user", content: turn.content });
    }
    messages.push({
      role: "user",
      content: hasUserMessage
        ? message ?? ""
        : "(Hãy bắt đầu cuộc hội thoại bằng một câu chào/dẫn dắt tự nhiên vào chủ đề bài học.)",
    });

    let result: Record<string, unknown> | null = null;
    let provider = "gemini";
    let modelUsed = GEMINI_MODEL;
    let usage: TokenUsage = { inputTokens: 0, outputTokens: 0 };
    let geminiErr: unknown = null;

    if (GOOGLE_AI_API_KEY) {
      try {
        const r = await callGemini(systemPrompt, messages);
        result = r.result;
        usage = r.usage;
      } catch (e) {
        geminiErr = e;
        console.error("Gemini failed:", e);
      }
    }

    if (result === null && ANTHROPIC_API_KEY) {
      try {
        provider = "anthropic";
        modelUsed = ANTHROPIC_MODEL;
        const r = await callAnthropic(systemPrompt, messages);
        result = r.result;
        usage = r.usage;
      } catch (e) {
        console.error("Anthropic fallback also failed:", e);
        return jsonResponse({ error: friendlyError(e) }, 502);
      }
    }

    if (result === null) {
      return jsonResponse({ error: friendlyError(geminiErr) }, 502);
    }

    await logAiUsage(supabase, {
      feature: "lesson_mission",
      provider,
      model: modelUsed,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
    });

    return jsonResponse({ ...result, _provider: provider }, 200);
  } catch (e) {
    if (e instanceof AiGuardError) {
      return jsonResponse(guardErrorBody(e), e.status);
    }
    console.error(e);
    return jsonResponse({ error: "Lỗi không xác định." }, 500);
  }
});
