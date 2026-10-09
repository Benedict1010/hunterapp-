class Resume {
  final String id;
  final String userId;
  final String filename;
  final String? fileUrl;
  final String? contentText;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Resume({
    required this.id,
    required this.userId,
    required this.filename,
    this.fileUrl,
    this.contentText,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      filename: json['filename'] as String? ?? 'uploaded_resume',
      fileUrl: json['file_url'] as String?,
      contentText: json['content_text'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'filename': filename,
    'file_url': fileUrl,
    'content_text': contentText,
    'is_primary': isPrimary,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Resume copyWith({
    String? id,
    String? userId,
    String? filename,
    String? fileUrl,
    String? contentText,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Resume(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      filename: filename ?? this.filename,
      fileUrl: fileUrl ?? this.fileUrl,
      contentText: contentText ?? this.contentText,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
