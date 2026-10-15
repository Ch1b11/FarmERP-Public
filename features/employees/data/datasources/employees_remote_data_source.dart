import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/dio_error_parser.dart';
import '../models/employee_model.dart';

abstract class IEmployeesRemoteDataSource {
  Future<List<EmployeeModel>> getEmployees({
    int page = 1,
    int pageSize = 50,
    String? search,
    int? departmentId,
  });
  Future<EmployeeModel> getEmployeeById(String id);
  Future<EmployeeModel> createEmployee(EmployeeModel employee);
  Future<EmployeeModel> updateEmployee(String id, EmployeeModel employee);
  Future<void> deleteEmployee(String id);
  Future<void> deactivateEmployee(String id);
}

class EmployeesRemoteDataSourceImpl implements IEmployeesRemoteDataSource {
  final Dio dio;
  EmployeesRemoteDataSourceImpl({required this.dio});

  static const String _base = '/api/v1/workforce/employees';

  @override
  Future<List<EmployeeModel>> getEmployees({
    int page = 1,
    int pageSize = 50,
    String? search,
    int? departmentId,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        'departmentId': ?departmentId,
      };
      final response = await dio.get(_base, queryParameters: params);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<dynamic> items = data is Map && data['items'] is List
            ? data['items'] as List<dynamic>
            : data is List
            ? data
            : [];
        return items
            .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ServerException('Failed to load employees');
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(e, fallback: 'Failed to fetch employees.'),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final response = await dio.get('$_base/$id');
      if (response.statusCode == 200 && response.data != null) {
        return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Employee not found');
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(e, fallback: 'Failed to fetch employee.'),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    try {
      final response = await dio.post(
        _base,
        data: employee.toJson(forUpdate: false),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Failed to create employee');
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(e, fallback: 'Failed to create employee.'),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<EmployeeModel> updateEmployee(
    String id,
    EmployeeModel employee,
  ) async {
    try {
      final response = await dio.put(
        '$_base/$id',
        data: employee.toJson(forUpdate: true),
      );
      if (response.statusCode == 200 && response.data != null) {
        return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Failed to update employee');
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(e, fallback: 'Failed to update employee.'),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      final response = await dio.delete('$_base/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to delete employee');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(e, fallback: 'Failed to delete employee.'),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deactivateEmployee(String id) async {
    try {
      final response = await dio.patch('$_base/$id/deactivate');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to deactivate employee');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to deactivate employee.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
