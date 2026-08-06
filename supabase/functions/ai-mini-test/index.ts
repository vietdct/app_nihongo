// AI Mini Test (docs/JLPT_MINI_TEST_DESIGN.md §2/§11, Task 11) — proxy an
// toàn tới Google Gemini (primary) + Anthropic (fallback), cùng kiến trúc
// dual-provider đã dùng ở ai-lesson-mission/ai-review-coach. Khác các
// function Q&A khác: trả về CẢ 1 đề trắc nghiệm (nhiều câu hỏi) trong 1 lần
// gọi, dựa trên N lỗi/điểm yếu gần nhất của người học (pattern giới hạn
// context giống ai-review-coach) — không gửi toàn bộ Mistake Notebook.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  AiGuardError,
  enforceAiQuota,
  guardErrorBody,
  logAiUsage,
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

const JLPT_LEVELS = ["N5", "N4", "N3", "N2", "N1"] as const;
const SOURCE_TYPES = ["vocabulary", "grammar", "kanji"] as const;
const MAX_MISTAKES_SENT = 15;

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    questions: {
      type: "array",
      description: "Danh sách câu hỏi trắc nghiệm, đúng số lượng question_count đã yêu cầu.",
      items: {
        type: "object",
        properties: {
          source_type: {
            type: "string",
            enum: ["vocabulary", "grammar", "kanji"],
            description: "Loại nội dung câu hỏi kiểm tra.",
          },
          prompt_vi: {
            type: "string",
            description: "Hướng dẫn/câu hỏi ngắn bằng tiếng Việt, VD 'Từ này có nghĩa là gì?' hoặc 'Chọn từ đúng điền vào chỗ trống'.",
          },
          display_jp: {
            type: "string",
            description: "Nội dung tiếng Nhật chính hiển thị giữa câu hỏi (từ vựng/kanji/câu có chỗ trống ___).",
          },
          options: {
            type: "array",
            items: { type: "string" },
            description: "Đúng 4 lựa chọn, chỉ 1 đáp án đúng, 3 lựa chọn còn lại là nhiễu hợp lý cùng loại/trình độ, không trùng đáp án đúng.",
          },
          correct_index: {
            type: "integer",
            description: "Chỉ số (0-3) của đáp án đúng trong options.",
          },
        },
        required: ["source_type", "prompt_vi", "display_jp", "options", "correct_index"],
      },
    },
  },
  required: ["questions"],
};

interface MistakeContext {
  sourceType: string;
  correctAnswer: string;
  explanation: string | null;
  occurrenceCount: number;
}

interface PromptParams {
  jlptLevel: string;
  questionCount: number;
  mistakes: MistakeContext[];
  sources: string[];
}

