import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/usecases/add_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/update_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/watch_task_usecase.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/bloc/task_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final WatchTask _watchTasks;
  final AddTask _addTask;
  final UpdateTask _updateTask;
  StreamSubscription<List<TaskEntity>>? _tasksSubscription;

  TaskListBloc({
    required WatchTask watchTasks,
    required AddTask addTask,
    required UpdateTask updateTask,
  }) : _watchTasks = watchTasks,
       _addTask = addTask,
       _updateTask = updateTask,
       super(const TaskListState()) {
    on<WatchTasksStarted>(_onWatchTasksStarted);
    on<_TasksReceived>(_onTasksReceived);
    on<ToggleSection>(_onToggleSection);
    on<CreateTaskRequested>(_onCreateTaskRequested);
    on<UpdateTaskRequested>(_onUpdateTaskRequested);
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
      await _updateTask(event.task);
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
