import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Audio Cue Service for low-latency feedback in Handlebar HUD and Pocket Mode (TWS/Earphones).
/// Generates synthetic low-latency PCM beeps on the fly.
class AudioCueService {
  static final AudioCueService _instance = AudioCueService._internal(AudioPlayer());
  factory AudioCueService() => _instance;
  AudioCueService._internal([AudioPlayer? player]) : _player = player;

  factory AudioCueService.mock() => AudioCueService._internal(null);

  final AudioPlayer? _player;
  bool soundEnabled = true;

  String? _armedPath;
  String? _finishedPath;
  String? _falseStartPath;

  Future<void> init() async {
    if (_player != null) {
      try {
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setVolume(1.0);
      } catch (_) {}
    }

    try {
      final cacheDir = await getTemporaryDirectory();
      final armedFile = File('${cacheDir.path}/racebox_armed.wav');
      await armedFile.writeAsBytes(_generateToneWav(frequencyHz: 880, durationMs: 320));
      _armedPath = armedFile.path;

      final finFile = File('${cacheDir.path}/racebox_finished.wav');
      await finFile.writeAsBytes(_generateDoubleBeepWav(
        frequencyHz: 1200,
        beepDurationMs: 120,
        gapDurationMs: 80,
      ));
      _finishedPath = finFile.path;

      final alertFile = File('${cacheDir.path}/racebox_alert.wav');
      await alertFile.writeAsBytes(_generateToneWav(frequencyHz: 400, durationMs: 400));
      _falseStartPath = alertFile.path;
    } catch (_) {}
  }

  /// FRD SEC-04 State 3: ARMED (1x Long Beep ~ 300ms @ 880Hz A5)
  Future<void> playArmedBeep() async {
    if (!soundEnabled || _player == null) return;
    try {
      HapticFeedback.heavyImpact();
      await _player.stop();
      if (_armedPath != null && await File(_armedPath!).exists()) {
        await _player.play(DeviceFileSource(_armedPath!));
      } else {
        final wavBytes = _generateToneWav(frequencyHz: 880, durationMs: 320);
        await _player.play(BytesSource(wavBytes));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// FRD SEC-04 State 5: FINISHED (2x Beep ~ 120ms each @ 1200Hz D6)
  Future<void> playFinishedBeep() async {
    if (!soundEnabled || _player == null) return;
    try {
      HapticFeedback.vibrate();
      await _player.stop();
      if (_finishedPath != null && await File(_finishedPath!).exists()) {
        await _player.play(DeviceFileSource(_finishedPath!));
      } else {
        final wavBytes = _generateDoubleBeepWav(
          frequencyHz: 1200,
          beepDurationMs: 120,
          gapDurationMs: 80,
        );
        await _player.play(BytesSource(wavBytes));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// FRD SEC-04 State 4: FALSE START (Alert buzz tone @ 400Hz)
  Future<void> playFalseStartAlert() async {
    if (!soundEnabled || _player == null) return;
    try {
      HapticFeedback.heavyImpact();
      await _player.stop();
      if (_falseStartPath != null && await File(_falseStartPath!).exists()) {
        await _player.play(DeviceFileSource(_falseStartPath!));
      } else {
        final wavBytes = _generateToneWav(frequencyHz: 400, durationMs: 400);
        await _player.play(BytesSource(wavBytes));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Generates a single monophonic sine wave 16-bit PCM WAV in memory
  Uint8List _generateToneWav({
    required int frequencyHz,
    required int durationMs,
    int sampleRate = 16000,
  }) {
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final int dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final int fileSize = 44 + dataSize;

    final bytes = ByteData(fileSize);

    // RIFF Header
    _writeString(bytes, 0, 'RIFF');
    bytes.setUint32(4, fileSize - 8, Endian.little);
    _writeString(bytes, 8, 'WAVE');

    // fmt subchunk
    _writeString(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // Subchunk1Size
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // Mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    bytes.setUint16(32, 2, Endian.little); // BlockAlign
    bytes.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    _writeString(bytes, 36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    // PCM Samples with smooth linear fade-in and fade-out envelope to prevent clicks
    final int attackSamples = (sampleRate * 0.01).round(); // 10ms
    final int releaseSamples = (sampleRate * 0.01).round(); // 10ms

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double amplitude = sin(2 * pi * frequencyHz * t);

      // Envelope
      if (i < attackSamples) {
        amplitude *= (i / attackSamples);
      } else if (i > numSamples - releaseSamples) {
        amplitude *= ((numSamples - i) / releaseSamples);
      }

      final int sampleValue = (amplitude * 28000).clamp(-32768, 32767).toInt();
      bytes.setInt16(44 + (i * 2), sampleValue, Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  /// Generates a double-beep PCM WAV pattern
  Uint8List _generateDoubleBeepWav({
    required int frequencyHz,
    required int beepDurationMs,
    required int gapDurationMs,
    int sampleRate = 16000,
  }) {
    final int beepSamples = (sampleRate * (beepDurationMs / 1000.0)).round();
    final int gapSamples = (sampleRate * (gapDurationMs / 1000.0)).round();
    final int totalSamples = (beepSamples * 2) + gapSamples;
    final int dataSize = totalSamples * 2;
    final int fileSize = 44 + dataSize;

    final bytes = ByteData(fileSize);

    // Header
    _writeString(bytes, 0, 'RIFF');
    bytes.setUint32(4, fileSize - 8, Endian.little);
    _writeString(bytes, 8, 'WAVE');
    _writeString(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    _writeString(bytes, 36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    // Write samples
    int offset = 44;
    for (int beep = 0; beep < 2; beep++) {
      for (int i = 0; i < beepSamples; i++) {
        final double t = i / sampleRate;
        final double sample = sin(2 * pi * frequencyHz * t);
        final int val = (sample * 28000).clamp(-32768, 32767).toInt();
        bytes.setInt16(offset, val, Endian.little);
        offset += 2;
      }
      if (beep == 0) {
        for (int i = 0; i < gapSamples; i++) {
          bytes.setInt16(offset, 0, Endian.little);
          offset += 2;
        }
      }
    }

    return bytes.buffer.asUint8List();
  }

  void _writeString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  void dispose() {
    _player?.dispose();
  }
}
