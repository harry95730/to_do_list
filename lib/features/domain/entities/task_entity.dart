import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime? dueDate;
  final int? priority;
  final int? status;
  final List<String> dependencies;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  /// Display order within the task’s group (active vs dependency). Lower = earlier.
  final int sortOrder;

  const TaskEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.dependencies,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    dueDate,
    priority,
    status,
    dependencies,
    createdAt,
    updatedAt,
    createdBy,
    sortOrder,
  ];

  TaskEntity copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? dueDate,
    int? priority,
    int? status,
    List<String>? dependencies,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? sortOrder,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dependencies: dependencies ?? this.dependencies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority,
    'status': status,
    'dependencies': dependencies,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'createdBy': createdBy,
    'sortOrder': sortOrder,
  };

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      priority: (json['priority'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      dependencies:
          (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
