import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';
import '../repositories/i_work_periods_repository.dart';

class GetActiveWorkPeriodUseCase {
  final IWorkPeriodsRepository repository;

  GetActiveWorkPeriodUseCase(this.repository);

  Future<Either<Failure, WorkPeriod?>> call(String employeeId) {
    return repository.getActiveWorkPeriod(employeeId);
  }

  Future<Either<Failure, WorkPeriod?>> getCached(String employeeId) {
    return repository.getCachedActiveWorkPeriod(employeeId);
  }

  Stream<WorkPeriod?> watch(String employeeId) {
    return repository.watchActiveWorkPeriod(employeeId);
  }
}
