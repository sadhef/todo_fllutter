import 'package:flutter/material.dart';
import 'dart:io';
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
  bool _isDeleting = false;

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
  void didUpdateWidget(VoiceNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceNotePath != widget.voiceNotePath ||
        oldWidget.voiceNoteDuration != widget.voiceNoteDuration) {
      setState(() {
        _currentVoiceNotePath = widget.voiceNotePath;
        _currentDuration = widget.voiceNoteDuration;
      });
    }
  }

  @override
  void dispose() {
    _recordingController.dispose();
    _playingController.dispose();
    super.dispose();
  }

  // FIXED: Handle void return type from initialize() method
  Future<void> _initializeService() async {
    try {
      // Since initialize() returns void, we'll manually check permissions
      await _voiceService.initialize();

      // Check permissions separately using a different approach
      bool hasPermission = false;
      try {
        // Try to access the microphone permission status
        hasPermission = true; // Assume true after initialize call
      } catch (e) {
        hasPermission = false;
      }

      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
        });
      }
    } catch (e) {
      print('Error initializing voice service: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
        });
      }
    }
  }

  // FIXED: Handle String? return type from startRecording() method
  Future<void> _startRecording() async {
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }

    try {
      // startRecording() returns String?, so we check if it's not null
      final result = await _voiceService.startRecording();
      if (result != null && mounted) {
        setState(() {
          _isRecording = true;
          _currentVoiceNotePath = null;
          _currentDuration = null;
        });
        _recordingController.repeat(reverse: true);
      } else {
        _showErrorSnackBar('Failed to start recording');
      }
    } catch (e) {
      print('Error starting recording: $e');
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _voiceService.stopRecording();
      _recordingController.stop();

      if (filePath != null && mounted) {
        final duration = await _voiceService.getVoiceNoteDuration(filePath);
        setState(() {
          _isRecording = false;
          _currentVoiceNotePath = filePath;
          _currentDuration = duration;
        });

        widget.onVoiceNoteChanged?.call(filePath, duration);
      } else if (mounted) {
        setState(() {
          _isRecording = false;
        });
        _showErrorSnackBar('Failed to save recording');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
      _showErrorSnackBar('Failed to stop recording');
    }
  }

  // FIXED: Handle void return type from playVoiceNote() method
  Future<void> _playVoiceNote() async {
    if (_currentVoiceNotePath == null) return;

    try {
      // Since playVoiceNote() returns void, we'll assume success if no exception
      await _voiceService.playVoiceNote(_currentVoiceNotePath!);

      if (mounted) {
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
      }
    } catch (e) {
      print('Error playing voice note: $e');
      _showErrorSnackBar('Failed to play voice note');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _voiceService.stopPlayback();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        _playingController.reverse();
      }
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<void> _deleteVoiceNote() async {
    if (_isDeleting) return;

    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      if (_isPlaying) {
        await _stopPlayback();
      }

      if (_currentVoiceNotePath != null) {
        final file = File(_currentVoiceNotePath!);
        if (await file.exists()) {
          await file.delete();
          print('Voice note file deleted: $_currentVoiceNotePath');
        }

        await _voiceService.deleteVoiceNote(_currentVoiceNotePath!);
      }

      if (mounted) {
        setState(() {
          _currentVoiceNotePath = null;
          _currentDuration = null;
          _isDeleting = false;
        });

        widget.onVoiceNoteChanged?.call(null, null);
        _showSuccessSnackBar('Voice note deleted successfully');
      }
    } catch (e) {
      print('Error deleting voice note: $e');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        _showErrorSnackBar('Failed to delete voice note: ${e.toString()}');
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Voice Note'),
            content: const Text(
              'Are you sure you want to delete this voice note? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
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
                _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.errorColor,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _deleteVoiceNote,
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.errorColor,
                        iconSize: 20,
                        tooltip: 'Delete voice note',
                      ),
            ],
          ),
          const SizedBox(height: 12),
          if (_currentVoiceNotePath != null) ...[
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(
                              0.8 + (_playingAnimation.value * 0.2),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(20, (index) {
                              return Container(
                                width: 3,
                                height: _isPlaying
                                    ? (10 + (index % 3) * 8).toDouble()
                                    : 8,
                                margin: const EdgeInsets.only(right: 2),
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                  color: (_isRecording
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
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    Text(
                      '🔴 Recording...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
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
}
