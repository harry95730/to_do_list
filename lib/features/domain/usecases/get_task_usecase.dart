import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class GetTasks {
  final ToDoRepository _repository;

  GetTasks(this._repository);

  Future<List<TaskEntity>> call() {
    return _repository.getTasks();
  }
}
