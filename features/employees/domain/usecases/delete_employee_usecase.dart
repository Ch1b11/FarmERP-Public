import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_employees_repository.dart';

class DeleteEmployeeUseCase {
  final IEmployeesRepository repository;
  DeleteEmployeeUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.deleteEmployee(id);
}
