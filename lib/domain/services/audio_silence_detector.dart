import 'dart:math' as math;
import 'dart:typed_data';

/// Kết quả phân tích năng lượng audio — dùng để chặn gọi AI (tốn phí) khi
/// bản ghi rõ ràng không có giọng nói, KHÔNG thay thế được việc AI nghe thật
/// (không phân biệt được tiếng ồn/tiếng bíp có năng lượng nhưng không phải
/// giọng nói — case đó vẫn cần Gemini xử lý).
class WavSilenceResult {
  const WavSilenceResult({required this.isSilent, required this.rms});

  final bool isSilent;
  final double rms;
}

/// Đọc PCM 16-bit trong file WAV (`record` package ghi ra định dạng này) và
/// tính RMS (root-mean-square) biên độ, chuẩn hoá về 0..1. Dưới ngưỡng
/// [rmsThreshold] coi là im lặng — mặc định 0.02 (~-34dB), đủ thấp để không
/// chặn nhầm giọng nói khẽ nhưng bắt được im lặng/tiếng ồn nền phòng.
///
/// Không parse được header (file hỏng/quá ngắn) hoặc không phải PCM 16-bit
/// thì trả về `isSilent: false` — thà để AI nghe thật còn hơn chặn nhầm.
WavSilenceResult analyzeWavSilence(Uint8List wavBytes, {double rmsThreshold = 0.02}) {
  const notSilent = WavSilenceResult(isSilent: false, rms: 0);
  if (wavBytes.length < 44) return notSilent;

  final bytes = ByteData.sublistView(wavBytes);
  if (String.fromCharCodes(wavBytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(wavBytes.sublist(8, 12)) != 'WAVE') {
    return notSilent;
  }

  int? bitsPerSample;
  int? dataOffset;
  int? dataLength;
  var offset = 12;
  while (offset + 8 <= wavBytes.length) {
    final chunkId = String.fromCharCodes(wavBytes.sublist(offset, offset + 4));
    final chunkSize = bytes.getUint32(offset + 4, Endian.little);
    final chunkDataStart = offset + 8;
    if (chunkId == 'fmt ' && chunkDataStart + 16 <= wavBytes.length) {
      bitsPerSample = bytes.getUint16(chunkDataStart + 14, Endian.little);
    } else if (chunkId == 'data') {
      dataOffset = chunkDataStart;
      dataLength = chunkSize;
    }
    offset = chunkDataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
  }

  if (bitsPerSample != 16 || dataOffset == null || dataLength == null) return notSilent;

  final end = math.min(dataOffset + dataLength, wavBytes.length);
  var sumSquares = 0.0;
  var sampleCount = 0;
  for (var i = dataOffset; i + 1 < end; i += 2) {
    final sample = bytes.getInt16(i, Endian.little) / 32768.0;
    sumSquares += sample * sample;
    sampleCount++;
  }
  if (sampleCount == 0) return const WavSilenceResult(isSilent: true, rms: 0);

  final rms = math.sqrt(sumSquares / sampleCount);
  return WavSilenceResult(isSilent: rms < rmsThreshold, rms: rms);
}
