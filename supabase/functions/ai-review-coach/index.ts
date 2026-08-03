// AI Review Coach — cùng kiến trúc provider với ai-kaiwa-tutor/ai-grammar-tutor
// (Gemini primary + Anthropic fallback, quota/token tracking qua ai_guard.ts),
// nhưng KHÔNG phải hội thoại tự do: chỉ trả lời 1 trong 5 câu hỏi mẫu cố định
// về các lỗi thật đã ghi nhận ở Mistake Notebook (docs/REVIEW_DESIGN.md §12).
// AI chỉ được diễn giải/đề xuất — không tạo phiên ôn thật, không tự bịa lỗi
// ngoài danh sách `mistakes` client gửi lên.

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
} from "../_shared/ai_guard.ts";
import { CORS_HEADERS } from "../_shared/cors.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-haiku-4-5-20251001";
const GOOGLE_AI_API_KEY = Deno.env.get("GOOGLE_AI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.1-flash-lite";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const QUESTION_KEYS = [
  "why_wrong",
  "explain_again",
  "example_variants",
  "quiz_from_mistakes",
  "review_yesterday",
] as const;
type QuestionKey = typeof QUESTION_KEYS[number];

const QUESTION_TEXT: Record<QuestionKey, string> = {
  why_wrong: "Vì sao tôi hay sai những lỗi này?",
  explain_again: "Giải thích lại giúp tôi các lỗi này, dễ hiểu hơn.",
  example_variants: "Cho tôi thêm ví dụ dễ hơn và ví dụ khó hơn cho các lỗi này.",
  quiz_from_mistakes: "Tạo một quiz ngắn (3-5 câu) từ chính các lỗi của tôi, kèm đáp án ở cuối để tôi tự chấm.",
  review_yesterday: "Ôn lại giúp tôi các lỗi tôi đã gặp hôm qua.",
};

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    reply: {
      type: "string",
      description: "Câu trả lời tiếng Việt, dựa đúng vào danh sách lỗi được cung cấp, không bịa lỗi khác. Với quiz thì trình bày câu hỏi trước, đáp án ở cuối rõ ràng (vd sau dòng 'Đáp án:').",
    },
  },
  required: ["reply"],
};

interface MistakeInput {
  sourceType: string;
  correctAnswer: string;
  explanation: string | null;
  occurrenceCount: number;
  updatedAt: string | null;
}

