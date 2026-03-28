import 'dart:async';

import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class InMemoryToDoRepository implements ToDoRepository {
  final List<TaskEntity> _tasks = [];
  final StreamController<List<TaskEntity>> _updates =
      StreamController<List<TaskEntity>>.broadcast();

  List<TaskEntity> _snapshot() =>
      List<TaskEntity>.unmodifiable(List<TaskEntity>.from(_tasks));

  void _emit() {
    if (!_updates.isClosed) {
      _updates.add(_snapshot());
    }
  }

  @override
  Future<List<TaskEntity>> getTasks() async => _snapshot();

  @override
  Stream<List<TaskEntity>> watchTasks() {
    return Stream<List<TaskEntity>>.multi((controller) {
      controller.add(_snapshot());
      final sub = _updates.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    _tasks.add(task);
    _emit();
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      _tasks[i] = task;
      _emit();
    }
  }
}
