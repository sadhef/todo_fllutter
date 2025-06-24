import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class VoiceNoteService {
  static final VoiceNoteService _instance = VoiceNoteService._internal();
  factory VoiceNoteService() => _instance;
  VoiceNoteService._internal();

  final RecorderController _recorderController = RecorderController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  RecorderController get recorderController => _recorderController;

  // Initialize service and request permissions
  Future<bool> initialize() async {
    try {
      final microphonePermission = await Permission.microphone.request();
      return microphonePermission == PermissionStatus.granted;
    } catch (e) {
      print('Error initializing voice note service: $e');
      return false;
    }
  }

  // Start recording voice note
  Future<bool> startRecording() async {
    try {
      if (_isRecording) return false;

      final hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) return false;

      final directory = await getApplicationDocumentsDirectory();
      final voiceNotesDir = Directory('${directory.path}/voice_notes');
      if (!await voiceNotesDir.exists()) {
        await voiceNotesDir.create(recursive: true);
      }

      final fileName =
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path.join(voiceNotesDir.path, fileName);

      await _recorderController.record(path: _currentRecordingPath!);
      _isRecording = true;

      return true;
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final filePath = await _recorderController.stop();
      _isRecording = false;

      if (filePath != null && await File(filePath).exists()) {
        return filePath;
      }

      return _currentRecordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Play voice note
  Future<bool> playVoiceNote(String filePath) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      if (!await File(filePath).exists()) {
        return false;
      }

      await _audioPlayer.play(DeviceFileSource(filePath));
      _isPlaying = true;

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      return true;
    } catch (e) {
      print('Error playing voice note: $e');
      _isPlaying = false;
      return false;
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  // Get voice note duration
  Future<Duration?> getVoiceNoteDuration(String filePath) async {
    try {
      if (!await File(filePath).exists()) return null;

      final tempPlayer = AudioPlayer();
      await tempPlayer.setSource(DeviceFileSource(filePath));
      final duration = await tempPlayer.getDuration();
      await tempPlayer.dispose();

      return duration;
    } catch (e) {
      print('Error getting voice note duration: $e');
      return null;
    }
  }

  // Delete voice note file
  Future<bool> deleteVoiceNote(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting voice note: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _recorderController.dispose();
    _audioPlayer.dispose();
  }
}
