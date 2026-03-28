import 'package:equatable/equatable.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';

enum TaskListStatus { initial, loading, success, failure }

class TaskListState extends Equatable {
  final TaskListStatus status;
  final List<TaskEntity> tasks;
  final Set<String> expandedSections;

  const TaskListState({
    this.status = TaskListStatus.initial,
    this.tasks = const [],
    this.expandedSections = const {"Active Sequence"},
  });

  TaskListState copyWith({
    TaskListStatus? status,
    List<TaskEntity>? tasks,
    Set<String>? expandedSections,
  }) {
    return TaskListState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      expandedSections: expandedSections ?? this.expandedSections,
    );
  }

  @override
  List<Object?> get props => [status, tasks, expandedSections];
}
