class JobSourceItem {
  final String id;
  final String name;
  final String? baseUrl;
  final String? description;
  final bool isAvailable;

  const JobSourceItem({
    required this.id,
    required this.name,
    this.baseUrl,
    this.description,
    this.isAvailable = false,
  });

  factory JobSourceItem.fromJson(Map<String, dynamic> json) {
    return JobSourceItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseUrl: json['base_url'] as String?,
      description: json['description'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'base_url': baseUrl,
    'description': description,
    'is_available': isAvailable,
  };
}
