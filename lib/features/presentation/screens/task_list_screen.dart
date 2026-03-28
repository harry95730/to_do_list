import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/presentation/bloc/task_bloc.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/bloc/task_state.dart';
import 'package:to_do_list/features/presentation/screens/create_task.dart';
import 'package:to_do_list/theme.dart';

List<InlineSpan> _highlightQueryInText(
  String text,
  String query,
  TextStyle normalStyle,
  TextStyle highlightStyle,
) {
  final trimmed = query.trim();
  if (trimmed.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: normalStyle)];
  }
  final lowerText = text.toLowerCase();
  final lowerQ = trimmed.toLowerCase();
  final spans = <InlineSpan>[];
  var start = 0;
  final qLen = trimmed.length;
  while (start <= text.length) {
    final i = lowerText.indexOf(lowerQ, start);
    if (i < 0) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: normalStyle));
      }
      break;
    }
    if (i > start) {
      spans.add(TextSpan(text: text.substring(start, i), style: normalStyle));
    }
    final end = (i + qLen).clamp(0, text.length);
    spans.add(
      TextSpan(
        text: text.substring(i, end),
        style: highlightStyle,
      ),
    );
    start = end;
  }
  return spans;
}

bool _taskBlockedByIncompleteDependencies(
  TaskEntity task,
  List<TaskEntity> allTasks,
) {
  if (task.dependencies.isEmpty) return false;
  final byId = {for (final t in allTasks) t.id: t};
  for (final id in task.dependencies) {
    final dep = byId[id];
    if (dep == null || dep.status != 2) return true;
  }
  return false;
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _searchQuery => _searchController.text;

  void _closeSearch() {
    setState(() {
      _searchActive = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: OrchestrateTheme.primary,
          leading: _searchActive
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _closeSearch,
                )
              : null,
          title: _searchActive
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search by task name…',
                    hintStyle: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : Text(
                  'Orchestrate',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
          actions: [
            if (_searchActive)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => setState(() => _searchActive = true),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreateTaskScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            _buildCustomTabBar(context),
            Expanded(
              child: TabBarView(
                children: [
                  _TaskListView(filterStatus: null, searchQuery: _searchQuery),
                  _TaskListView(filterStatus: 0, searchQuery: _searchQuery),
                  _TaskListView(filterStatus: 1, searchQuery: _searchQuery),
                  _TaskListView(filterStatus: 2, searchQuery: _searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    return Container(
      color: OrchestrateTheme.primary,
      padding: const EdgeInsets.only(top: 8),
      child: BlocBuilder<TaskListBloc, TaskListState>(
        buildWhen: (prev, next) => prev.tasks != next.tasks,
        builder: (context, state) {
          final tasks = state.tasks;
          final nAll = tasks.length;
          final nTodo = tasks.where((t) => t.status == 0).length;
          final nProgress = tasks.where((t) => t.status == 1).length;
          final nDone = tasks.where((t) => t.status == 2).length;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(
              color: OrchestrateTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: OrchestrateTheme.primary,
              labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                  ),
              unselectedLabelStyle: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: OrchestrateTheme.onSurface.withValues(alpha: 0.6),
                  ),
              labelColor: OrchestrateTheme.primary.withValues(alpha: 0.6),
              unselectedLabelColor:
                  OrchestrateTheme.onSurface.withValues(alpha: 0.6),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(text: 'All ($nAll)'),
                Tab(text: 'To-Do ($nTodo)'),
                Tab(text: 'In Progress ($nProgress)'),
                Tab(text: 'Completed ($nDone)'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  final int? filterStatus;
  final String searchQuery;

  const _TaskListView({
    this.filterStatus,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        if (state.status == TaskListStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        var filtered = filterStatus == null
            ? state.tasks
            : state.tasks.where((t) => t.status == filterStatus).toList();

        final q = searchQuery.trim().toLowerCase();
        if (q.isNotEmpty) {
          filtered = filtered
              .where((t) => t.name.toLowerCase().contains(q))
              .toList();
        }

        final active = filtered.where((t) => t.dependencies.isEmpty).toList();
        final blocked = filtered
            .where((t) => t.dependencies.isNotEmpty)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CollapsibleSection(
              title: "Active Sequence",
              icon: Icons.bolt,
              iconColor: OrchestrateTheme.primary,
              tasks: active,
              allTasks: state.tasks,
              searchQuery: searchQuery,
            ),
            const SizedBox(height: 16),
            _CollapsibleSection(
              title: "Dependencies",
              icon: Icons.alt_route,
              iconColor: OrchestrateTheme.tertiary,
              tasks: blocked,
              allTasks: state.tasks,
              searchQuery: searchQuery,
            ),
          ],
        );
      },
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<TaskEntity> tasks;
  final List<TaskEntity> allTasks;
  final String searchQuery;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.tasks,
    required this.allTasks,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = context.select(
      (TaskListBloc b) => b.state.expandedSections.contains(title),
    );

    return Column(
      children: [
        ListTile(
          onTap: () => context.read<TaskListBloc>().add(ToggleSection(title)),
          leading: Icon(icon, color: iconColor),
          title: Text(
            '$title (${tasks.length})',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down),
          ),
        ),
        if (isExpanded)
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16,
              ),
              child: _TaskCard(
                task: task,
                allTasks: allTasks,
                searchQuery: searchQuery,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  final int? status;

  const _TaskStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      0 => ('TO-DO', Colors.red),
      1 => ('IN-PROGRESS', Colors.orange),
      2 => ('COMPLETED', Colors.green),
      _ => ('—', Colors.black45),
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;
  final List<TaskEntity> allTasks;
  final String searchQuery;

  const _TaskCard({
    required this.task,
    required this.allTasks,
    required this.searchQuery,
  });

  static const Color _highlightBg = Color(0xFFFFF59D);
  static const Color _highlightFg = Color(0xFF3E2723);

  @override
  Widget build(BuildContext context) {
    final bool blocked =
        _taskBlockedByIncompleteDependencies(task, allTasks);

    // Priority logic based on your Entity
    final bool isHigh = task.priority == 2;
    final Color priorityColor = isHigh
        ? OrchestrateTheme.tertiary
        : (task.priority == 1 ? Colors.orange : Colors.green);

    final nameBaseStyle = GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      fontSize: 16,
      color: const Color(0xFF191B23),
    );
    final nameHighlightStyle = nameBaseStyle.copyWith(
      backgroundColor: _highlightBg,
      color: _highlightFg,
    );

    final descBaseStyle = GoogleFonts.inter(
      fontSize: 13,
      color: const Color(0xFF434655),
      height: 1.5,
    );
    final descHighlightStyle = descBaseStyle.copyWith(
      backgroundColor: _highlightBg,
      color: _highlightFg,
    );

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateTaskScreen(taskToEdit: task),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: priorityColor, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: _highlightQueryInText(
                                  task.name,
                                  searchQuery,
                                  nameBaseStyle,
                                  nameHighlightStyle,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (blocked) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Waiting on incomplete dependencies',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _TaskStatusBadge(status: task.status),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: _highlightQueryInText(
                          task.description,
                          searchQuery,
                          descBaseStyle,
                          descHighlightStyle,
                        ),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F1F9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFFEDEDF9),
                        child: Icon(Icons.person, size: 14, color: Colors.grey),
                      ),
                      _buildDateInfo(task.dueDate),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!blocked) return card;

    return Opacity(
      opacity: 0.48,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: card,
      ),
    );
  }

  Widget _buildDateInfo(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    String displayDate;
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      displayDate = "Due Today";
    } else if (date.difference(now).inDays == 1) {
      displayDate = "Due Tomorrow";
    } else {
      displayDate = "${date.day}/${date.month}/${date.year}";
    }

    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: Colors.black45,
        ),
        const SizedBox(width: 6),
        Text(
          displayDate,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}
