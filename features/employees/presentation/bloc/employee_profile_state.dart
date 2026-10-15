import 'package:equatable/equatable.dart';

import '../../../finance/domain/entities/finance_account.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/work_period.dart';

abstract class EmployeeProfileState extends Equatable {
  const EmployeeProfileState();

  @override
  List<Object?> get props => [];
}

class EmployeeProfileInitial extends EmployeeProfileState {}

class EmployeeProfileLoading extends EmployeeProfileState {}

class EmployeeProfileLoaded extends EmployeeProfileState {
  final Employee employee;
  final WorkPeriod? activePeriod;
  final List<WorkPeriod> workHistory;
  final List<FinanceAccount> financeAccounts;
  final bool isSubmitting;
  final bool isDeleted;
  final String? errorMessage;
  final String? successMessage;

  const EmployeeProfileLoaded({
    required this.employee,
    this.activePeriod,
    this.workHistory = const [],
    this.financeAccounts = const [],
    this.isSubmitting = false,
    this.isDeleted = false,
    this.errorMessage,
    this.successMessage,
  });

  EmployeeProfileLoaded copyWith({
    Employee? employee,
    WorkPeriod? activePeriod,
    bool clearActivePeriod = false,
    List<WorkPeriod>? workHistory,
    List<FinanceAccount>? financeAccounts,
    bool? isSubmitting,
    bool? isDeleted,
    String? errorMessage,
    String? successMessage,
  }) {
    return EmployeeProfileLoaded(
      employee: employee ?? this.employee,
      activePeriod: clearActivePeriod
          ? null
          : (activePeriod ?? this.activePeriod),
      workHistory: workHistory ?? this.workHistory,
      financeAccounts: financeAccounts ?? this.financeAccounts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isDeleted: isDeleted ?? this.isDeleted,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    employee,
    activePeriod,
    workHistory,
    financeAccounts,
    isSubmitting,
    isDeleted,
    errorMessage,
    successMessage,
  ];
}

class EmployeeProfileError extends EmployeeProfileState {
  final String message;

  const EmployeeProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
