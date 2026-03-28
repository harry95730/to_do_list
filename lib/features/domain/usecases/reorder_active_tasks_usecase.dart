import 'package:to_do_list/features/domain/repositories/to_do_repository.dart';

class ReorderActiveTasks {
  final ToDoRepository _repository;

  ReorderActiveTasks(this._repository);

  Future<void> call(List<String> orderedIds) {
    return _repository.reorderActiveTasks(orderedIds);
  }
}
