import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';
import '../repositories/i_work_periods_repository.dart';

class AddBonusUseCase {
  final IWorkPeriodsRepository repository;

  AddBonusUseCase(this.repository);

  Future<Either<Failure, WorkPeriod>> call({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    return await repository.addBonus(
      periodId: periodId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }
}
