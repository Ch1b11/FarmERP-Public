import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_employees_repository.dart';

class DeactivateEmployeeUseCase {
  final IEmployeesRepository repository;

  DeactivateEmployeeUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deactivateEmployee(id);
  }
}
