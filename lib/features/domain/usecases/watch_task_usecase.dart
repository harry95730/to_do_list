import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class WatchTask {
  final ToDoRepository _repository;

  WatchTask(this._repository);

  Stream<List<TaskEntity>> call() {
    return _repository.watchTasks();
  }
}
