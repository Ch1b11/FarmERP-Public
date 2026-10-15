import 'package:equatable/equatable.dart';

import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';

abstract class EmployeesState extends Equatable {
  const EmployeesState();
  @override
  List<Object?> get props => [];
}

class EmployeesInitial extends EmployeesState {
  const EmployeesInitial();
}

class EmployeesLoading extends EmployeesState {
  const EmployeesLoading();
}

class EmployeesLoaded extends EmployeesState {
  final List<Employee> allEmployees;
  final List<Employee> filteredEmployees;
  final String searchQuery;
  final String? departmentFilter;
  final List<Department> departments;
  final String? actionMessage;
  final bool isActionInProgress;

  const EmployeesLoaded({
    required this.allEmployees,
    required this.filteredEmployees,
    this.searchQuery = '',
    this.departmentFilter,
    this.departments = const [],
    this.actionMessage,
    this.isActionInProgress = false,
  });

  EmployeesLoaded copyWith({
    List<Employee>? allEmployees,
    List<Employee>? filteredEmployees,
    String? searchQuery,
    String? departmentFilter,
    bool clearDepartmentFilter = false,
    List<Department>? departments,
    String? actionMessage,
    bool? isActionInProgress,
  }) {
    return EmployeesLoaded(
      allEmployees: allEmployees ?? this.allEmployees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      departmentFilter: clearDepartmentFilter
          ? null
          : departmentFilter ?? this.departmentFilter,
      departments: departments ?? this.departments,
      actionMessage: actionMessage,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
    );
  }

  @override
  List<Object?> get props => [
    allEmployees,
    filteredEmployees,
    searchQuery,
    departmentFilter,
    departments,
    actionMessage,
    isActionInProgress,
  ];
}

class EmployeesError extends EmployeesState {
  final String message;
  final List<Employee>? cachedEmployees;
  final int timestamp;

  EmployeesError({required this.message, this.cachedEmployees, int? timestamp})
    : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [message, cachedEmployees, timestamp];
}
