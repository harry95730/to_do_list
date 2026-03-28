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
    );
  }
}
