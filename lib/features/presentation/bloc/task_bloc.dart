import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/usecases/add_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/reorder_active_tasks_usecase.dart';
import 'package:to_do_list/features/domain/usecases/reorder_dependency_tasks_usecase.dart';
import 'package:to_do_list/features/domain/usecases/update_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/watch_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/delete_task_usecase.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/bloc/task_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final WatchTask _watchTasks;
  final AddTask _addTask;
  final UpdateTask _updateTask;
  final DeleteTask _deleteTask;
  final ReorderActiveTasks _reorderActive;
  final ReorderDependencyTasks _reorderDependencies;
  StreamSubscription<List<TaskEntity>>? _tasksSubscription;

  TaskListBloc({
    required WatchTask watchTasks,
    required AddTask addTask,
    required UpdateTask updateTask,
    required DeleteTask deleteTask,
    required ReorderActiveTasks reorderActive,
    required ReorderDependencyTasks reorderDependencies,
  }) : _watchTasks = watchTasks,
       _addTask = addTask,
       _updateTask = updateTask,
       _deleteTask = deleteTask,
       _reorderActive = reorderActive,
       _reorderDependencies = reorderDependencies,
       super(const TaskListState()) {
    on<WatchTasksStarted>(_onWatchTasksStarted);
    on<_TasksReceived>(_onTasksReceived);
    on<ToggleSection>(_onToggleSection);
    on<CreateTaskRequested>(_onCreateTaskRequested);
    on<UpdateTaskRequested>(_onUpdateTaskRequested);
    on<DeleteTaskRequested>(_onDeleteTaskRequested);
    on<ReorderActiveTasksRequested>(_onReorderActiveTasksRequested);
    on<ReorderDependencyTasksRequested>(_onReorderDependencyTasksRequested);
  }

  Future<void> _onWatchTasksStarted(
    WatchTasksStarted event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: TaskListStatus.loading));
    await _tasksSubscription?.cancel();
    _tasksSubscription = _watchTasks().listen(
      (tasks) => add(_TasksReceived(tasks)),
    );
  }

  void _onTasksReceived(_TasksReceived event, Emitter<TaskListState> emit) {
    emit(state.copyWith(status: TaskListStatus.success, tasks: event.tasks));
  }

  Future<void> _onCreateTaskRequested(
    CreateTaskRequested event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: TaskListStatus.loading));

    try {
      await _addTask(event.task);
      await _maybeSpawnRecurringFollowUp(
        savedTask: event.task,
        previousVersion: null,
      );
      emit(state.copyWith(status: TaskListStatus.success));
    } catch (_) {
      emit(state.copyWith(status: TaskListStatus.failure));
    }
  }

  Future<void> _onUpdateTaskRequested(
    UpdateTaskRequested event,
    Emitter<TaskListState> emit,
  ) async {
    try {
      final matches = state.tasks.where((t) => t.id == event.task.id);
      final TaskEntity? prior = matches.isEmpty ? null : matches.first;
      await _updateTask(event.task);
      await _maybeSpawnRecurringFollowUp(
        savedTask: event.task,
        previousVersion: prior,
      );
    } catch (_) {
      emit(state.copyWith(status: TaskListStatus.failure));
    }
  }

  Future<void> _maybeSpawnRecurringFollowUp({
    required TaskEntity savedTask,
    required TaskEntity? previousVersion,
  }) async {
    final n = savedTask.recurrenceDays;
    if (n == null || n <= 0) return;
    final becameCompleted =
        savedTask.status == 2 &&
        (previousVersion == null || previousVersion.status != 2);
    if (!becameCompleted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDue = today.add(Duration(days: n));

    final followUp = TaskEntity(
      id: '${now.microsecondsSinceEpoch}_${savedTask.id}',
      name: savedTask.name,
      description: savedTask.description,
      dueDate: nextDue,
      priority: savedTask.priority,
      status: 0,
      dependencies: List<String>.from(savedTask.dependencies),
      recurrenceDays: savedTask.recurrenceDays,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: savedTask.createdBy,
    );
    await _addTask(followUp);
  }

  Future<void> _onDeleteTaskRequested(
    DeleteTaskRequested event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: TaskListStatus.loading));

    try {
      await _deleteTask(event.taskId);
      emit(state.copyWith(status: TaskListStatus.success));
    } catch (_) {
      emit(state.copyWith(status: TaskListStatus.failure));
    }
  }

  void _onToggleSection(ToggleSection event, Emitter<TaskListState> emit) {
    final newExpanded = Set<String>.from(state.expandedSections);
    if (newExpanded.contains(event.sectionTitle)) {
      newExpanded.remove(event.sectionTitle);
    } else {
      newExpanded.add(event.sectionTitle);
    }
    emit(state.copyWith(expandedSections: newExpanded));
  }

  Future<void> _onReorderActiveTasksRequested(
    ReorderActiveTasksRequested event,
    Emitter<TaskListState> emit,
  ) async {
    try {
      await _reorderActive(event.orderedIds);
    } catch (_) {
      emit(state.copyWith(status: TaskListStatus.failure));
    }
  }

  Future<void> _onReorderDependencyTasksRequested(
    ReorderDependencyTasksRequested event,
    Emitter<TaskListState> emit,
  ) async {
    try {
      await _reorderDependencies(event.orderedIds);
    } catch (_) {
      emit(state.copyWith(status: TaskListStatus.failure));
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}

class _TasksReceived extends TaskListEvent {
  final List<TaskEntity> tasks;
  const _TasksReceived(this.tasks);

  @override
  List<Object?> get props => [tasks];
}
