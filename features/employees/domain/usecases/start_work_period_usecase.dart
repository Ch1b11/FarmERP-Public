import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';
import '../repositories/i_work_periods_repository.dart';

class StartWorkPeriodUseCase {
  final IWorkPeriodsRepository repository;

  StartWorkPeriodUseCase(this.repository);

  Future<Either<Failure, WorkPeriod>> call({
    required String employeeId,
    required DateTime arrivalDate,
    required String arrivalTimeType,
  }) {
    return repository.startWorkPeriod(
      employeeId: employeeId,
      arrivalDate: arrivalDate,
      arrivalTimeType: arrivalTimeType,
    );
  }
}
