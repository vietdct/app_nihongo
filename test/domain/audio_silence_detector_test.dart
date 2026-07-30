import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/audio_silence_detector.dart';

Uint8List _buildWav16(List<int> samples, {int sampleRate = 16000, int numChannels = 1}) {
  final dataLength = samples.length * 2;
  final buffer = ByteData(44 + dataLength);
  void writeAscii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      buffer.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little); // PCM
  buffer.setUint16(22, numChannels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * numChannels * 2, Endian.little);
  buffer.setUint16(32, numChannels * 2, Endian.little);
  buffer.setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  buffer.setUint32(40, dataLength, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    buffer.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return buffer.buffer.asUint8List();
}

void main() {
  group('analyzeWavSilence', () {
    test('true silence (all-zero samples) is flagged silent', () {
      final wav = _buildWav16(List.filled(16000, 0));
      final result = analyzeWavSilence(wav);
      expect(result.isSilent, isTrue);
      expect(result.rms, 0);
    });

    test('loud tone (near full-scale) is not silent', () {
      final samples = List.generate(16000, (i) => i.isEven ? 20000 : -20000);
      final wav = _buildWav16(samples);
      final result = analyzeWavSilence(wav);
      expect(result.isSilent, isFalse);
      expect(result.rms, greaterThan(0.02));
    });

    test('quiet background noise below threshold is flagged silent', () {
      final samples = List.generate(16000, (i) => i.isEven ? 100 : -100);
      final wav = _buildWav16(samples);
      final result = analyzeWavSilence(wav);
      expect(result.isSilent, isTrue);
    });

    test('malformed/too-short bytes fall back to not-silent (honest unknown)', () {
      final result = analyzeWavSilence(Uint8List.fromList([1, 2, 3]));
      expect(result.isSilent, isFalse);
    });

    test('non-RIFF bytes fall back to not-silent', () {
      final bytes = Uint8List(100);
      final result = analyzeWavSilence(bytes);
      expect(result.isSilent, isFalse);
    });
  });
}
