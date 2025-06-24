import 'package:flutter/material.dart';
import '../services/voice_note_service.dart';
import '../theme/app_theme.dart';

class VoiceNoteWidget extends StatefulWidget {
  final String? voiceNotePath;
  final Duration? voiceNoteDuration;
  final Function(String? path, Duration? duration)? onVoiceNoteChanged;
  final bool isRecordingMode;

  const VoiceNoteWidget({
    super.key,
    this.voiceNotePath,
    this.voiceNoteDuration,
    this.onVoiceNoteChanged,
    this.isRecordingMode = false,
  });

  @override
  State<VoiceNoteWidget> createState() => _VoiceNoteWidgetState();
}

class _VoiceNoteWidgetState extends State<VoiceNoteWidget>
    with TickerProviderStateMixin {
  final VoiceNoteService _voiceService = VoiceNoteService();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;
  String? _currentVoiceNotePath;
  Duration? _currentDuration;

  late AnimationController _recordingController;
  late AnimationController _playingController;
  late Animation<double> _recordingAnimation;
  late Animation<double> _playingAnimation;

  @override
  void initState() {
    super.initState();
    _currentVoiceNotePath = widget.voiceNotePath;
    _currentDuration = widget.voiceNoteDuration;

    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _playingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _recordingAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _recordingController, curve: Curves.easeInOut),
    );

    _playingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playingController, curve: Curves.easeInOut),
    );

    _initializeService();
  }

  @override
  void dispose() {
    _recordingController.dispose();
    _playingController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    final hasPermission = await _voiceService.initialize();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }

    final started = await _voiceService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _currentVoiceNotePath = null;
        _currentDuration = null;
      });
      _recordingController.repeat(reverse: true);
    } else {
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    final filePath = await _voiceService.stopRecording();
    _recordingController.stop();

    if (filePath != null) {
      final duration = await _voiceService.getVoiceNoteDuration(filePath);
      setState(() {
        _isRecording = false;
        _currentVoiceNotePath = filePath;
        _currentDuration = duration;
      });

      widget.onVoiceNoteChanged?.call(filePath, duration);
    } else {
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar('Failed to save recording');
    }
  }

  Future<void> _playVoiceNote() async {
    if (_currentVoiceNotePath == null) return;

    final played = await _voiceService.playVoiceNote(_currentVoiceNotePath!);
    if (played) {
      setState(() {
        _isPlaying = true;
      });
      _playingController.forward();

      // Listen for playback completion
      Future.delayed(_currentDuration ?? const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
          _playingController.reverse();
        }
      });
    } else {
      _showErrorSnackBar('Failed to play voice note');
    }
  }

  Future<void> _stopPlayback() async {
    await _voiceService.stopPlayback();
    setState(() {
      _isPlaying = false;
    });
    _playingController.reverse();
  }

  Future<void> _deleteVoiceNote() async {
    if (_currentVoiceNotePath != null) {
      await _voiceService.deleteVoiceNote(_currentVoiceNotePath!);
    }

    setState(() {
      _currentVoiceNotePath = null;
      _currentDuration = null;
    });

    widget.onVoiceNoteChanged?.call(null, null);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'This app needs microphone permission to record voice notes. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecordingMode && _currentVoiceNotePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.lightPink, AppTheme.mediumPink.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.softPink, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Voice Note',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_currentVoiceNotePath != null && widget.isRecordingMode)
                IconButton(
                  onPressed: _deleteVoiceNote,
                  icon: const Icon(Icons.delete),
                  color: AppTheme.errorColor,
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_currentVoiceNotePath != null) ...[
            // Voice note player
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isPlaying ? _stopPlayback : _playVoiceNote,
                    child: AnimatedBuilder(
                      animation: _playingAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: _isPlaying
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(20, (index) {
                              return Container(
                                width: 3,
                                height: (index % 4 + 1) * 8.0,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _isPlaying
                                      ? AppTheme.primaryColor
                                      : AppTheme.softPink,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentDuration != null
                              ? _formatDuration(_currentDuration!)
                              : '0:00',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.isRecordingMode) ...[
            // Recording interface
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: AnimatedBuilder(
                      animation: _recordingAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _recordingAnimation.value : 1.0,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_isRecording
                                              ? AppTheme.errorColor
                                              : AppTheme.primaryColor)
                                          .withOpacity(0.3),
                                  blurRadius: _isRecording ? 12 : 6,
                                  spreadRadius: _isRecording ? 4 : 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording
                        ? 'Tap to stop recording'
                        : 'Tap to start recording',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
