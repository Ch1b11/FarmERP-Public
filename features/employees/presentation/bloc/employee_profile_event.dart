import 'package:equatable/equatable.dart';

abstract class EmployeeProfileEvent extends Equatable {
  const EmployeeProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends EmployeeProfileEvent {
  final String employeeId;

  const ProfileLoadRequested(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class ProfileDeleteRequested extends EmployeeProfileEvent {
  const ProfileDeleteRequested();
}

class ProfileDeactivateRequested extends EmployeeProfileEvent {
  const ProfileDeactivateRequested();
}

class StartWorkPeriodSubmitted extends EmployeeProfileEvent {
  final DateTime arrivalDate;
  final String arrivalTimeType;

  const StartWorkPeriodSubmitted({
    required this.arrivalDate,
    required this.arrivalTimeType,
  });

  @override
  List<Object?> get props => [arrivalDate, arrivalTimeType];
}

class WithdrawalSubmitted extends EmployeeProfileEvent {
  final String periodId;
  final double amount;
  final DateTime date;
  final String? notes;

  const WithdrawalSubmitted({
    required this.periodId,
    required this.amount,
    required this.date,
    this.notes,
  });

  @override
  List<Object?> get props => [periodId, amount, date, notes];
}

class BonusSubmitted extends EmployeeProfileEvent {
  final String periodId;
  final double amount;
  final DateTime date;
  final String? notes;

  const BonusSubmitted({
    required this.periodId,
    required this.amount,
    required this.date,
    this.notes,
  });

  @override
  List<Object?> get props => [periodId, amount, date, notes];
}

class PeriodCompletionSubmitted extends EmployeeProfileEvent {
  final String periodId;
  final DateTime departureDate;
  final String accountId;

  const PeriodCompletionSubmitted({
    required this.periodId,
    required this.departureDate,
    required this.accountId,
  });

  @override
  List<Object?> get props => [periodId, departureDate, accountId];
}

class DiscardWorkPeriodRequested extends EmployeeProfileEvent {
  final String periodId;

  const DiscardWorkPeriodRequested(this.periodId);

  @override
  List<Object?> get props => [periodId];
}

class WorkHistoryUpdated extends EmployeeProfileEvent {
  final List<dynamic> history;

  const WorkHistoryUpdated(this.history);

  @override
  List<Object?> get props => [history];
}

class ActivePeriodUpdated extends EmployeeProfileEvent {
  final dynamic activePeriod;

  const ActivePeriodUpdated(this.activePeriod);

  @override
  List<Object?> get props => [activePeriod];
}
