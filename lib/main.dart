import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_list/features/data/repositories/persisting_to_do_repository.dart';
import 'package:to_do_list/features/domain/usecases/add_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/delete_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/reorder_active_tasks_usecase.dart';
import 'package:to_do_list/features/domain/usecases/reorder_dependency_tasks_usecase.dart';
import 'package:to_do_list/features/domain/usecases/update_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/watch_task_usecase.dart';
import 'package:to_do_list/features/presentation/bloc/task_bloc.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/screens/task_list_screen.dart';
import 'package:to_do_list/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await PersistingToDoRepository.create();

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final PersistingToDoRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskListBloc(
        watchTasks: WatchTask(repository),
        addTask: AddTask(repository),
        updateTask: UpdateTask(repository),
        deleteTask: DeleteTask(repository),
        reorderActive: ReorderActiveTasks(repository),
        reorderDependencies: ReorderDependencyTasks(repository),
      )..add(WatchTasksStarted()),
      child: MaterialApp(
        title: 'Orchestrate',
        theme: OrchestrateTheme.light,
        home: const TaskListScreen(),
      ),
    );
  }
}
