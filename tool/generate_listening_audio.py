#!/usr/bin/env python3
"""Tạo audio hội thoại (mp3) bằng Google Cloud Text-to-Speech cho mọi đoạn
`listening_dialogues` (N5–N1 + IT): mỗi nhân vật 1 giọng thần kinh khác nhau.

Dùng:
  # Cách A — Cloud Text-to-Speech (key dạng AIza..., bật Cloud TTS API):
  export GOOGLE_TTS_API_KEY=...        # key của bạn, KHÔNG commit
  # Cách B — Gemini TTS bằng key Google AI Studio (--provider gemini):
  export GEMINI_API_KEY=...
  python3 tool/generate_listening_audio.py --provider gemini --limit 3  # thử 3 file
  # Câu mẫu Luyện nói (grammar_points.example_jp): thêm --source shadowing
  # Từ vựng + ví dụ theo cấp: --source vocab --level IT (cũng vào thư mục m/)
  # Câu đáp án đầy đủ của bài luyện Ngữ pháp soạn sẵn: --source practice
  python3 tool/generate_listening_audio.py --dry-run   # chỉ đếm số ký tự
  python3 tool/generate_listening_audio.py             # tạo file còn thiếu
  # Upload từng thư mục con (s0/s1/m), KHÔNG upload cả build/listening_audio:
  supabase storage cp -r build/listening_audio/m ss:///listening-audio/ --linked --experimental

Tên file = slot giọng + FNV-1a 64 của nội dung lượt thoại, khớp
`lib/core/services/dialogue_audio.dart` (app tự tìm file theo nội dung).
"""
import base64
import html
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# slot nhân vật (theo thứ tự xuất hiện) → giọng. Nữ / nam / nam trầm.
VOICES = ["ja-JP-Neural2-B", "ja-JP-Neural2-C", "ja-JP-Neural2-D"]
OUT = Path("build/listening_audio")

LATIN = dict(zip("ABCDEFGHIJKLMNOPQRSTUVWXYZ", [
    "エー", "ビー", "シー", "ディー", "イー", "エフ", "ジー", "エイチ", "アイ",
    "ジェー", "ケー", "エル", "エム", "エヌ", "オー", "ピー", "キュー", "アール",
    "エス", "ティー", "ユー", "ブイ", "ダブリュー", "エックス", "ワイ", "ゼット"]))


