import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_list/features/domain/entities/task_entity.dart';
import 'package:to_do_list/features/presentation/bloc/task_bloc.dart';
import 'package:to_do_list/features/presentation/bloc/task_event.dart';
import 'package:to_do_list/features/presentation/bloc/task_state.dart';
import 'package:to_do_list/features/presentation/screens/create_task.dart';
import 'package:to_do_list/theme.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: OrchestrateTheme.primary,
          title: Text(
            "Orchestrate",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
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
                  _TaskListView(filterStatus: null), // All
                  _TaskListView(filterStatus: 0), // To-Do
                  _TaskListView(filterStatus: 1), // In-Progress
                  _TaskListView(filterStatus: 2), // Completed
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
      child: Container(
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
            fontSize: 16, // slightly bigger but still clean
            color: Colors.white,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.titleMedium
              ?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: OrchestrateTheme.onSurface.withValues(alpha: 0.6),
              ),

          labelColor: OrchestrateTheme.primary.withValues(alpha: 0.6),
          unselectedLabelColor: OrchestrateTheme.onSurface.withValues(alpha: 0.6),

          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),

          tabs: const [
            Tab(text: "All"),
            Tab(text: "To-Do"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  final int? filterStatus;
  const _TaskListView({this.filterStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        if (state.status == TaskListStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = filterStatus == null
            ? state.tasks
            : state.tasks.where((t) => t.status == filterStatus).toList();

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
            ),
            const SizedBox(height: 16),
            _CollapsibleSection(
              title: "Dependencies",
              icon: Icons.alt_route,
              iconColor: OrchestrateTheme.tertiary,
              tasks: blocked,
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

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.tasks,
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
            title,
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
              child: _TaskCard(task: task),
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
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    // Priority logic based on your Entity
    final bool isHigh = task.priority == 2;
    final Color priorityColor = isHigh
        ? OrchestrateTheme.tertiary
        : (task.priority == 1 ? Colors.orange : Colors.green);

    return Padding(
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
                            Text(
                              task.name,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: const Color(0xFF191B23),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _TaskStatusBadge(status: task.status),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      task.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF434655),
                        height: 1.5,
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
