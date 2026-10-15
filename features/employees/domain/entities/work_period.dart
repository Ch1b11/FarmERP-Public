import 'package:equatable/equatable.dart';

class WorkPeriod extends Equatable {
  final String id;
  final String employeeId;
  final DateTime arrivalDate;
  final String arrivalTimeType;
  final DateTime? departureDate;
  final double dailyWage;
  final double totalWithdrawals;
  final double totalBonuses;
  final double? totalWorkedDays;
  final double? totalSalary;
  final double? finalSalary;
  final bool isSynced;

  const WorkPeriod({
    required this.id,
    required this.employeeId,
    required this.arrivalDate,
    required this.arrivalTimeType,
    this.departureDate,
    required this.dailyWage,
    this.totalWithdrawals = 0.0,
    this.totalBonuses = 0.0,
    this.totalWorkedDays,
    this.totalSalary,
    this.finalSalary,
    this.isSynced = true,
  });

  bool get isActive => departureDate == null;

  WorkPeriod copyWith({
    String? id,
    String? employeeId,
    DateTime? arrivalDate,
    String? arrivalTimeType,
    DateTime? departureDate,
    double? dailyWage,
    double? totalWithdrawals,
    double? totalBonuses,
    double? totalWorkedDays,
    double? totalSalary,
    double? finalSalary,
    bool? isSynced,
  }) {
    return WorkPeriod(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      arrivalTimeType: arrivalTimeType ?? this.arrivalTimeType,
      departureDate: departureDate ?? this.departureDate,
      dailyWage: dailyWage ?? this.dailyWage,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      totalBonuses: totalBonuses ?? this.totalBonuses,
      totalWorkedDays: totalWorkedDays ?? this.totalWorkedDays,
      totalSalary: totalSalary ?? this.totalSalary,
      finalSalary: finalSalary ?? this.finalSalary,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    arrivalDate,
    arrivalTimeType,
    departureDate,
    dailyWage,
    totalWithdrawals,
    totalBonuses,
    totalWorkedDays,
    totalSalary,
    finalSalary,
    isSynced,
  ];
}
