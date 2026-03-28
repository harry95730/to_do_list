import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class PersistingToDoRepository implements ToDoRepository {
  PersistingToDoRepository._(this._prefs, List<TaskEntity> initial)
    : _tasks = List<TaskEntity>.from(initial);

  final SharedPreferences _prefs;
  static const _key = 'todo_tasks_v1';
  final List<TaskEntity> _tasks;
  final StreamController<List<TaskEntity>> _updates =
      StreamController<List<TaskEntity>>.broadcast();

  static Future<PersistingToDoRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = <TaskEntity>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final e in decoded) {
          list.add(TaskEntity.fromJson(Map<String, dynamic>.from(e as Map)));
        }
      } catch (_) {}
    }
    return PersistingToDoRepository._(prefs, list);
  }

  List<TaskEntity> _sortedCopy() {
    final copy = List<TaskEntity>.from(_tasks);
    copy.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return copy;
  }

  List<TaskEntity> _snapshot() => List<TaskEntity>.unmodifiable(_sortedCopy());

  void _emit() {
    if (!_updates.isClosed) {
      _updates.add(_snapshot());
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  int _nextSortOrder() {
    if (_tasks.isEmpty) return 0;
    return _tasks.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
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
    final withOrder = task.copyWith(
      sortOrder: _nextSortOrder(),
      updatedAt: DateTime.now(),
    );
    _tasks.add(withOrder);
    await _persist();
    _emit();
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      _tasks[i] = task;
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> reorderActiveTasks(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final idx = _tasks.indexWhere((t) => t.id == orderedIds[i]);
      if (idx < 0) continue;
      final t = _tasks[idx];
      if (t.dependencies.isNotEmpty) continue;
      _tasks[idx] = t.copyWith(sortOrder: i, updatedAt: DateTime.now());
    }
    await _persist();
    _emit();
  }

  @override
  Future<void> reorderDependencyTasks(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final idx = _tasks.indexWhere((t) => t.id == orderedIds[i]);
      if (idx < 0) continue;
      final t = _tasks[idx];
      if (t.dependencies.isEmpty) continue;
      _tasks[idx] = t.copyWith(sortOrder: i, updatedAt: DateTime.now());
    }
    await _persist();
    _emit();
  }
}
