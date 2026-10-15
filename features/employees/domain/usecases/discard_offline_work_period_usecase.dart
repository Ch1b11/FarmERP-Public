import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_work_periods_repository.dart';

class DiscardOfflineWorkPeriodUseCase {
  final IWorkPeriodsRepository repository;

  DiscardOfflineWorkPeriodUseCase(this.repository);

  Future<Either<Failure, void>> call(String periodId) {
    return repository.discardOfflineWorkPeriod(periodId);
  }
}
