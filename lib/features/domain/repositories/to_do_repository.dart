import 'package:to_do_list/features/domain/entities/task_entity.dart';

abstract class ToDoRepository {
  Future<List<TaskEntity>> getTasks();
  Stream<List<TaskEntity>> watchTasks();
  Future<void> addTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
}
