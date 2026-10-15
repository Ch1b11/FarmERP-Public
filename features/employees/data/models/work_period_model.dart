import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/work_period.dart';

class WorkPeriodModel extends WorkPeriod {
  const WorkPeriodModel({
    required super.id,
    required super.employeeId,
    required super.arrivalDate,
    required super.arrivalTimeType,
    super.departureDate,
    required super.dailyWage,
    super.totalWithdrawals = 0.0,
    super.totalBonuses = 0.0,
    super.totalWorkedDays,
    super.totalSalary,
    super.finalSalary,
    super.isSynced = true,
  });

  factory WorkPeriodModel.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['workPeriodId'] ??
        json['WorkPeriodId'] ??
        json['workPeriodID'] ??
        json['WorkPeriodID'] ??
        json['id'] ??
        json['Id'];
    final rawEmployeeId =
        json['employeeId'] ??
        json['EmployeeId'] ??
        json['employeeID'] ??
        json['EmployeeID'];

    final rawArrivalDate = json['arrivalDate'] ?? json['ArrivalDate'];
    final arrivalDate = rawArrivalDate is String
        ? DateTime.parse(rawArrivalDate)
        : (rawArrivalDate is DateTime ? rawArrivalDate : DateTime.now());

    final rawDepartureDate = json['departureDate'] ?? json['DepartureDate'];
    final departureDate = rawDepartureDate != null
        ? (rawDepartureDate is String
              ? DateTime.parse(rawDepartureDate)
              : (rawDepartureDate is DateTime ? rawDepartureDate : null))
        : null;

    final totalWorkedDays =
        (json['totalWorkedDays'] ?? json['TotalWorkedDays']) as num?;
    final totalSalary = (json['totalSalary'] ?? json['TotalSalary']) as num?;
    final finalSalary = (json['finalSalary'] ?? json['FinalSalary']) as num?;

    return WorkPeriodModel(
      id: rawId?.toString() ?? '',
      employeeId: rawEmployeeId?.toString() ?? '',
      arrivalDate: arrivalDate,
      arrivalTimeType:
          json['arrivalTimeType'] as String? ??
          json['ArrivalTimeType'] as String? ??
          'Morning',
      departureDate: departureDate,
      dailyWage: ((json['dailyWage'] ?? json['DailyWage']) as num? ?? 0.0)
          .toDouble(),
      totalWithdrawals:
          ((json['totalWithdrawals'] ?? json['TotalWithdrawals']) as num? ??
                  0.0)
              .toDouble(),
      totalBonuses:
          ((json['totalBonuses'] ?? json['TotalBonuses']) as num? ?? 0.0)
              .toDouble(),
      totalWorkedDays: totalWorkedDays?.toDouble(),
      totalSalary: totalSalary?.toDouble(),
      finalSalary: finalSalary?.toDouble(),
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final parsedEmployeeId = int.tryParse(employeeId);
    return {
      'arrivalDate': DateFormatter.toApiUtcIso8601String(arrivalDate),
      'arrivalTimeType': arrivalTimeType,
      'employeeId': parsedEmployeeId ?? employeeId,
      if (departureDate != null)
        'departureDate': DateFormatter.toApiUtcIso8601String(departureDate!),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'workPeriodId': int.tryParse(id),
      'employeeId': employeeId,
      'arrivalDate': arrivalDate.toIso8601String(),
      'arrivalTimeType': arrivalTimeType,
      'departureDate': departureDate?.toIso8601String(),
      'dailyWage': dailyWage,
      'totalWithdrawals': totalWithdrawals,
      'totalBonuses': totalBonuses,
      'totalWorkedDays': totalWorkedDays,
      'totalSalary': totalSalary,
      'finalSalary': finalSalary,
      'isSynced': isSynced,
    };
  }

  factory WorkPeriodModel.fromLocalJson(Map<String, dynamic> json) {
    final rawId =
        json['id']?.toString() ?? json['workPeriodId']?.toString() ?? '';
    final rawArrivalDate = json['arrivalDate'];
    final arrivalDate = rawArrivalDate is String
        ? DateTime.parse(rawArrivalDate)
        : DateTime.now();

    final rawDepartureDate = json['departureDate'];
    final departureDate = rawDepartureDate != null
        ? DateTime.parse(rawDepartureDate as String)
        : null;

    return WorkPeriodModel(
      id: rawId,
      employeeId: json['employeeId']?.toString() ?? '',
      arrivalDate: arrivalDate,
      arrivalTimeType: json['arrivalTimeType'] as String? ?? 'Morning',
      departureDate: departureDate,
      dailyWage: (json['dailyWage'] as num? ?? 0.0).toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] as num? ?? 0.0).toDouble(),
      totalBonuses: (json['totalBonuses'] as num? ?? 0.0).toDouble(),
      totalWorkedDays: (json['totalWorkedDays'] as num?)?.toDouble(),
      totalSalary: (json['totalSalary'] as num?)?.toDouble(),
      finalSalary: (json['finalSalary'] as num?)?.toDouble(),
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  factory WorkPeriodModel.fromEntity(WorkPeriod period) {
    return WorkPeriodModel(
      id: period.id,
      employeeId: period.employeeId,
      arrivalDate: period.arrivalDate,
      arrivalTimeType: period.arrivalTimeType,
      departureDate: period.departureDate,
      dailyWage: period.dailyWage,
      totalWithdrawals: period.totalWithdrawals,
      totalBonuses: period.totalBonuses,
      totalWorkedDays: period.totalWorkedDays,
      totalSalary: period.totalSalary,
      finalSalary: period.finalSalary,
      isSynced: period.isSynced,
    );
  }
}
