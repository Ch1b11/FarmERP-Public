import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/sort_utils.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/create_employee_usecase.dart';
import '../../domain/usecases/deactivate_employee_usecase.dart';
import '../../domain/usecases/delete_employee_usecase.dart';
import '../../domain/usecases/get_active_work_period_usecase.dart';
import '../../domain/usecases/get_cached_employees_usecase.dart';
import '../../domain/usecases/get_departments_usecase.dart';
import '../../domain/usecases/get_employees_usecase.dart';
import '../../domain/usecases/update_employee_usecase.dart';
import 'employees_event.dart';
import 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final GetEmployeesUseCase getEmployeesUseCase;
  final GetCachedEmployeesUseCase? getCachedEmployeesUseCase;
  final CreateEmployeeUseCase createEmployeeUseCase;
  final UpdateEmployeeUseCase updateEmployeeUseCase;
  final DeleteEmployeeUseCase deleteEmployeeUseCase;
  final DeactivateEmployeeUseCase deactivateEmployeeUseCase;
  final GetDepartmentsUseCase getDepartmentsUseCase;
  final GetActiveWorkPeriodUseCase? getActiveWorkPeriodUseCase;

  StreamSubscription<List<Employee>>? _employeesSubscription;

  EmployeesBloc({
    required this.getEmployeesUseCase,
    this.getCachedEmployeesUseCase,
    required this.createEmployeeUseCase,
    required this.updateEmployeeUseCase,
    required this.deleteEmployeeUseCase,
    required this.deactivateEmployeeUseCase,
    required this.getDepartmentsUseCase,
    this.getActiveWorkPeriodUseCase,
  }) : super(const EmployeesInitial()) {
    on<EmployeesFetchRequested>(_onFetchRequested);
    on<EmployeesSearchChanged>(_onSearchChanged);
    on<EmployeeDepartmentFilterChanged>(_onDepartmentFilterChanged);
    on<EmployeeCreateRequested>(_onCreateRequested);
    on<EmployeeUpdateRequested>(_onUpdateRequested);
    on<EmployeeDeleteRequested>(_onDeleteRequested);
    on<EmployeeDeactivateRequested>(_onDeactivateRequested);
    on<EmployeesCacheUpdated>(_onCacheUpdated);
    on<EmployeesDepartmentsLoadRequested>(_onDepartmentsLoadRequested);

    _employeesSubscription = getEmployeesUseCase.repository
        .watchEmployees()
        .listen((_) {
          add(const EmployeesCacheUpdated());
        });
  }

  @override
  Future<void> close() {
    _employeesSubscription?.cancel();
    return super.close();
  }

  List<Employee> _sort(List<Employee> list) {
    final copy = List<Employee>.from(list);
    copy.sort((a, b) => SortUtils.compareIds(a.id, b.id));
    return copy;
  }

  List<Employee> _filter(
    List<Employee> all,
    String query,
    String? departmentId,
  ) {
    var result = all;
    if (departmentId != null) {
      result = result.where((e) => e.departmentId == departmentId).toList();
    }
    if (query.trim().isNotEmpty) {
      final lower = query.toLowerCase();
      result = result.where((e) {
        return e.fullName.toLowerCase().contains(lower) ||
            (e.jobTitle?.toLowerCase().contains(lower) ?? false) ||
            (e.departmentName?.toLowerCase().contains(lower) ?? false);
      }).toList();
    }
    return result;
  }

  List<Employee> _enrichEmployees(
    List<Employee> employees,
    List<Department> departments,
  ) {
    return employees.map((emp) {
      String? enrichedDepartmentName = emp.departmentName;

      if (emp.departmentId != null) {
        final dept = departments
            .where((d) => d.id.toString() == emp.departmentId)
            .firstOrNull;
        if (dept != null) {
          enrichedDepartmentName = dept.name;
        }
      }

      if (enrichedDepartmentName != emp.departmentName) {
        return emp.copyWith(departmentName: enrichedDepartmentName);
      }
      return emp;
    }).toList();
  }

  Future<void> _onCacheUpdated(
    EmployeesCacheUpdated event,
    Emitter<EmployeesState> emit,
  ) async {
    if (state is EmployeesLoaded) {
      final current = state as EmployeesLoaded;
      final cacheResult = getCachedEmployeesUseCase != null
          ? await getCachedEmployeesUseCase!()
          : await getEmployeesUseCase.getCachedEmployees();
      cacheResult.fold((_) {}, (cached) {
        final enriched = _enrichEmployees(cached, current.departments);
        final sorted = _sort(enriched);
        emit(
          current.copyWith(
            allEmployees: sorted,
            filteredEmployees: _filter(
              sorted,
              current.searchQuery,
              current.departmentFilter,
            ),
          ),
        );
      });
    }
  }

  Future<void> _onFetchRequested(
    EmployeesFetchRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    final currentQuery = state is EmployeesLoaded
        ? (state as EmployeesLoaded).searchQuery
        : '';
    final currentDeptFilter = state is EmployeesLoaded
        ? (state as EmployeesLoaded).departmentFilter
        : null;
    final currentDepts = state is EmployeesLoaded
        ? (state as EmployeesLoaded).departments
        : <Department>[];

    final cacheResult = getCachedEmployeesUseCase != null
        ? await getCachedEmployeesUseCase!()
        : await getEmployeesUseCase.getCachedEmployees();
    var cached = cacheResult.getOrElse(() => []);

    cached = _enrichEmployees(cached, currentDepts);
    cached = _sort(cached);

    if (cached.isEmpty) {
      if (state is! EmployeesLoaded) emit(const EmployeesLoading());
    } else {
      emit(
        EmployeesLoaded(
          allEmployees: cached,
          filteredEmployees: _filter(cached, currentQuery, currentDeptFilter),
          searchQuery: currentQuery,
          departmentFilter: currentDeptFilter,
          departments: currentDepts,
          isActionInProgress: false,
        ),
      );
    }

    try {
      final result = await getEmployeesUseCase(forceRefresh: true);
      result.fold(
        (failure) {
          if (state is! EmployeesLoaded) {
            emit(EmployeesError(message: failure.message));
          }
        },
        (fresh) {
          final activeDepts = state is EmployeesLoaded
              ? (state as EmployeesLoaded).departments
              : currentDepts;
          final enriched = _enrichEmployees(fresh, activeDepts);
          final sorted = _sort(enriched);
          final activeQuery = state is EmployeesLoaded
              ? (state as EmployeesLoaded).searchQuery
              : currentQuery;
          final activeDept = state is EmployeesLoaded
              ? (state as EmployeesLoaded).departmentFilter
              : currentDeptFilter;
          emit(
            EmployeesLoaded(
              allEmployees: sorted,
              filteredEmployees: _filter(sorted, activeQuery, activeDept),
              searchQuery: activeQuery,
              departmentFilter: activeDept,
              departments: activeDepts,
              isActionInProgress: false,
            ),
          );
        },
      );
    } catch (e) {
      if (state is! EmployeesLoaded) {
        emit(EmployeesError(message: e.toString()));
      }
    }

    add(const EmployeesDepartmentsLoadRequested());
  }

  Future<void> _onDepartmentsLoadRequested(
    EmployeesDepartmentsLoadRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    if (state is! EmployeesLoaded) return;
    final current = state as EmployeesLoaded;
    try {
      final result = await getDepartmentsUseCase();
      result.fold(
        (_) {},
        (depts) => emit(current.copyWith(departments: depts)),
      );
    } catch (e) {
      debugPrint('[EmployeesBloc] Departments load failed: $e');
    }
  }

  void _onSearchChanged(
    EmployeesSearchChanged event,
    Emitter<EmployeesState> emit,
  ) {
    if (state is EmployeesLoaded) {
      final current = state as EmployeesLoaded;
      emit(
        current.copyWith(
          searchQuery: event.query,
          filteredEmployees: _filter(
            current.allEmployees,
            event.query,
            current.departmentFilter,
          ),
        ),
      );
    }
  }

  void _onDepartmentFilterChanged(
    EmployeeDepartmentFilterChanged event,
    Emitter<EmployeesState> emit,
  ) {
    if (state is EmployeesLoaded) {
      final current = state as EmployeesLoaded;
      final newFilter = event.departmentId;
      emit(
        EmployeesLoaded(
          allEmployees: current.allEmployees,
          filteredEmployees: _filter(
            current.allEmployees,
            current.searchQuery,
            newFilter,
          ),
          searchQuery: current.searchQuery,
          departmentFilter: newFilter,
          departments: current.departments,
          isActionInProgress: false,
        ),
      );
    }
  }

  Future<void> _onCreateRequested(
    EmployeeCreateRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    if (state is! EmployeesLoaded) return;
    final current = state as EmployeesLoaded;
    emit(current.copyWith(isActionInProgress: true));

    final result = await createEmployeeUseCase(
      firstName: event.firstName,
      middleName: event.middleName,
      lastName: event.lastName,
      nationalId: event.nationalId,
      mobileNumber: event.mobileNumber,
      jobTitle: event.jobTitle,
      departmentId: event.departmentId,
      dailyWage: event.dailyWage,
    );

    result.fold(
      (failure) => emit(
        current.copyWith(
          actionMessage: failure.message,
          isActionInProgress: false,
        ),
      ),
      (created) {
        final updatedAll = _sort([created, ...current.allEmployees]);
        emit(
          EmployeesLoaded(
            allEmployees: updatedAll,
            filteredEmployees: _filter(
              updatedAll,
              current.searchQuery,
              current.departmentFilter,
            ),
            searchQuery: current.searchQuery,
            departmentFilter: current.departmentFilter,
            departments: current.departments,
            actionMessage: 'employeeCreated',
            isActionInProgress: false,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateRequested(
    EmployeeUpdateRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    if (state is! EmployeesLoaded) return;
    final current = state as EmployeesLoaded;
    emit(current.copyWith(isActionInProgress: true));

    final result = await updateEmployeeUseCase(
      id: event.id,
      firstName: event.firstName,
      middleName: event.middleName,
      lastName: event.lastName,
      nationalId: event.nationalId,
      mobileNumber: event.mobileNumber,
      jobTitle: event.jobTitle,
      departmentId: event.departmentId,
      dailyWage: event.dailyWage,
    );

    result.fold(
      (failure) => emit(
        current.copyWith(
          actionMessage: failure.message,
          isActionInProgress: false,
        ),
      ),
      (updated) {
        final updatedAll = _sort(
          current.allEmployees
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
        emit(
          EmployeesLoaded(
            allEmployees: updatedAll,
            filteredEmployees: _filter(
              updatedAll,
              current.searchQuery,
              current.departmentFilter,
            ),
            searchQuery: current.searchQuery,
            departmentFilter: current.departmentFilter,
            departments: current.departments,
            actionMessage: 'employeeUpdated',
            isActionInProgress: false,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteRequested(
    EmployeeDeleteRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    if (state is! EmployeesLoaded) return;
    final current = state as EmployeesLoaded;
    emit(current.copyWith(isActionInProgress: true));

    try {
      final result = await deleteEmployeeUseCase(event.id);
      result.fold(
        (failure) => emit(
          current.copyWith(
            actionMessage: failure.message,
            isActionInProgress: false,
          ),
        ),
        (_) {
          final updatedAll = current.allEmployees
              .where((e) => e.id != event.id)
              .toList();
          emit(
            EmployeesLoaded(
              allEmployees: updatedAll,
              filteredEmployees: _filter(
                updatedAll,
                current.searchQuery,
                current.departmentFilter,
              ),
              searchQuery: current.searchQuery,
              departmentFilter: current.departmentFilter,
              departments: current.departments,
              actionMessage: 'employeeDeleted',
              isActionInProgress: false,
            ),
          );
        },
      );
    } on StateError catch (e) {
      emit(
        EmployeesError(
          message: e.message,
          cachedEmployees: current.allEmployees,
        ),
      );
    } catch (e) {
      emit(
        EmployeesError(
          message: e.toString(),
          cachedEmployees: current.allEmployees,
        ),
      );
    }
  }

  Future<void> _onDeactivateRequested(
    EmployeeDeactivateRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    if (state is! EmployeesLoaded) return;
    final current = state as EmployeesLoaded;
    emit(current.copyWith(isActionInProgress: true));

    try {
      final result = await deactivateEmployeeUseCase(event.id);
      result.fold(
        (failure) => emit(
          current.copyWith(
            actionMessage: failure.message,
            isActionInProgress: false,
          ),
        ),
        (_) {
          final updatedAll = current.allEmployees
              .where((e) => e.id != event.id)
              .toList();
          emit(
            EmployeesLoaded(
              allEmployees: updatedAll,
              filteredEmployees: _filter(
                updatedAll,
                current.searchQuery,
                current.departmentFilter,
              ),
              searchQuery: current.searchQuery,
              departmentFilter: current.departmentFilter,
              departments: current.departments,
              actionMessage: 'employeeDeactivated',
              isActionInProgress: false,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        current.copyWith(
          actionMessage: e.toString(),
          isActionInProgress: false,
        ),
      );
    }
  }
}
