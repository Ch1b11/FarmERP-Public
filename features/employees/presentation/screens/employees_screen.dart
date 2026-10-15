import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/layout_manager/adaptive_layout_manager.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import '../utils/employee_ui_helper.dart';
import '../widgets/components/employees_desktop_layout.dart';
import '../widgets/components/employees_mobile_layout.dart';
import '../widgets/components/employees_tablet_layout.dart';
import '../widgets/employee_editor_sheet.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EmployeesBloc>()..add(const EmployeesFetchRequested()),
      child: const EmployeesView(),
    );
  }
}

class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<EmployeesBloc, EmployeesState>(
      listenWhen: (_, current) {
        if (current is EmployeesLoaded && current.actionMessage != null) {
          return true;
        }
        if (current is EmployeesError) return true;
        return false;
      },
      listener: (context, state) {
        if (state is EmployeesLoaded && state.actionMessage != null) {
          final msg = EmployeeUiHelper.resolveMessage(
            l10n,
            state.actionMessage!,
          );
          SnackBarUtils.showSuccess(context, msg);
        } else if (state is EmployeesError) {
          final msg = EmployeeUiHelper.resolveMessage(l10n, state.message);
          SnackBarUtils.showError(context, msg);
        }
      },
      builder: (context, state) {
        final isLoading =
            state is EmployeesLoading || state is EmployeesInitial;
        List<Employee> employees = [];
        String searchQuery = '';
        List<Department> departments = [];
        String? departmentFilter;

        if (state is EmployeesLoaded) {
          employees = state.filteredEmployees;
          searchQuery = state.searchQuery;
          departments = state.departments;
          departmentFilter = state.departmentFilter;
        } else if (state is EmployeesError &&
            state.cachedEmployees != null &&
            state.cachedEmployees!.isNotEmpty) {
          employees = state.cachedEmployees!;
        }

        if (state is EmployeesError && employees.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.failedToLoadEmployees,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppActionButton(
                    label: l10n.retry,
                    isFilled: true,
                    width: 140,
                    leadingIcon: const Icon(Icons.refresh_rounded),
                    onTap: () => context.read<EmployeesBloc>().add(
                      const EmployeesFetchRequested(forceRefresh: true),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            heroTag: 'employees_add_fab',
            tooltip: l10n.addEmployee,
            onPressed: () => EmployeeEditorSheet.show(context),
            child: const Icon(Icons.person_add_rounded),
          ),
          body: AdaptiveLayoutManager(
            mobileLayout: (ctx) => EmployeesMobileLayout(
              employees: employees,
              searchQuery: searchQuery,
              departments: departments,
              selectedDepartmentId: departmentFilter,
              isLoading: isLoading,
            ),
            tabletLayout: (ctx) => EmployeesTabletLayout(
              employees: employees,
              searchQuery: searchQuery,
              departments: departments,
              selectedDepartmentId: departmentFilter,
              isLoading: isLoading,
            ),
            desktopLayout: (ctx) => EmployeesDesktopLayout(
              employees: employees,
              searchQuery: searchQuery,
              departments: departments,
              selectedDepartmentId: departmentFilter,
              isLoading: isLoading,
            ),
          ),
        );
      },
    );
  }
}
