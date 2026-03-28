import 'package:equatable/equatable.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';

abstract class TaskListEvent extends Equatable {
  const TaskListEvent();
  @override
  List<Object?> get props => [];
}

class WatchTasksStarted extends TaskListEvent {}

class ToggleSection extends TaskListEvent {
  final String sectionTitle;
  const ToggleSection(this.sectionTitle);
  @override
  List<Object?> get props => [sectionTitle];
}

class CreateTaskRequested extends TaskListEvent {
  final TaskEntity task;
  const CreateTaskRequested(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTaskRequested extends TaskListEvent {
  final TaskEntity task;
  const UpdateTaskRequested(this.task);

  @override
  List<Object?> get props => [task];
}

class ReorderActiveTasksRequested extends TaskListEvent {
  final List<String> orderedIds;
  const ReorderActiveTasksRequested(this.orderedIds);

  @override
  List<Object?> get props => [orderedIds];
}

class ReorderDependencyTasksRequested extends TaskListEvent {
  final List<String> orderedIds;
  const ReorderDependencyTasksRequested(this.orderedIds);

  @override
  List<Object?> get props => [orderedIds];
}
