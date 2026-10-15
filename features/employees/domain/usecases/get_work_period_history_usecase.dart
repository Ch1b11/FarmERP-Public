import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';
import '../repositories/i_work_periods_repository.dart';

class GetWorkPeriodHistoryUseCase {
  final IWorkPeriodsRepository repository;

  GetWorkPeriodHistoryUseCase(this.repository);

  Future<Either<Failure, List<WorkPeriod>>> call(String employeeId) async {
    return await repository.getWorkPeriodHistory(employeeId);
  }

  Future<Either<Failure, List<WorkPeriod>>> getCached(String employeeId) async {
    return await repository.getCachedWorkPeriodHistory(employeeId);
  }

  Stream<List<WorkPeriod>> watch(String employeeId) {
    return repository.watchWorkPeriodHistory(employeeId);
  }
}
