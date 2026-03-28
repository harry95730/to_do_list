import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_list/features/data/repositories/in_memory_to_do_repository.dart';
import 'package:to_do_list/features/domain/usecases/add_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/update_task_usecase.dart';
import 'package:to_do_list/features/domain/usecases/watch_task_usecase.dart';
import 'package:to_do_list/features/presentation/bloc/task_bloc.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/screens/task_list_screen.dart';
import 'package:to_do_list/theme.dart';

void main() {
  testWidgets('Task list shows Orchestrate and tab labels', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryToDoRepository();

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => TaskListBloc(
          watchTasks: WatchTask(repository),
          addTask: AddTask(repository),
          updateTask: UpdateTask(repository),
        )..add(WatchTasksStarted()),
        child: MaterialApp(
          theme: OrchestrateTheme.light,
          home: const TaskListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Orchestrate'), findsOneWidget);
    expect(find.textContaining('All ('), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