def fnv1a64_hex(text: str) -> str:
    h = 0xCBF29CE484222325
    for b in text.encode("utf-8"):
        h = ((h ^ b) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return f"{h:016x}"


def prepare(text: str) -> str:
    """Chuẩn hoá chữ để đọc tự nhiên (giống prepareJpForSpeech trong app)."""
    t = html.unescape(text)
    t = re.sub(r"(?<![A-Za-z])([A-Z])(?=さん)", lambda m: LATIN[m[1]], t)
    t = re.sub(r"^[〜～~]+", "", t)
    t = re.sub(r"[〜～~]", "、", t)
    t = re.sub(r"(…+|・{3,}|\.{3,})", "、", t)
    return re.sub(r"\s+", " ", t).strip()


def fetch_dialogues(query="select id, turns from listening_dialogues order by id", key="turns"):
    sql = Path("build/_listening_dialogues.sql")
    sql.parent.mkdir(parents=True, exist_ok=True)
    sql.write_text(query)
    res = subprocess.run(
        ["supabase", "db", "query", "--linked", "-o", "json", "-f", str(sql)],
        capture_output=True, text=True)
    out = res.stdout
    if res.returncode != 0:
        sys.exit("supabase db query lỗi (đã `supabase login` và `supabase link` "
                 f"chưa?):\n{res.stderr.strip()}\n{out.strip()[:500]}")
    rows = _find_rows(out, key)
    if rows is None:
        sys.exit("Không đọc được kết quả từ supabase. 500 ký tự đầu:\n"
                 f"{out[:500]}")
    return rows


def _find_rows(text: str, key: str = "turns"):
    """Tìm đối tượng JSON có khoá `rows` (hoặc `data`) trong đầu ra của CLI,
    chịu được dòng log/cảnh báo đi kèm và khác biệt định dạng giữa các bản CLI."""
    dec = json.JSONDecoder()
    for i, ch in enumerate(text):
        if ch not in "{[":
            continue
        try:
            obj, _ = dec.raw_decode(text[i:])
        except ValueError:
            continue
        found = _dig(obj, key)
        if found is not None:
            return found
    return None


def _dig(obj, key="turns"):
    if isinstance(obj, dict):
        for k in ("rows", "data", "result", "results"):
            v = obj.get(k)
            if isinstance(v, list) and v and isinstance(v[0], dict) and key in v[0]:
                return v
            if v is not None:
                r = _dig(v, key)
                if r is not None:
                    return r
    elif isinstance(obj, list) and obj and isinstance(obj[0], dict) and key in obj[0]:
        return obj
    return None


def synthesize(key: str, text: str, voice: str) -> bytes:
    body = json.dumps({
        "input": {"text": text},
        "voice": {"languageCode": "ja-JP", "name": voice},
        "audioConfig": {"audioEncoding": "MP3", "speakingRate": 1.0},
    }).encode()
    headers = {"Content-Type": "application/json"}
    url = "https://texttospeech.googleapis.com/v1/text:synthesize"
    token = os.environ.get("GOOGLE_TTS_ACCESS_TOKEN")  # gcloud auth print-access-token
    if token:
        headers["Authorization"] = f"Bearer {token}"
        if os.environ.get("GOOGLE_CLOUD_PROJECT"):
            headers["x-goog-user-project"] = os.environ["GOOGLE_CLOUD_PROJECT"]
        key = token
    else:
        url += f"?key={key}"
    req = urllib.request.Request(url, body, headers)
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return base64.b64decode(json.load(r)["audioContent"])
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace").replace(key, "***")
            if attempt < 4 and e.code in (429, 500, 503):
                time.sleep(5 * (attempt + 1))
                continue
            sys.exit(f"Google TTS trả lỗi HTTP {e.code} (voice {voice}):\n{detail[:800]}")
        except (TimeoutError, urllib.error.URLError, ConnectionError):
            if attempt < 4:  # mạng chập chờn: thử lại thay vì sập cả lượt chạy
                time.sleep(5 * (attempt + 1))
                continue
            raise EmptyAudio("timeout/mạng")


class EmptyAudio(Exception):
    """Gemini trả rỗng nhiều lần cho 1 câu — bỏ qua câu đó, đi tiếp."""


# Giọng Gemini TTS theo slot: nữ / nam trầm / nam sáng.
GEMINI_VOICES = ["Kore", "Charon", "Puck"]


def synthesize_gemini(key: str, text: str, voice: str, prefix: bool = True) -> bytes:
    """Gemini TTS → PCM 24kHz 16-bit mono → mp3 (cần ffmpeg)."""
    model = os.environ.get("GEMINI_TTS_MODEL", "gemini-2.5-flash-preview-tts")
    body = json.dumps({
        "contents": [{"parts": [{"text": (
            f"Say the following Japanese text naturally: {text}" if prefix else text)}]}],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {"languageCode": "ja-JP", "voiceConfig": {
                "prebuiltVoiceConfig": {"voiceName": voice}}},
        },
    }).encode()
    url = ("https://generativelanguage.googleapis.com/v1beta/models/"
           f"{model}:generateContent")
    req = urllib.request.Request(
        url, body, {"Content-Type": "application/json", "x-goog-api-key": key})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                data = json.load(r)
            parts = ((data.get("candidates") or [{}])[0]
                     .get("content") or {}).get("parts") or []
            if not parts and attempt < 4:
                time.sleep(3 * (attempt + 1))  # đôi khi Gemini trả rỗng (finishReason OTHER)
                continue
            break
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace").replace(key, "***")
            if e.code == 400 and "languageCode" in detail and b"languageCode" in body:
                body = body.replace(b'"languageCode": "ja-JP", ', b"")
                req = urllib.request.Request(url, body, dict(req.header_items()))
                continue
            if attempt < 4 and (e.code in (429, 500, 503) or
                                (e.code == 400 and "only be used for TTS" in detail)):
                time.sleep(5 * (attempt + 1))
                continue
            sys.exit(f"Gemini TTS lỗi HTTP {e.code} (voice {voice}):\n{detail[:800]}")
        except (TimeoutError, urllib.error.URLError, ConnectionError):
            # Timeout/mạng chập chờn: thử lại thay vì làm sập cả lượt chạy.
            if attempt < 4:
                time.sleep(5 * (attempt + 1))
                continue
            raise EmptyAudio("timeout/mạng")
    try:
        pcm = base64.b64decode(
            data["candidates"][0]["content"]["parts"][0]["inlineData"]["data"])
    except (KeyError, IndexError):
        raise EmptyAudio(str(data)[:300])
    res = subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-f", "s16le", "-ar", "24000", "-ac", "1",
         "-i", "-", "-b:a", "48k", "-f", "mp3", "-"],
        input=pcm, capture_output=True)
    if res.returncode != 0:
        sys.exit(f"ffmpeg lỗi: {res.stderr.decode()[:300]}")
    return res.stdout