function buildSystemPrompt(question: QuestionKey, mistakes: MistakeInput[], nowIso: string): string {
  const sourceLabel: Record<string, string> = {
    vocab: "Từ vựng",
    kanji: "Kanji",
    grammar: "Ngữ pháp",
  };
  const list = mistakes.length === 0
    ? "(không có lỗi nào được cung cấp)"
    : mistakes.map((m, i) => {
      const label = sourceLabel[m.sourceType] ?? m.sourceType;
      return `${i + 1}. [${label}] Đáp án đúng: "${m.correctAnswer}"${m.explanation ? ` — Giải thích: ${m.explanation}` : ""} — đã sai ${m.occurrenceCount} lần${m.updatedAt ? `, lần gần nhất: ${m.updatedAt}` : ""}`;
    }).join("\n");

  return `Bạn là AI Review Coach của app học tiếng Nhật Nihongo, giúp người học Việt Nam hiểu vì sao họ hay sai và ôn lại đúng trọng tâm.

THỜI ĐIỂM HIỆN TẠI: ${nowIso}

DANH SÁCH LỖI THẬT NGƯỜI HỌC ĐÃ GHI NHẬN (NGUỒN DUY NHẤT — không bịa thêm lỗi nào ngoài danh sách này):
${list}

CÂU HỎI NGƯỜI HỌC CHỌN: "${QUESTION_TEXT[question]}"

QUY TẮC:
- Trả lời tiếng Việt, ngắn gọn nhưng đủ ý (khoảng 4-8 câu, hoặc dài hơn nếu là quiz).
- Chỉ dựa vào danh sách lỗi trên. Nếu danh sách rỗng, nói rõ chưa có dữ liệu và gợi ý làm vài lượt ôn tập trước, không tự chế lỗi giả.
- Với câu hỏi "Ôn lại bài hôm qua": chỉ tập trung vào lỗi có "lần gần nhất" rơi vào khoảng 24 giờ trước THỜI ĐIỂM HIỆN TẠI; nếu không có lỗi nào trong khoảng đó, nói rõ không có lỗi nào ghi nhận hôm qua, gợi ý xem toàn bộ Sổ tay lỗi hoặc dùng Smart Review.
- Với câu hỏi "Tạo quiz từ lỗi của tôi": chỉ soạn quiz để đọc ngay trong câu trả lời (không tạo phiên ôn thật trong app), đáp án đặt rõ ràng ở cuối.
- Không tự ghi hay đề xuất thay đổi lịch ôn tập (SRS) — chỉ diễn giải và đề xuất, việc ôn lại thật do người học tự bấm vào Smart Review/Weak Points.
- Giọng văn khích lệ, không chê trách.
- Luôn phản hồi đúng cấu trúc JSON được yêu cầu, không kèm văn bản thừa.`;
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

interface AiCallResult {
  result: Record<string, unknown>;
  usage: TokenUsage;
}

async function callAnthropic(systemPrompt: string): Promise<AiCallResult> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 768,
      system: systemPrompt,
      messages: [{ role: "user", content: "Hãy trả lời theo đúng câu hỏi và quy tắc ở trên." }],
      tools: [{
        name: "review_coach_response",
        description: "Câu trả lời của AI Review Coach cho câu hỏi mẫu người học đã chọn.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "review_coach_response" },
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

async function callGemini(systemPrompt: string): Promise<AiCallResult> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GOOGLE_AI_API_KEY}`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: "Hãy trả lời theo đúng câu hỏi và quy tắc ở trên." }] }],
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

const MAX_MISTAKES = 15;

function parseMistakes(value: unknown): MistakeInput[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) {
    throw new AiGuardError("Trường mistakes phải là mảng.", 400, "INVALID_REQUEST", { field: "mistakes" });
  }
  if (value.length > MAX_MISTAKES) {
    throw new AiGuardError(
      `mistakes không được vượt quá ${MAX_MISTAKES} phần tử.`,
      400,
      "INVALID_REQUEST",
      { field: "mistakes" },
    );
  }
  return value.map((item, index) => {
    const m = requireObject(item, `mistakes[${index}]`);
    const rawCount = m.occurrenceCount;
    const occurrenceCount = typeof rawCount === "number" && Number.isFinite(rawCount)
      ? Math.max(0, Math.trunc(rawCount))
      : 1;
    const rawUpdatedAt = m.updatedAt;
    const updatedAt = typeof rawUpdatedAt === "string" && !Number.isNaN(Date.parse(rawUpdatedAt))
      ? rawUpdatedAt
      : null;
    return {
      sourceType: requireEnum(m.sourceType, `mistakes[${index}].sourceType`, ["vocab", "kanji", "grammar"]),
      correctAnswer: requireString(m.correctAnswer, `mistakes[${index}].correctAnswer`, 200),
      explanation: optionalString(m.explanation, `mistakes[${index}].explanation`, 1000),
      occurrenceCount,
      updatedAt,
    };
  });
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
    const questionKey = requireEnum(body.questionKey, "questionKey", QUESTION_KEYS);
    const mistakes = parseMistakes(body.mistakes);

    await enforceAiQuota(supabase, "review_coach");

    const systemPrompt = buildSystemPrompt(questionKey, mistakes, new Date().toISOString());

    let result: Record<string, unknown> | null = null;
    let provider = "gemini";
    let modelUsed = GEMINI_MODEL;
    let usage: TokenUsage = { inputTokens: 0, outputTokens: 0 };
    let geminiErr: unknown = null;

    if (GOOGLE_AI_API_KEY) {
      try {
        const r = await callGemini(systemPrompt);
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
        const r = await callAnthropic(systemPrompt);
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
      feature: "review_coach",
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
