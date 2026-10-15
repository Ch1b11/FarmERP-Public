import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';
import '../repositories/i_work_periods_repository.dart';

class CompleteAndSettlePeriodUseCase {
  final IWorkPeriodsRepository repository;

  CompleteAndSettlePeriodUseCase(this.repository);

  Future<Either<Failure, WorkPeriod>> call({
    required String periodId,
    required DateTime departureDate,
    required String accountId,
  }) async {
    return await repository.completeAndSettlePeriod(
      periodId: periodId,
      departureDate: departureDate,
      accountId: accountId,
    );
  }
}
