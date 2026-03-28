import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class DeleteTask {
  final ToDoRepository _repository;

  DeleteTask(this._repository);

  Future<void> call(String taskId) {
    return _repository.deleteTask(taskId);
  }
}
