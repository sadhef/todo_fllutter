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
    };
  }

  // ADDED: Convert Todo to JSON Map for SharedPreferences storage
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
    );
  }

  // ADDED: Create Todo from JSON Map for SharedPreferences storage
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
    );
  }

  // Check if todo has voice note
  bool get hasVoiceNote => voiceNotePath != null && voiceNotePath!.isNotEmpty;

  // Get formatted voice note duration
  String get formattedVoiceNoteDuration {
    if (voiceNoteDuration == null) return '';
    final minutes = voiceNoteDuration!.inMinutes;
    final seconds = voiceNoteDuration!.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Todo{id: $id, title: $title, isCompleted: $isCompleted, hasVoiceNote: $hasVoiceNote}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
