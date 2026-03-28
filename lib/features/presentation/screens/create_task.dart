import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_list/features/data/create_task_draft_storage.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/presentation/bloc/task_bloc.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/bloc/task_state.dart';
import 'package:to_do_list/features/shared_widgets/priority_selection_widget.dart';
import 'package:to_do_list/features/shared_widgets/time_picker_widget.dart';
import 'package:to_do_list/theme.dart';

class CreateTaskScreen extends StatefulWidget {
  final TaskEntity? taskToEdit;
  const CreateTaskScreen({super.key, this.taskToEdit});
  bool get isEditing => taskToEdit != null;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen>
    with WidgetsBindingObserver {
  /// Matches list UI / `PrioritySelector` order: TO-DO, IN-PROGRESS, COMPLETED.
  static const int _kStatusCompleted = 2;

  late int _currentPriorityIndex;
  late int _currentStatusIndex;
  late DateTime _selectedDate;
  late Set<String> _selectedDependencyIds;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _recurrenceController = TextEditingController();

  /// After a successful create, avoid re-persisting form text from [dispose].
  bool _suppressDraftPersistence = false;

  static int _optionIndex(int? value) {
    if (value == null) return 0;
    return value.clamp(0, 2);
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.taskToEdit;
    if (existing != null) {
      _nameController.text = existing.name;
      _descriptionController.text = existing.description;
      _selectedDate = existing.dueDate ?? DateTime.now();
      _currentPriorityIndex = _optionIndex(existing.priority);
      _currentStatusIndex = _optionIndex(existing.status);
      _selectedDependencyIds = Set<String>.from(existing.dependencies);
      final r = existing.recurrenceDays;
      if (r != null && r > 0) {
        _recurrenceController.text = r.toString();
      }
    } else {
      _selectedDate = DateTime.now();
      _currentPriorityIndex = 0;
      _currentStatusIndex = 0;
      _selectedDependencyIds = {};
      WidgetsBinding.instance.addObserver(this);
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraftIfAny());
    }
  }

  CreateTaskDraft _draftSnapshot() {
    final deps = _dependencyListForSubmit();
    return CreateTaskDraft(
      name: _nameController.text,
      description: _descriptionController.text,
      dueMillis: _selectedDate.millisecondsSinceEpoch,
      priorityIndex: _currentPriorityIndex,
      statusIndex: _currentStatusIndex,
      dependencyIds: deps,
      recurrenceText: _recurrenceController.text,
    );
  }

  bool _draftIsMeaningful(CreateTaskDraft d) {
    if (d.name.trim().isNotEmpty || d.description.trim().isNotEmpty) {
      return true;
    }
    if (d.recurrenceText.trim().isNotEmpty) return true;
    if (d.dependencyIds.isNotEmpty) return true;
    if (d.priorityIndex != 0 || d.statusIndex != 0) return true;
    final today = DateTime.now();
    final due = DateTime.fromMillisecondsSinceEpoch(d.dueMillis);
    if (due.year != today.year ||
        due.month != today.month ||
        due.day != today.day) {
      return true;
    }
    return false;
  }

  void _persistDraftOrClear() {
    if (widget.isEditing || _suppressDraftPersistence) return;
    final draft = _draftSnapshot();
    if (_draftIsMeaningful(draft)) {
      unawaited(CreateTaskDraftStorage.save(draft));
    } else {
      unawaited(CreateTaskDraftStorage.clear());
    }
  }

