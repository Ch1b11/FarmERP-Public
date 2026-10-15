import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/employee.dart';
import '../repositories/i_employees_repository.dart';

class GetEmployeesUseCase {
  final IEmployeesRepository repository;
  GetEmployeesUseCase(this.repository);

  Future<Either<Failure, List<Employee>>> call({
    String? search,
    String? departmentId,
    bool forceRefresh = false,
  }) => repository.getEmployees(
    search: search,
    departmentId: departmentId,
    forceRefresh: forceRefresh,
  );

  Future<Either<Failure, List<Employee>>> getCachedEmployees() =>
      repository.getCachedEmployees();
}
