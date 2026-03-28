import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Task list shows Orchestrate and tab labels', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = await PersistingToDoRepository.create();

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => TaskListBloc(
          watchTasks: WatchTask(repository),
          addTask: AddTask(repository),
          updateTask: UpdateTask(repository),
          deleteTask: DeleteTask(repository),
          reorderActive: ReorderActiveTasks(repository),
          reorderDependencies: ReorderDependencyTasks(repository),
        )..add(WatchTasksStarted()),
        child: MaterialApp(
          theme: OrchestrateTheme.light,
          home: const TaskListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('All ('), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
