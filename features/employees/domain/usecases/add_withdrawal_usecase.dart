import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/work_period.dart';
import '../repositories/i_work_periods_repository.dart';

class AddWithdrawalUseCase {
  final IWorkPeriodsRepository repository;

  AddWithdrawalUseCase(this.repository);

  Future<Either<Failure, WorkPeriod>> call({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    return await repository.addWithdrawal(
      periodId: periodId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }
}