function buildSystemPrompt(p: PromptParams): string {
  const mistakesList = p.mistakes.length > 0
    ? p.mistakes.map((m) =>
      `- [${m.sourceType}] đáp án đúng: "${m.correctAnswer}"${m.explanation ? ` — ${m.explanation}` : ""} (đã sai ${m.occurrenceCount} lần)`
    ).join("\n")
    : "(Người học chưa có lỗi nào được ghi nhận — tạo đề ôn tập tổng quát ở trình độ mục tiêu.)";
  const sourcesList = p.sources.join(", ");

  return `Bạn là chuyên gia luyện thi JLPT, soạn 1 đề Mini Test trắc nghiệm ĐÚNG ${p.questionCount} câu cho người học tiếng Nhật trình độ mục tiêu ${p.jlptLevel}.

DANH SÁCH LỖI GẦN ĐÂY CỦA NGƯỜI HỌC (ưu tiên ra câu hỏi xoay quanh các điểm này, tạo biến thể/ngữ cảnh MỚI để kiểm tra lại — không sao chép y nguyên):
${mistakesList}

QUY TẮC BẮT BUỘC:
- Sinh ĐÚNG ${p.questionCount} câu hỏi, MỖI câu source_type chỉ được thuộc 1 trong các loại người học đã chọn: ${sourcesList} — TUYỆT ĐỐI không sinh câu thuộc loại khác các loại này. CHỈ dùng nội dung ĐÚNG trình độ ${p.jlptLevel} theo chuẩn JLPT chính thức, không dùng từ/mẫu ngữ pháp cao hơn trình độ này.
- Mỗi câu có ĐÚNG 4 lựa chọn (options), chỉ 1 đáp án đúng duy nhất, 3 đáp án còn lại phải là nhiễu HỢP LÝ (cùng loại từ/cùng phạm trù ngữ pháp), không trùng lặp nội dung với đáp án đúng hoặc với nhau.
- correct_index phải khớp CHÍNH XÁC vị trí đáp án đúng trong mảng options (đếm từ 0).
- display_jp là nội dung tiếng Nhật chính (từ/kanji/câu có chỗ trống ___), prompt_vi là hướng dẫn ngắn gọn bằng tiếng Việt.
- Không lặp lại cùng 1 từ/mẫu ngữ pháp quá 1 lần trong cùng đề.
- Luôn phản hồi đúng theo cấu trúc JSON được yêu cầu, không kèm văn bản thừa.`;
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
      max_tokens: 2048,
      system: systemPrompt,
      messages: [{ role: "user", content: "Hãy soạn đề theo đúng quy tắc ở trên." }],
      tools: [{
        name: "mini_test_response",
        description: "Đề Mini Test trắc nghiệm JLPT gồm nhiều câu hỏi.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "mini_test_response" },
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
        contents: [{ role: "user", parts: [{ text: "Hãy soạn đề theo đúng quy tắc ở trên." }] }],
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

/// Kiểm tra lại cấu trúc AI trả về TRƯỚC khi gửi cho client — nội dung do AI
/// sinh có thể sai định dạng (thiếu option, correct_index ngoài phạm vi...),
/// không tin tưởng mù quáng dù đã ép JSON schema (schema chỉ ép KIỂU dữ
/// liệu, không ép logic đúng/sai của từng giá trị).
function validateQuestions(
  result: Record<string, unknown>,
  expectedCount: number,
  allowedSources: readonly string[],
): void {
  const questions = result.questions;
  if (!Array.isArray(questions) || questions.length === 0) {
    throw new Error("AI trả về danh sách câu hỏi rỗng hoặc sai định dạng");
  }
  if (questions.length > expectedCount) {
    throw new Error("AI trả về nhiều câu hỏi hơn yêu cầu");
  }
  for (const q of questions) {
    if (q === null || typeof q !== "object") {
      throw new Error("AI trả về 1 câu hỏi sai định dạng");
    }
    const item = q as Record<string, unknown>;
    if (!allowedSources.includes(item.source_type as string)) {
      throw new Error("AI trả về source_type ngoài phạm vi đã chọn");
    }
    if (typeof item.prompt_vi !== "string" || item.prompt_vi.trim().length === 0) {
      throw new Error("AI trả về prompt_vi không hợp lệ");
    }
    if (typeof item.display_jp !== "string" || item.display_jp.trim().length === 0) {
      throw new Error("AI trả về display_jp không hợp lệ");
    }
    if (
      !Array.isArray(item.options) ||
      item.options.length !== 4 ||
      item.options.some((o) => typeof o !== "string" || o.trim().length === 0)
    ) {
      throw new Error("AI trả về options không hợp lệ (cần đúng 4 lựa chọn)");
    }
    if (
      typeof item.correct_index !== "number" ||
      !Number.isInteger(item.correct_index) ||
      item.correct_index < 0 ||
      item.correct_index > 3
    ) {
      throw new Error("AI trả về correct_index không hợp lệ");
    }
  }
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
    const jlptLevel = requireEnum(body.jlptLevel, "jlptLevel", JLPT_LEVELS);

    const questionCountRaw = body.questionCount;
    if (
      typeof questionCountRaw !== "number" ||
      !Number.isInteger(questionCountRaw) ||
      questionCountRaw < 1 ||
      questionCountRaw > 20
    ) {
      throw new AiGuardError(
        "Trường questionCount phải là số nguyên 1-20.",
        400,
        "INVALID_REQUEST",
        { field: "questionCount" },
      );
    }
    const questionCount = questionCountRaw;

    if (
      !Array.isArray(body.sources) ||
      body.sources.length === 0 ||
      body.sources.length > SOURCE_TYPES.length ||
      body.sources.some((s) => !SOURCE_TYPES.includes(s as typeof SOURCE_TYPES[number]))
    ) {
      throw new AiGuardError(
        `Trường sources phải là mảng khác rỗng gồm các giá trị: ${SOURCE_TYPES.join(", ")}.`,
        400,
        "INVALID_REQUEST",
        { field: "sources" },
      );
    }
    const sources = [...new Set(body.sources as string[])];

    if (!Array.isArray(body.mistakes) || body.mistakes.length > MAX_MISTAKES_SENT) {
      throw new AiGuardError(
        `Trường mistakes phải là mảng tối đa ${MAX_MISTAKES_SENT} phần tử.`,
        400,
        "INVALID_REQUEST",
        { field: "mistakes" },
      );
    }
    const mistakes: MistakeContext[] = body.mistakes.map((item, index) => {
      const value = requireObject(item, `mistakes[${index}]`);
      const occurrenceRaw = value.occurrenceCount;
      return {
        sourceType: requireString(value.sourceType, `mistakes[${index}].sourceType`, 32),
        correctAnswer: requireString(value.correctAnswer, `mistakes[${index}].correctAnswer`, 300),
        explanation: typeof value.explanation === "string" && value.explanation.trim().length > 0
          ? requireString(value.explanation, `mistakes[${index}].explanation`, 500)
          : null,
        occurrenceCount: typeof occurrenceRaw === "number" && Number.isFinite(occurrenceRaw)
          ? Math.max(0, Math.trunc(occurrenceRaw))
          : 0,
      };
    });

    const quota = await enforceAiQuota(supabase, "mini_test_ai");

    const systemPrompt = buildSystemPrompt({ jlptLevel, questionCount, mistakes, sources });

    let result: Record<string, unknown> | null = null;
    let provider = "gemini";
    let modelUsed = GEMINI_MODEL;
    let usage: TokenUsage = { inputTokens: 0, outputTokens: 0 };
    let geminiErr: unknown = null;

    if (GOOGLE_AI_API_KEY) {
      try {
        const r = await callGemini(systemPrompt);
        validateQuestions(r.result, questionCount, sources);
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
        validateQuestions(r.result, questionCount, sources);
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
      feature: "mini_test_ai",
      provider,
      model: modelUsed,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
    });

    return jsonResponse({ ...result, _quota: quota }, 200);
  } catch (e) {
    if (e instanceof AiGuardError) {
      return jsonResponse(guardErrorBody(e), e.status);
    }
    console.error(e);
    return jsonResponse({ error: "Lỗi không xác định." }, 500);
  }
});