def main():
    dry = "--dry-run" in sys.argv
    gemini = "--provider" in sys.argv and \
        sys.argv[sys.argv.index("--provider") + 1] == "gemini"
    limit = int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else None
    env = "GEMINI_API_KEY" if gemini else "GOOGLE_TTS_API_KEY"
    key = os.environ.get(env, "")
    # vocab/--cloud chỉ dùng Cloud TTS → không cần key Gemini
    cloud_only = ("--cloud" in sys.argv or "vocab" in sys.argv) and \
        os.environ.get("GOOGLE_TTS_API_KEY")
    if not dry and not key and not cloud_only:
        sys.exit(f"Thiếu {env} (hoặc dùng --dry-run).")
    voices = GEMINI_VOICES if gemini else VOICES
    jobs = {}  # path -> (voice, text)
    sentences = "--source" in sys.argv and \
        sys.argv[sys.argv.index("--source") + 1] == "shadowing"
    vocab = "--source" in sys.argv and \
        sys.argv[sys.argv.index("--source") + 1] == "vocab"
    if sentences:
        # Luyện nói: câu mẫu = grammar_points.example_jp, 1 giọng (slot 0), thư mục m/
        rows = fetch_dialogues(
            "select distinct example_jp from grammar_points "
            "where example_jp is not null and btrim(example_jp) <> '' "
            "order by example_jp", "example_jp")
        for row in rows:
            jp = row["example_jp"].strip()
            jobs[f"m/{fnv1a64_hex(jp)}.mp3"] = (voices[0], prepare(jp))
    cloud_paths = set()
    if vocab:
        # Từ vựng + câu ví dụ theo cấp (--level IT), vào m/ (cùng đường dẫn với Luyện nói
        # nên JpSpeakButton tự tìm theo nội dung). Toàn bộ dùng Cloud TTS (không lời nhắc
        # → không bị đọc tiếng Anh/rè). Từ đọc theo cột reading để không đọc sai chữ Hán.
        lvl = sys.argv[sys.argv.index("--level") + 1] if "--level" in sys.argv else "IT"
        # --level ALL: mọi cấp (từ liên quan/kanji ở màn IT dùng từ cấp khác)
        cond = "true" if lvl == "ALL" else f"l.code='{lvl}'"
        rows = fetch_dialogues(
            "select * from ("
            "select v.word as t, v.reading as r from vocabulary v join jlpt_levels l on l.id=v.level_id "
            f"where {cond} union all "
            "select m.example_jp, null from vocabulary_meanings m join vocabulary v on v.id=m.vocabulary_id "
            f"join jlpt_levels l on l.id=v.level_id where {cond} "
            "union all select unnest(m.extra_examples_jp), null from vocabulary_meanings m "
            "join vocabulary v on v.id=m.vocabulary_id "
            f"join jlpt_levels l on l.id=v.level_id where {cond}"
            ") x where t is not null and btrim(t) <> '' order by t", "t")
        for row in rows:
            jp = row["t"].strip()
            if not jp:
                continue
            say = (row.get("r") or "").strip()
            if not re.search(r"[\u3040-\u30ff]", say):  # reading rỗng/"—" → đọc chính từ
                say = jp
            path = f"m/{fnv1a64_hex(jp)}.mp3"
            jobs[path] = (voices[0], prepare(say))
            cloud_paths.add(path)
    grammar = "--source" in sys.argv and \
        sys.argv[sys.argv.index("--source") + 1] == "grammar"
    if grammar:
        # Ngữ pháp: tiêu đề mẫu + ví dụ chính/phụ + ví dụ theo nghĩa (--level IT|N5|...|ALL), Cloud TTS.
        lvl = sys.argv[sys.argv.index("--level") + 1] if "--level" in sys.argv else "ALL"
        cond = "true" if lvl == "ALL" else f"l.code='{lvl}'"
        base = "from grammar_points gp join jlpt_levels l on l.id=gp.level_id"
        rows = fetch_dialogues(
            "select t from ("
            f"select gp.title as t {base} where {cond} "
            f"union all select gp.example_jp {base} where {cond} "
            f"union all select unnest(gp.extra_examples_jp) {base} where {cond} "
            "union all select unnest(gm.examples_jp) from grammar_meanings gm "
            "join grammar_points gp on gp.id=gm.grammar_point_id "
            f"join jlpt_levels l on l.id=gp.level_id where {cond}"
            ") x where t is not null and btrim(t) <> '' order by t", "t")
        for row in rows:
            jp = row["t"].strip()
            path = f"m/{fnv1a64_hex(jp)}.mp3"
            jobs[path] = (voices[0], prepare(jp))
            cloud_paths.add(path)
    practice = "--source" in sys.argv and \
        sys.argv[sys.argv.index("--source") + 1] == "practice"
    if practice:
        # Luyện tập Ngữ pháp soạn sẵn (grammar_practice_questions): câu hoàn chỉnh sau khi
        # điền đáp án đúng vào （　　）. App chỉ phát câu này SAU khi người học trả lời.
        rows = fetch_dialogues(
            "select replace(prompt_jp, '（　　）', options->>correct_index) as t "
            "from grammar_practice_questions order by 1", "t")
        for row in rows:
            jp = row["t"].strip()
            path = f"m/{fnv1a64_hex(jp)}.mp3"
            jobs[path] = (voices[0], prepare(jp))
            cloud_paths.add(path)
    kanji = "--source" in sys.argv and \
        sys.argv[sys.argv.index("--source") + 1] == "kanji"
    if kanji:
        # Kanji: app đọc cách đọc đầu tiên (kun, không có thì on, không có thì chính chữ) + câu ví dụ.
        # Tên file theo chuỗi gốc app truyền vào (vd "つ.む"), nội dung đọc bỏ "." và "-".
        rows = fetch_dialogues(
            "select character, onyomi, kunyomi, example_jp from kanji order by character", "character")
        for row in rows:
            kun = [x for x in (row.get("kunyomi") or []) if x and x.strip()]
            on = [x for x in (row.get("onyomi") or []) if x and x.strip()]
            first = (kun[0] if kun else on[0] if on else row["character"]).strip()
            items_k = [(first, re.sub(r"[.\-]", "", first))]
            if (row.get("example_jp") or "").strip():
                ex = row["example_jp"].strip()
                items_k.append((ex, ex))
            for key_text, say in items_k:
                path = f"m/{fnv1a64_hex(key_text)}.mp3"
                jobs[path] = (voices[0], prepare(say))
                cloud_paths.add(path)
    for row in ([] if sentences or vocab or grammar or kanji or practice else fetch_dialogues()):
        turns = row["turns"]
        if isinstance(turns, str):
            turns = json.loads(turns)
        order = []
        for t in turns:
            sp = (t.get("speaker") or "A").strip() or "A"
            jp = (t.get("jp") or "").strip()
            if not jp:
                continue
            if sp not in order:
                order.append(sp)
            slot = order.index(sp) % 3
            jobs[f"s{slot}/{fnv1a64_hex(jp)}.mp3"] = (voices[slot], prepare(jp))
    chars = sum(len(v[1]) for v in jobs.values())
    todo = {p: v for p, v in jobs.items() if not (OUT / p).exists()}
    print(f"{len(jobs)} file, {chars} ký tự; còn thiếu {len(todo)}")
    if dry:
        return
    items = sorted(todo.items())[:limit]
    skipped = []
    use_cloud = "--cloud" in sys.argv  # ép mọi file qua Cloud TTS (không lời nhắc)

    def cloud_voice(path):
        # Hội thoại (s0/s1/s2): GOOGLE_TTS_VOICES="giọng0,giọng1,giọng2"; còn lại GOOGLE_TTS_VOICE.
        lst = [v.strip() for v in os.environ.get("GOOGLE_TTS_VOICES", "").split(",") if v.strip()]
        if path[0] == "s" and lst:
            return lst[int(path[1]) % len(lst)]
        return os.environ.get("GOOGLE_TTS_VOICE", VOICES[0])

    for i, (path, (voice, text)) in enumerate(items, 1):
        f = OUT / path
        f.parent.mkdir(parents=True, exist_ok=True)
        try:
            gkey = os.environ.get("GOOGLE_TTS_API_KEY", "") or \
                os.environ.get("GOOGLE_TTS_ACCESS_TOKEN", "")
            if gemini and (use_cloud or path in cloud_paths or (len(text) <= 8 and not os.environ.get("SHORT_WITH_GEMINI"))):
                # Từ ngắn: Gemini hay đọc sai ngôn ngữ/kèm tiếng rè → dùng Cloud TTS (ép ja-JP).
                if not gkey:
                    skipped.append((path, text))
                    print(f"[{i}/{len(items)}] BỎ QUA (thiếu GOOGLE_TTS_API_KEY) {path}: {text}")
                    continue
                raw = synthesize(gkey, text, cloud_voice(path))
                # Cloud TTS trả MP3 thô không có thẻ ID3 → Supabase Storage từ chối
                # (415 mime octet-stream). Thêm thẻ ID3, không đổi âm thanh.
                res = subprocess.run(
                    ["ffmpeg", "-loglevel", "error", "-f", "mp3", "-i", "-", "-c", "copy",
                     "-write_id3v2", "1", "-id3v2_version", "3", "-f", "mp3", "-"],
                    input=raw, capture_output=True)
                f.write_bytes(res.stdout if res.returncode == 0 and res.stdout else raw)
            else:
                try:
                    # SHORT_WITH_GEMINI=1: từ ngắn cũng dùng Gemini, không kèm lời nhắc tiếng Anh.
                    short = gemini and len(text) <= 8
                    f.write_bytes((synthesize_gemini if gemini else synthesize)(
                        key, text, voice, **({"prefix": False} if short else {})))
                except EmptyAudio:
                    # Câu ngắn/chỉ số đôi khi bị từ chối khi có lời nhắc: thử lại không kèm lời nhắc.
                    f.write_bytes(synthesize_gemini(key, text, voice, prefix=False))
        except EmptyAudio as e:
            skipped.append((path, text))
            print(f"[{i}/{len(items)}] BỎ QUA {path}: {text[:24]} ({e})")
            continue
        print(f"[{i}/{len(items)}] {path} {voice} {text[:24]}")
    if skipped:
        print(f"{len(skipped)} câu bị bỏ qua (chạy lại script để thử lại):")
        for pth, tx in skipped:
            print(f"  {pth} {tx[:40]}")
    print("Xong. Upload từng thư mục con, ví dụ: supabase storage cp -r "
          "build/listening_audio/m ss:///listening-audio/ --linked --experimental")


if __name__ == "__main__":
    main()
