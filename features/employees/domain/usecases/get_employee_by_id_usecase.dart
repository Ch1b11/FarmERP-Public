import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/employee.dart';
import '../repositories/i_employees_repository.dart';

class GetEmployeeByIdUseCase {
  final IEmployeesRepository repository;
  GetEmployeeByIdUseCase(this.repository);

  Future<Either<Failure, Employee>> call(String id) =>
      repository.getEmployeeById(id);

  Future<Either<Failure, Employee?>> getCached(String id) =>
      repository.getCachedEmployeeById(id);
}
