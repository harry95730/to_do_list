import 'package:to_do_list/features/domain/entities/task_entity.dart';

abstract class ToDoRepository {
  Future<List<TaskEntity>> getTasks();
  Stream<List<TaskEntity>> watchTasks();
  Future<void> addTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String taskId);

  Future<void> reorderActiveTasks(List<String> orderedIds);

  Future<void> reorderDependencyTasks(List<String> orderedIds);
}
