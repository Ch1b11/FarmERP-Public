import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/empty_state_indicator.dart';
import '../../../../../core/widgets/skeleton_loader.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/department.dart';
import '../../../domain/entities/employee.dart';
import '../../bloc/employees_bloc.dart';
import '../../bloc/employees_event.dart';
import '../employee_editor_sheet.dart';
import '../employee_list_tile.dart';

class EmployeesTabletLayout extends StatefulWidget {
  final List<Employee> employees;
  final String searchQuery;
  final List<Department> departments;
  final String? selectedDepartmentId;
  final bool isLoading;

  const EmployeesTabletLayout({
    super.key,
    required this.employees,
    this.searchQuery = '',
    this.departments = const [],
    this.selectedDepartmentId,
    this.isLoading = false,
  });

  @override
  State<EmployeesTabletLayout> createState() => _EmployeesTabletLayoutState();
}

class _EmployeesTabletLayoutState extends State<EmployeesTabletLayout> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant EmployeesTabletLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => context.read<EmployeesBloc>().add(
        const EmployeesFetchRequested(forceRefresh: true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: l10n.searchEmployees,
                  leading: const Icon(Icons.search_rounded, size: 20),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<EmployeesBloc>().add(
                            const EmployeesSearchChanged(''),
                          );
                        },
                      ),
                  ],
                  onChanged: (v) => context.read<EmployeesBloc>().add(
                    EmployeesSearchChanged(v),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (widget.departments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FilterChip(
                            label: Text(l10n.allDepartments),
                            selected: widget.selectedDepartmentId == null,
                            onSelected: (_) {
                              context.read<EmployeesBloc>().add(
                                const EmployeeDepartmentFilterChanged(null),
                              );
                            },
                          ),
                        ),
                        ...widget.departments.map((d) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: FilterChip(
                              label: Text(d.name),
                              selected: widget.selectedDepartmentId == d.id,
                              onSelected: (_) {
                                context.read<EmployeesBloc>().add(
                                  EmployeeDepartmentFilterChanged(d.id),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${widget.employees.length} ${l10n.employees}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: (widget.isLoading && widget.employees.isEmpty)
                ? const EmployeeListSkeleton()
                : widget.employees.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: EmptyStateIndicator(
                        icon: widget.searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.people_outline_rounded,
                        message: widget.searchQuery.isNotEmpty
                            ? '${l10n.noEmployeesMatch} "${widget.searchQuery}"'
                            : l10n.noEmployeesFound,
                        verticalPadding: 32,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    itemCount: widget.employees.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final emp = widget.employees[index];
                      return EmployeeListTile(
                        employee: emp,
                        onEdit: () =>
                            EmployeeEditorSheet.show(context, employee: emp),
                        onDelete: () => context.read<EmployeesBloc>().add(
                          EmployeeDeactivateRequested(emp.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
