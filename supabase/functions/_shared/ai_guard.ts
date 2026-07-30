import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export class AiGuardError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code: string,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
  }
}

interface QuotaResult {
  allowed: boolean;
  code?: string;
  limit?: number;
  used?: number;
  retry_after?: string;
  minute_limit?: number;
  minute_used?: number;
  daily_limit?: number;
  daily_used?: number;
}

export interface ChatMessage {
  role: "user" | "ai";
  content: string;
}

export async function readJsonBody(
  req: Request,
  maxBytes = 128 * 1024,
): Promise<Record<string, unknown>> {
  const contentType = req.headers.get("content-type")?.toLowerCase() ?? "";
  if (!contentType.includes("application/json")) {
    throw new AiGuardError(
      "Content-Type phải là application/json.",
      415,
      "UNSUPPORTED_CONTENT_TYPE",
    );
  }

  const declaredLength = Number(req.headers.get("content-length"));
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw new AiGuardError(
      "Dữ liệu gửi lên quá lớn.",
      413,
      "REQUEST_TOO_LARGE",
      { maxBytes },
    );
  }

  const chunks: Uint8Array[] = [];
  let receivedBytes = 0;
  const reader = req.body?.getReader();
  if (reader) {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      receivedBytes += value.byteLength;
      if (receivedBytes > maxBytes) {
        await reader.cancel();
        throw new AiGuardError(
          "Dữ liệu gửi lên quá lớn.",
          413,
          "REQUEST_TOO_LARGE",
          { maxBytes },
        );
      }
      chunks.push(value);
    }
  }

  const rawBytes = new Uint8Array(receivedBytes);
  let offset = 0;
  for (const chunk of chunks) {
    rawBytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  let raw: string;
  try {
    raw = new TextDecoder("utf-8", { fatal: true }).decode(rawBytes);
  } catch {
    throw new AiGuardError("Body không phải UTF-8 hợp lệ.", 400, "INVALID_JSON");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new AiGuardError("JSON không hợp lệ.", 400, "INVALID_JSON");
  }

  return requireObject(parsed, "body");
}

export function requireObject(
  value: unknown,
  field: string,
): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw invalidField(field, "phải là object");
  }
  return value as Record<string, unknown>;
}

export function requireString(
  value: unknown,
  field: string,
  maxLength: number,
  options: { allowEmpty?: boolean } = {},
): string {
  if (typeof value !== "string") {
    throw invalidField(field, "phải là chuỗi");
  }
  const result = value.trim();
  if (!options.allowEmpty && result.length === 0) {
    throw invalidField(field, "không được để trống");
  }
  if (result.length > maxLength) {
    throw invalidField(field, `không được vượt quá ${maxLength} ký tự`);
  }
  return result;
}

export function optionalString(
  value: unknown,
  field: string,
  maxLength: number,
): string | null {
  if (value === null || value === undefined) return null;
  return requireString(value, field, maxLength, { allowEmpty: true });
}

export function requireEnum<T extends string>(
  value: unknown,
  field: string,
  allowed: readonly T[],
): T {
  const result = requireString(value, field, 64);
  if (!allowed.includes(result as T)) {
    throw invalidField(field, `chỉ chấp nhận: ${allowed.join(", ")}`);
  }
  return result as T;
}

export function validateStringArray(
  value: unknown,
  field: string,
  maxItems: number,
  maxItemLength: number,
): string[] {
  if (!Array.isArray(value)) throw invalidField(field, "phải là mảng");
  if (value.length > maxItems) {
    throw invalidField(field, `không được vượt quá ${maxItems} phần tử`);
  }
  return value.map((item, index) =>
    requireString(item, `${field}[${index}]`, maxItemLength)
  );
}

export function validateHistory(
  value: unknown,
  options: { maxTurns?: number; maxContentLength?: number } = {},
): ChatMessage[] {
  if (value === null || value === undefined) return [];
  if (!Array.isArray(value)) throw invalidField("history", "phải là mảng");

  const maxTurns = options.maxTurns ?? 20;
  const maxContentLength = options.maxContentLength ?? 1000;
  if (value.length > maxTurns) {
    throw invalidField("history", `không được vượt quá ${maxTurns} lượt`);
  }

  return value.map((item, index) => {
    const turn = requireObject(item, `history[${index}]`);
    return {
      role: requireEnum(turn.role, `history[${index}].role`, ["user", "ai"]),
      content: requireString(
        turn.content,
        `history[${index}].content`,
        maxContentLength,
      ),
    };
  });
}

export async function enforceAiQuota(
  supabase: SupabaseClient,
  feature: string,
): Promise<QuotaResult> {
  const { data, error } = await supabase.rpc("consume_ai_quota", {
    p_feature: feature,
  });

  if (error) {
    console.error("AI quota RPC failed:", error.message ?? error);
    throw new AiGuardError(
      "Không kiểm tra được hạn mức AI.",
      503,
      "AI_QUOTA_UNAVAILABLE",
    );
  }

  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    throw new AiGuardError(
      "Phản hồi hạn mức AI không hợp lệ.",
      503,
      "AI_QUOTA_UNAVAILABLE",
    );
  }
  const result = data as QuotaResult;
  if (!result.allowed) {
    const daily = result.code === "AI_DAILY_QUOTA_EXCEEDED";
    throw new AiGuardError(
      daily
        ? "Bạn đã dùng hết lượt AI hôm nay."
        : "Bạn thao tác quá nhanh, vui lòng thử lại sau.",
      429,
      result.code ?? "AI_QUOTA_EXCEEDED",
      {
        limit: result.limit,
        used: result.used,
        retryAfter: result.retry_after,
      },
    );
  }

  return result;
}

export function guardErrorBody(error: AiGuardError): Record<string, unknown> {
  return {
    error: error.message,
    code: error.code,
    ...error.details,
  };
}

function invalidField(field: string, reason: string): AiGuardError {
  return new AiGuardError(
    `Trường ${field} ${reason}.`,
    400,
    "INVALID_REQUEST",
    { field },
  );
}
