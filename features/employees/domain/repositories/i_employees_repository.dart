import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/department.dart';
import '../entities/employee.dart';

abstract class IEmployeesRepository {
  Future<Either<Failure, List<Employee>>> getEmployees({
    String? search,
    String? departmentId,
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<Employee>>> getCachedEmployees();

  Future<Either<Failure, Employee>> getEmployeeById(String id);

  Future<Either<Failure, Employee?>> getCachedEmployeeById(String id);

  Future<Either<Failure, Employee>> createEmployee({
    required String firstName,
    String? middleName,
    required String lastName,
    String? nationalId,
    String? mobileNumber,
    String? jobTitle,
    String? departmentId,
    required double dailyWage,
  });

  Future<Either<Failure, Employee>> updateEmployee({
    required String id,
    required String firstName,
    String? middleName,
    required String lastName,
    String? nationalId,
    String? mobileNumber,
    String? jobTitle,
    String? departmentId,
    required double dailyWage,
  });

  Future<Either<Failure, void>> deleteEmployee(String id);

  Future<Either<Failure, void>> deactivateEmployee(String id);

  Future<Either<Failure, List<Department>>> getDepartments();

  Stream<List<Employee>> watchEmployees();
}