  Future<void> _restoreDraftIfAny() async {
    if (!mounted || widget.isEditing) return;
    final draft = await CreateTaskDraftStorage.load();
    if (!mounted || draft == null || !_draftIsMeaningful(draft)) return;
    final validIds = context.read<TaskListBloc>().state.tasks.map((t) => t.id).toSet();
    final deps = draft.dependencyIds.where(validIds.contains).toSet();
    setState(() {
      _nameController.text = draft.name;
      _descriptionController.text = draft.description;
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(draft.dueMillis);
      _currentPriorityIndex = draft.priorityIndex.clamp(0, 2);
      _currentStatusIndex = draft.statusIndex.clamp(0, 2);
      _selectedDependencyIds = deps;
      _recurrenceController.text = draft.recurrenceText;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.isEditing) return;
    if (state == AppLifecycleState.paused) {
      _persistDraftOrClear();
    }
  }

  int? _parseRecurrenceDays() {
    final t = _recurrenceController.text.trim();
    if (t.isEmpty) return null;
    final v = int.tryParse(t);
    if (v == null || v <= 0) return null;
    return v;
  }

  List<String> _dependencyListForSubmit() {
    final list = _selectedDependencyIds.toList()..sort();
    return list;
  }

  /// True if any selected dependency is missing or not completed (`status == 2`).
  bool _hasIncompleteSelectedDependencies(TaskListState state) {
    if (_selectedDependencyIds.isEmpty) return false;
    final byId = {for (final t in state.tasks) t.id: t};
    for (final id in _selectedDependencyIds) {
      final dep = byId[id];
      if (dep == null || dep.status != _kStatusCompleted) return true;
    }
    return false;
  }

  void _onTaskStatusIndexChanged(
    BuildContext context,
    int index,
    TaskListState blocState,
  ) {
    if (index == _kStatusCompleted &&
        _hasIncompleteSelectedDependencies(blocState)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete all dependency tasks before marking this one completed.',
          ),
        ),
      );
      return;
    }
    setState(() => _currentStatusIndex = index);
  }

  @override
  void dispose() {
    if (!widget.isEditing) {
      WidgetsBinding.instance.removeObserver(this);
      _persistDraftOrClear();
    }
    _nameController.dispose();
    _descriptionController.dispose();
    _recurrenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bloc = context.read<TaskListBloc>();
    final blocState = bloc.state;
    if (_currentStatusIndex == _kStatusCompleted &&
        _hasIncompleteSelectedDependencies(blocState)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete all dependency tasks before marking this task completed.',
          ),
        ),
      );
      return;
    }

    final recurrenceDays = _parseRecurrenceDays();

    if (widget.isEditing) {
      final existing = widget.taskToEdit!;
      final task = TaskEntity(
        id: existing.id,
        name: _nameController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        priority: _currentPriorityIndex,
        status: _currentStatusIndex,
        dependencies: _dependencyListForSubmit(),
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        createdBy: existing.createdBy,
        sortOrder: existing.sortOrder,
        recurrenceDays: recurrenceDays,
      );
      bloc.add(UpdateTaskRequested(task));
    } else {
      final task = TaskEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        priority: _currentPriorityIndex,
        status: _currentStatusIndex,
        dependencies: _dependencyListForSubmit(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: "Harry Asher",
        recurrenceDays: recurrenceDays,
      );
      bloc.add(CreateTaskRequested(task));
      _suppressDraftPersistence = true;
      await CreateTaskDraftStorage.clear();
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Orchestrate",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF004AC6),
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : const Icon(Icons.menu),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 18, backgroundColor: Colors.blueGrey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing ? "Update task" : "New Task Creation",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  editing
                      ? "Change details and save to update this task."
                      : "Define the parameters of your next project milestone.",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        _buildMainForm(context),
                        const SizedBox(height: 24),
                        _buildTimeLinebar(context),
                        const SizedBox(height: 24),
                        _buildDependencyTab(),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OrchestrateTheme.primary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            editing ? "UPDATE TASK" : "CREATE TASK",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainForm(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TASK NAME",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "e.g., Build New Project",
                    filled: true,
                    fillColor: OrchestrateTheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "DESCRIPTION",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Requirements of the project work...",
                    filled: true,
                    fillColor: OrchestrateTheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDependencyTab() {
    return BlocBuilder<TaskListBloc, TaskListState>(
      buildWhen: (prev, next) => prev.tasks != next.tasks,
      builder: (context, state) {
        final selfId = widget.taskToEdit?.id;
        final candidates = state.tasks.where((t) => t.id != selfId).toList();

        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.alt_route,
                      color: OrchestrateTheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Dependencies",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Select tasks that must be done before this one.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                if (candidates.isEmpty)
                  Text(
                    state.status == TaskListStatus.loading
                        ? "Loading tasks…"
                        : "No other tasks yet. Save this task, add more tasks, then edit to link dependencies.",
                    style: const TextStyle(color: Colors.black54, height: 1.4),
                  )
                else
                  ...candidates.map(
                    (t) => _buildDependencyCheckboxRow(context, t),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDependencyCheckboxRow(BuildContext context, TaskEntity task) {
    final selected = _selectedDependencyIds.contains(task.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: OrchestrateTheme.primary, width: 4),
          ),
        ),
        child: CheckboxListTile(
          value: selected,
          onChanged: (v) {
            final blocState = context.read<TaskListBloc>().state;
            setState(() {
              if (v ?? false) {
                _selectedDependencyIds.add(task.id);
              } else {
                _selectedDependencyIds.remove(task.id);
              }
              if (_currentStatusIndex == _kStatusCompleted &&
                  _hasIncompleteSelectedDependencies(blocState)) {
                _currentStatusIndex = 1;
              }
            });
          },
          title: Text(
            task.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: task.description.isEmpty
              ? Text(
                  "No description",
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                )
              : Text(
                  task.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF434655),
                    height: 1.35,
                  ),
                ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: OrchestrateTheme.primary,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeLinebar(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskListState>(
      buildWhen: (a, b) => a.tasks != b.tasks,
      builder: (context, blocState) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OrchestrateTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: OrchestrateTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TIMELINE & PRIORITY",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 24),
                  AppDatePicker(
                    title: "Due Date",
                    selectedDate:
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2080),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(
                                    primary: OrchestrateTheme.primary,
                                    onPrimary: Colors.white,
                                    onSurface: OrchestrateTheme.onSurface,
                                  ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: OrchestrateTheme.primary,
                                  textStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: OrchestrateTheme.primary,
                                  ),
                                ),
                              ),
                              appBarTheme: const AppBarTheme(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                centerTitle: false,
                                iconTheme: IconThemeData(color: Colors.white),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  PrioritySelector(
                    title: "Task Status",
                    selectedIndex: _currentStatusIndex,
                    options: const [
                      PriorityOption(label: "TO-DO", color: Colors.red),
                      PriorityOption(
                        label: "IN-PROGRESS",
                        color: Colors.orange,
                      ),
                      PriorityOption(label: "COMPLETED", color: Colors.green),
                    ],
                    onChanged: (index) =>
                        _onTaskStatusIndexChanged(context, index, blocState),
                  ),
                  const SizedBox(height: 24),
                  PrioritySelector(
                    title: "Priority Level",
                    selectedIndex: _currentPriorityIndex,
                    options: const [
                      PriorityOption(label: "LOW", color: Colors.green),
                      PriorityOption(label: "MEDIUM", color: Colors.orange),
                      PriorityOption(label: "HIGH", color: Colors.red),
                    ],
                    onChanged: (index) {
                      setState(() {
                        _currentPriorityIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "RECURRENCE (EVERY N DAYS)",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _recurrenceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: "e.g., 7 — leave empty for no repeat",
                      filled: true,
                      fillColor: OrchestrateTheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "When you mark this task completed, a new copy is created "
                    "with the same details and a due date of today plus this many days.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
