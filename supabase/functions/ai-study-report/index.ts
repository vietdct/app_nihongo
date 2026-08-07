// AI Study Report — Phase 5 để lại của module Hồ sơ (xem doc comment
// ai_insights_screen.dart). Cùng kiến trúc provider với ai-review-coach
// (Gemini primary + Anthropic fallback, quota/token tracking qua
// ai_guard.ts). Sinh 1 bản tóm tắt hiện trạng học tập bằng văn xuôi tiếng
// Việt, CHỈ dựa trên số liệu thật client gửi lên (streak/XP/số mục đã
// thuộc/số mục yếu/lỗi lặp lại) — không có dữ liệu lịch sử theo ngày nên
// không bịa ra khung "tuần này" hay xu hướng theo thời gian.

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

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    report: {
      type: "string",
      description:
        "Báo cáo học tập tiếng Việt, văn xuôi (không markdown/bullet), khoảng 3 đoạn ngắn: (1) tóm tắt hiện trạng dựa đúng số liệu được cung cấp, (2) điểm mạnh/điểm cần cải thiện, (3) gợi ý cụ thể nên làm tiếp theo trong app.",
    },
  },
  required: ["report"],
};

interface MistakeInput {
  sourceType: string;
  correctAnswer: string;
  explanation: string | null;
  occurrenceCount: number;
}

interface StatsInput {
  streakCount: number;
  longestStreakCount: number;
  xp: number;
  knownVocab: number;
  knownKanji: number;
  knownGrammar: number;
  weakVocab: number;
  weakKanji: number;
  weakGrammar: number;
}

function buildSystemPrompt(stats: StatsInput, mistakes: MistakeInput[]): string {
  const sourceLabel: Record<string, string> = {
    vocab: "Từ vựng",
    kanji: "Kanji",
    grammar: "Ngữ pháp",
  };
  const mistakeList = mistakes.length === 0
    ? "(không có lỗi lặp lại nào được ghi nhận)"
    : mistakes.map((m, i) => {
      const label = sourceLabel[m.sourceType] ?? m.sourceType;
      return `${i + 1}. [${label}] "${m.correctAnswer}"${m.explanation ? ` — ${m.explanation}` : ""} — đã sai ${m.occurrenceCount} lần`;
    }).join("\n");

  return `Bạn là AI Study Report của app học tiếng Nhật Nihongo, viết báo cáo hiện trạng học tập ngắn gọn cho người học Việt Nam.

SỐ LIỆU THẬT (NGUỒN DUY NHẤT — không bịa thêm số liệu hay xu hướng theo thời gian ngoài các con số dưới đây, vì hệ thống KHÔNG có lịch sử theo ngày để so sánh "tuần này so với tuần trước"):
- Chuỗi ngày học hiện tại: ${stats.streakCount} ngày (kỷ lục: ${stats.longestStreakCount} ngày)
- Tổng điểm kinh nghiệm (XP): ${stats.xp}
- Số mục đã thuộc: ${stats.knownVocab} từ vựng, ${stats.knownKanji} Kanji, ${stats.knownGrammar} ngữ pháp
- Số mục đang yếu (ease factor thấp, cần ôn lại): ${stats.weakVocab} từ vựng, ${stats.weakKanji} Kanji, ${stats.weakGrammar} ngữ pháp

LỖI LẶP LẠI NHIỀU NHẤT (Sổ tay lỗi):
${mistakeList}

QUY TẮC:
- Trả lời tiếng Việt, văn xuôi tự nhiên, không dùng markdown/bullet/số thứ tự, khoảng 3 đoạn ngắn (mỗi đoạn 2-4 câu).
- Chỉ dựa vào số liệu trên. Không suy diễn "tuần này/tháng này" hay so sánh với quá khứ vì không có dữ liệu đó.
- Nếu hầu hết số liệu bằng 0 (người mới), nói rõ chưa đủ dữ liệu để đánh giá sâu, khuyến khích học vài buổi trước.
- Đoạn cuối gợi ý 1-2 hành động cụ thể trong app (vd. "vào Smart Review ôn phần yếu nhất", "làm Weak Point Mini Test") — không đề xuất tính năng không có thật.
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
      messages: [{ role: "user", content: "Hãy viết báo cáo theo đúng quy tắc ở trên." }],
      tools: [{
        name: "study_report_response",
        description: "Báo cáo học tập của AI Study Report.",
        input_schema: RESPONSE_SCHEMA,
      }],
      tool_choice: { type: "tool", name: "study_report_response" },
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
        contents: [{ role: "user", parts: [{ text: "Hãy viết báo cáo theo đúng quy tắc ở trên." }] }],
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

const MAX_MISTAKES = 5;

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
    return {
      sourceType: requireEnum(m.sourceType, `mistakes[${index}].sourceType`, ["vocab", "kanji", "grammar"]),
      correctAnswer: requireString(m.correctAnswer, `mistakes[${index}].correctAnswer`, 200),
      explanation: optionalString(m.explanation, `mistakes[${index}].explanation`, 1000),
      occurrenceCount,
    };
  });
}

function requireNonNegativeInt(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    throw new AiGuardError(`Trường ${field} phải là số nguyên không âm.`, 400, "INVALID_REQUEST", { field });
  }
  return Math.trunc(value);
}

function parseStats(body: Record<string, unknown>): StatsInput {
  return {
    streakCount: requireNonNegativeInt(body.streakCount, "streakCount"),
    longestStreakCount: requireNonNegativeInt(body.longestStreakCount, "longestStreakCount"),
    xp: requireNonNegativeInt(body.xp, "xp"),
    knownVocab: requireNonNegativeInt(body.knownVocab, "knownVocab"),
    knownKanji: requireNonNegativeInt(body.knownKanji, "knownKanji"),
    knownGrammar: requireNonNegativeInt(body.knownGrammar, "knownGrammar"),
    weakVocab: requireNonNegativeInt(body.weakVocab, "weakVocab"),
    weakKanji: requireNonNegativeInt(body.weakKanji, "weakKanji"),
    weakGrammar: requireNonNegativeInt(body.weakGrammar, "weakGrammar"),
  };
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
    const stats = parseStats(body);
    const mistakes = parseMistakes(body.mistakes);

    await enforceAiQuota(supabase, "study_report");

    const systemPrompt = buildSystemPrompt(stats, mistakes);

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
      feature: "study_report",
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
