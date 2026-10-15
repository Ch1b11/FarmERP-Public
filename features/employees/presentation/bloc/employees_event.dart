import 'package:equatable/equatable.dart';

abstract class EmployeesEvent extends Equatable {
  const EmployeesEvent();
  @override
  List<Object?> get props => [];
}

class EmployeesFetchRequested extends EmployeesEvent {
  final bool forceRefresh;
  const EmployeesFetchRequested({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class EmployeesSearchChanged extends EmployeesEvent {
  final String query;
  const EmployeesSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class EmployeeDepartmentFilterChanged extends EmployeesEvent {
  final String? departmentId;
  const EmployeeDepartmentFilterChanged(this.departmentId);
  @override
  List<Object?> get props => [departmentId];
}

class EmployeeCreateRequested extends EmployeesEvent {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? nationalId;
  final String? mobileNumber;
  final String? jobTitle;
  final String? departmentId;
  final double dailyWage;

  const EmployeeCreateRequested({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.nationalId,
    this.mobileNumber,
    this.jobTitle,
    this.departmentId,
    required this.dailyWage,
  });

  @override
  List<Object?> get props => [
    firstName,
    middleName,
    lastName,
    nationalId,
    mobileNumber,
    jobTitle,
    departmentId,
    dailyWage,
  ];
}

class EmployeeUpdateRequested extends EmployeesEvent {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? nationalId;
  final String? mobileNumber;
  final String? jobTitle;
  final String? departmentId;
  final double dailyWage;

  const EmployeeUpdateRequested({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.nationalId,
    this.mobileNumber,
    this.jobTitle,
    this.departmentId,
    required this.dailyWage,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    middleName,
    lastName,
    nationalId,
    mobileNumber,
    jobTitle,
    departmentId,
    dailyWage,
  ];
}

class EmployeeDeleteRequested extends EmployeesEvent {
  final String id;
  const EmployeeDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class EmployeeDeactivateRequested extends EmployeesEvent {
  final String id;
  const EmployeeDeactivateRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class EmployeesCacheUpdated extends EmployeesEvent {
  const EmployeesCacheUpdated();
}

class EmployeesDepartmentsLoadRequested extends EmployeesEvent {
  const EmployeesDepartmentsLoadRequested();
}
