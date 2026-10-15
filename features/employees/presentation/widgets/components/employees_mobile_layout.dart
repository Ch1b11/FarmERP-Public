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

class EmployeesMobileLayout extends StatefulWidget {
  final List<Employee> employees;
  final String searchQuery;
  final List<Department> departments;
  final String? selectedDepartmentId;
  final bool isLoading;

  const EmployeesMobileLayout({
    super.key,
    required this.employees,
    this.searchQuery = '',
    this.departments = const [],
    this.selectedDepartmentId,
    this.isLoading = false,
  });

  @override
  State<EmployeesMobileLayout> createState() => _EmployeesMobileLayoutState();
}

class _EmployeesMobileLayoutState extends State<EmployeesMobileLayout> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant EmployeesMobileLayout oldWidget) {
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
      onRefresh: () async {
        context.read<EmployeesBloc>().add(
          const EmployeesFetchRequested(forceRefresh: true),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchBar(
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
                    ),
                    if (widget.departments.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: widget.selectedDepartmentId,
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(l10n.allDepartments),
                              ),
                              ...widget.departments.map(
                                (d) => DropdownMenuItem<String?>(
                                  value: d.id,
                                  child: Text(d.name),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              context.read<EmployeesBloc>().add(
                                EmployeeDepartmentFilterChanged(val),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  '${widget.employees.length} ${l10n.employees}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
