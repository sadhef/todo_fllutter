import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class VoiceNoteService {
  static final VoiceNoteService _instance = VoiceNoteService._internal();
  factory VoiceNoteService() => _instance;
  VoiceNoteService._internal();

  RecorderController? _recorderController;
  PlayerController? _playerController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _currentRecordingPath;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _recorderController = RecorderController();
      _playerController = PlayerController();

      await _recorderController!.checkPermission();
      _isInitialized = true;

      if (kDebugMode) {
        print('VoiceNoteService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing VoiceNoteService: $e');
      }
    }
  }

  Future<String?> startRecording() async {
    if (!_isInitialized || _isRecording) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/voice_note_$timestamp.m4a';

      await _recorderController!.record(path: filePath);
      _isRecording = true;
      _currentRecordingPath = filePath;

      if (kDebugMode) {
        print('Recording started: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
      return null;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording || _recorderController == null) return null;

    try {
      final path = await _recorderController!.stop();
      _isRecording = false;

      if (kDebugMode) {
        print('Recording stopped: $path');
      }

      return path;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping recording: $e');
      }
      return null;
    }
  }

  Future<void> pauseRecording() async {
    if (!_isRecording || _recorderController == null) return;

    try {
      await _recorderController!.pause();

      if (kDebugMode) {
        print('Recording paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing recording: $e');
      }
    }
  }

  Future<void> resumeRecording() async {
    if (!_isRecording || _recorderController == null) return;

    try {
      await _recorderController!.record();

      if (kDebugMode) {
        print('Recording resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resuming recording: $e');
      }
    }
  }

  Future<void> playVoiceNote(String filePath) async {
    if (!File(filePath).existsSync()) {
      if (kDebugMode) {
        print('Voice note file not found: $filePath');
      }
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
      _isPlaying = true;

      if (kDebugMode) {
        print('Playing voice note: $filePath');
      }

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error playing voice note: $e');
      }
    }
  }

  Future<void> stopPlaying() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;

      if (kDebugMode) {
        print('Stopped playing voice note');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping playback: $e');
      }
    }
  }

  Future<Duration?> getVoiceNoteDuration(String filePath) async {
    if (!File(filePath).existsSync()) return null;

    try {
      final tempPlayer = AudioPlayer();
      await tempPlayer.setSource(DeviceFileSource(filePath));
      final duration = await tempPlayer.getDuration();
      await tempPlayer.dispose();

      if (kDebugMode) {
        print('Voice note duration: $duration');
      }

      return duration;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting voice note duration: $e');
      }
      return null;
    }
  }

  Future<void> deleteVoiceNote(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          print('Voice note deleted: $filePath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting voice note: $e');
      }
    }
  }

  Stream<Duration>? getRecordingStream() {
    return _recorderController?.onRecorderStateChanged.map((state) {
      // RecorderState doesn't have duration property, return current position
      return Duration
          .zero; // You may need to implement this differently based on your needs
    });
  }

  Future<List<double>?> getWaveformData(String filePath) async {
    if (!File(filePath).existsSync()) return null;

    try {
      final playerController = PlayerController();
      await playerController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );

      final waveformData = playerController.waveformData;
      playerController.dispose(); // Remove await since dispose() returns void

      return waveformData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting waveform data: $e');
      }
      return null;
    }
  }

  Future<bool> hasPermission() async {
    if (_recorderController == null) return false;

    try {
      return await _recorderController!.checkPermission();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permission: $e');
      }
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      if (_isPlaying) {
        await stopPlaying();
      }

      _recorderController
          ?.dispose(); // Remove await since dispose() returns void
      _playerController?.dispose(); // Remove await since dispose() returns void
      await _audioPlayer.dispose();

      _isInitialized = false;

      if (kDebugMode) {
        print('VoiceNoteService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing VoiceNoteService: $e');
      }
    }
  }

  // Add the missing stopPlayback method for compatibility
  Future<void> stopPlayback() async {
    await stopPlaying();
  }
}
