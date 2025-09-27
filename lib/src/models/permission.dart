/// Represents a permission that an app can request
enum PermissionLevel {
  /// Normal permissions that don't require special access
  normal,
  
  /// Administrator permissions that can modify sensitive settings
  administrator,
}

/// Represents a specific permission
class Permission {
  /// The name of the permission
  final String name;
  
  /// The level of the permission
  final PermissionLevel level;
  
  /// Human-readable description of the permission
  final String description;
  
  Permission({
    required this.name,
    required this.level,
    required this.description,
  });

  /// Create Permission from JSON
  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      name: json['name'] ?? '',
      level: PermissionLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
        orElse: () => PermissionLevel.normal,
      ),
      description: json['description'] ?? '',
    );
  }

  /// Convert Permission to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level.toString(),
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Permission && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}