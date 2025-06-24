import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../services/voice_note_service.dart';
import '../theme/app_theme.dart';

class VoiceNoteWidget extends StatefulWidget {
  final String? voiceNotePath;
  final Duration? voiceNoteDuration;
  final Function(String path, Duration duration)? onVoiceNoteRecorded;
  final Function(String path, Duration duration)? onVoiceNoteChanged;
  final VoidCallback? onVoiceNoteDeleted;
  final bool isRecordingMode;

  const VoiceNoteWidget({
    super.key,
    this.voiceNotePath,
    this.voiceNoteDuration,
    this.onVoiceNoteRecorded,
    this.onVoiceNoteChanged,
    this.onVoiceNoteDeleted,
    this.isRecordingMode = false,
  });

  @override
  State<VoiceNoteWidget> createState() => _VoiceNoteWidgetState();
}

class _VoiceNoteWidgetState extends State<VoiceNoteWidget> {
  final VoiceNoteService _voiceService = VoiceNoteService();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;

  RecorderController? _recorderController;
  PlayerController? _playerController;

  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _setupControllers();
  }

  Future<void> _initializeService() async {
    await _voiceService.initialize();
    final hasPermission = await _voiceService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  void _setupControllers() {
    _recorderController = RecorderController();
    _playerController = PlayerController();
  }

  @override
  void dispose() {
    _recorderController?.dispose();
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }

    try {
      final path = await _voiceService.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _currentRecordingPath = path;
          _recordingDuration = Duration.zero;
        });

        // Start duration timer
        _startDurationTimer();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _voiceService.stopRecording();
      if (path != null) {
        final duration = await _voiceService.getVoiceNoteDuration(path);
        final finalDuration = duration ?? _recordingDuration;

        // Call both callbacks if they exist
        widget.onVoiceNoteRecorded?.call(path, finalDuration);
        widget.onVoiceNoteChanged?.call(path, finalDuration);
      }

      setState(() {
        _isRecording = false;
        _currentRecordingPath = null;
        _recordingDuration = Duration.zero;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  Future<void> _playVoiceNote() async {
    if (widget.voiceNotePath == null) return;

    try {
      await _voiceService.playVoiceNote(widget.voiceNotePath!);
      setState(() {
        _isPlaying = true;
      });

      // Auto-stop after duration
      if (widget.voiceNoteDuration != null) {
        Future.delayed(widget.voiceNoteDuration!, () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to play voice note: $e');
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _voiceService.stopPlaying();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to stop playing: $e');
    }
  }

  void _deleteVoiceNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Note'),
        content: const Text('Are you sure you want to delete this voice note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (widget.voiceNotePath != null) {
                await _voiceService.deleteVoiceNote(widget.voiceNotePath!);
                widget.onVoiceNoteDeleted?.call();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startDurationTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration =
              _recordingDuration + const Duration(milliseconds: 100);
        });
      }
      return _isRecording;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'This app needs microphone permission to record voice notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _initializeService();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasVoiceNote = widget.voiceNotePath != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.mic,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Note',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const Spacer(),
              if (hasVoiceNote)
                IconButton(
                  onPressed: _deleteVoiceNote,
                  icon: const Icon(Icons.delete, size: 18),
                  color: AppTheme.errorColor,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (hasVoiceNote) ...[
            // Existing voice note controls
            Row(
              children: [
                // Play/Stop button
                IconButton(
                  onPressed: _isPlaying ? _stopPlaying : _playVoiceNote,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  color: AppTheme.primaryColor,
                ),

                const SizedBox(width: 8),

                // Duration
                Text(
                  _formatDuration(widget.voiceNoteDuration ?? Duration.zero),
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(width: 16),

                // Waveform or progress indicator
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.lightPink,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _isPlaying
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.graphic_eq,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Recording controls
            Row(
              children: [
                // Record/Stop button
                IconButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  color: _isRecording
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),

                const SizedBox(width: 8),

                if (_isRecording) ...[
                  // Recording duration
                  Text(
                    _formatDuration(_recordingDuration),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(width: 16),

                  // Recording indicator
                  Expanded(
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recording...',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.errorColor,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Tap to record a voice note',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
