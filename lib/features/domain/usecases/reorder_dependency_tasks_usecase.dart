import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class ReorderDependencyTasks {
  final ToDoRepository _repository;

  ReorderDependencyTasks(this._repository);

  Future<void> call(List<String> orderedIds) {
    return _repository.reorderDependencyTasks(orderedIds);
  }
}
