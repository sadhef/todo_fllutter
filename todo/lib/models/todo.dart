class Todo {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? dueDate;
  String priority; // 'low', 'medium', 'high'
  String? voiceNotePath; // Path to voice note file
  Duration? voiceNoteDuration; // Duration of voice note

  // NEW: Custom reminder times before due date
  List<Duration>?
      customReminderTimes; // e.g., [Duration(hours: 2), Duration(minutes: 30)]
  bool
      enableDefaultReminders; // Whether to use default 24h, 2h, 15min reminders

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.priority = 'medium',
    this.voiceNotePath,
    this.voiceNoteDuration,
    this.customReminderTimes,
    this.enableDefaultReminders =
        true, // Default to true for backward compatibility
  });

  // Convert Todo to Map (similar to MongoDB document)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'voiceNotePath': voiceNotePath,
      'voiceNoteDuration': voiceNoteDuration?.inMilliseconds,
      'customReminderTimes':
          customReminderTimes?.map((d) => d.inMilliseconds).toList(),
      'enableDefaultReminders': enableDefaultReminders,
    };
  }

  // Convert Todo to JSON Map for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'voiceNotePath': voiceNotePath,
      'voiceNoteDuration': voiceNoteDuration?.inMilliseconds,
      'customReminderTimes':
          customReminderTimes?.map((d) => d.inMilliseconds).toList(),
      'enableDefaultReminders': enableDefaultReminders,
    };
  }

  // Create Todo from Map (similar to Mongoose model)
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      priority: map['priority'] ?? 'medium',
      voiceNotePath: map['voiceNotePath'],
      voiceNoteDuration: map['voiceNoteDuration'] != null
          ? Duration(milliseconds: map['voiceNoteDuration'])
          : null,
      customReminderTimes: map['customReminderTimes'] != null
          ? (map['customReminderTimes'] as List)
              .map((ms) => Duration(milliseconds: ms))
              .toList()
          : null,
      enableDefaultReminders: map['enableDefaultReminders'] ?? true,
    );
  }

  // Create Todo from JSON Map for SharedPreferences storage
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'] ?? 'medium',
      voiceNotePath: json['voiceNotePath'],
      voiceNoteDuration: json['voiceNoteDuration'] != null
          ? Duration(milliseconds: json['voiceNoteDuration'])
          : null,
      customReminderTimes: json['customReminderTimes'] != null
          ? (json['customReminderTimes'] as List)
              .map((ms) => Duration(milliseconds: ms))
              .toList()
          : null,
      enableDefaultReminders: json['enableDefaultReminders'] ?? true,
    );
  }

  // Create a copy with updated fields (similar to spread operator in JS)
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    String? priority,
    String? voiceNotePath,
    Duration? voiceNoteDuration,
    List<Duration>? customReminderTimes,
    bool? enableDefaultReminders,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      voiceNoteDuration: voiceNoteDuration ?? this.voiceNoteDuration,
      customReminderTimes: customReminderTimes ?? this.customReminderTimes,
      enableDefaultReminders:
          enableDefaultReminders ?? this.enableDefaultReminders,
    );
  }

  // Helper method to get effective reminder times
  List<Duration> getEffectiveReminderTimes() {
    if (customReminderTimes != null && customReminderTimes!.isNotEmpty) {
      return customReminderTimes!;
    } else if (enableDefaultReminders) {
      return [
        Duration(hours: 24), // 1 day before
        Duration(hours: 2), // 2 hours before
        Duration(minutes: 15), // 15 minutes before
      ];
    } else {
      return [];
    }
  }

  // Check if todo has voice note
  bool get hasVoiceNote => voiceNotePath != null && voiceNotePath!.isNotEmpty;

  // Check if todo has custom reminders
  bool get hasCustomReminders =>
      customReminderTimes != null && customReminderTimes!.isNotEmpty;

  // Get formatted voice note duration
  String get formattedVoiceNoteDuration {
    if (voiceNoteDuration == null) return '';
    final minutes = voiceNoteDuration!.inMinutes;
    final seconds = voiceNoteDuration!.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  // Format reminder times for display
  String get formattedReminderTimes {
    final times = getEffectiveReminderTimes();
    if (times.isEmpty) return 'No reminders';

    return times.map((duration) {
          if (duration.inDays > 0) {
            return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
          } else if (duration.inHours > 0) {
            return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
          } else {
            return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
          }
        }).join(', ') +
        ' before due date';
  }

  @override
  String toString() {
    return 'Todo{id: $id, title: $title, isCompleted: $isCompleted, hasVoiceNote: $hasVoiceNote, hasCustomReminders: $hasCustomReminders}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
