import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/employee.dart';
import '../repositories/i_employees_repository.dart';

class CreateEmployeeUseCase {
  final IEmployeesRepository repository;
  CreateEmployeeUseCase(this.repository);

  Future<Either<Failure, Employee>> call({
    required String firstName,
    String? middleName,
    required String lastName,
    String? nationalId,
    String? mobileNumber,
    String? jobTitle,
    String? departmentId,
    required double dailyWage,
  }) => repository.createEmployee(
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    nationalId: nationalId,
    mobileNumber: mobileNumber,
    jobTitle: jobTitle,
    departmentId: departmentId,
    dailyWage: dailyWage,
  );
}
