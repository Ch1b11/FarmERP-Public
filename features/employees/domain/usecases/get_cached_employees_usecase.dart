import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/employee.dart';
import '../repositories/i_employees_repository.dart';

class GetCachedEmployeesUseCase {
  final IEmployeesRepository repository;
  GetCachedEmployeesUseCase(this.repository);

  Future<Either<Failure, List<Employee>>> call() =>
      repository.getCachedEmployees();
}
