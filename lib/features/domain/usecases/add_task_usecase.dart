import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class AddTask {
  final ToDoRepository _repository;

  AddTask(this._repository);

  Future<void> call(TaskEntity task) {
    return _repository.addTask(task);
  }
}
