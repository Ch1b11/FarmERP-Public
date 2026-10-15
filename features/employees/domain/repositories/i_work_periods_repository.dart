import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';

abstract class IWorkPeriodsRepository {
  Future<Either<Failure, WorkPeriod?>> getActiveWorkPeriod(String employeeId);

  Future<Either<Failure, WorkPeriod?>> getCachedActiveWorkPeriod(
    String employeeId,
  );

  Future<Either<Failure, WorkPeriod>> startWorkPeriod({
    required String employeeId,
    required DateTime arrivalDate,
    required String arrivalTimeType,
  });

  Future<Either<Failure, WorkPeriod>> addWithdrawal({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  });

  Future<Either<Failure, WorkPeriod>> addBonus({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  });

  Future<Either<Failure, WorkPeriod>> completeAndSettlePeriod({
    required String periodId,
    required DateTime departureDate,
    required String accountId,
  });

  Future<Either<Failure, List<WorkPeriod>>> getWorkPeriodHistory(
    String employeeId,
  );

  Future<Either<Failure, List<WorkPeriod>>> getCachedWorkPeriodHistory(
    String employeeId,
  );

  Future<Either<Failure, void>> discardOfflineWorkPeriod(String periodId);

  Stream<List<WorkPeriod>> watchWorkPeriods();

  Stream<List<WorkPeriod>> watchWorkPeriodHistory(String employeeId);

  Stream<WorkPeriod?> watchActiveWorkPeriod(String employeeId);
}
