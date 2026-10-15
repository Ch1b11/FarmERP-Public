import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dio_error_parser.dart';
import '../models/work_period_model.dart';

abstract class IWorkPeriodsRemoteDataSource {
  Future<WorkPeriodModel?> getActiveWorkPeriod(String employeeId);
  Future<WorkPeriodModel> startWorkPeriod({
    required String employeeId,
    required DateTime arrivalDate,
    required String arrivalTimeType,
  });
  Future<void> createWithdrawal({
    required String periodId,
    required double amount,
    required DateTime date,
    int financialAccountId = 1,
    String? notes,
  });
  Future<void> createBonus({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  });
  Future<WorkPeriodModel> completeWorkPeriod({
    required String periodId,
    required DateTime departureDate,
  });
  Future<void> settleWorkPeriod({
    required String periodId,
    int financialAccountId = 1,
    String? notes,
  });
  Future<List<WorkPeriodModel>> getWorkPeriodHistory(String employeeId);
}

class WorkPeriodsRemoteDataSourceImpl implements IWorkPeriodsRemoteDataSource {
  final Dio dio;

  WorkPeriodsRemoteDataSourceImpl({required this.dio});

  static const String _baseEmployees = '/api/v1/workforce/employees';
  static const String _basePeriods = '/api/v1/workforce/work-periods';

  @override
  Future<WorkPeriodModel?> getActiveWorkPeriod(String employeeId) async {
    try {
      final response = await dio.get(
        '$_baseEmployees/$employeeId/work-periods/active',
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 300 || status == 404),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return WorkPeriodModel.fromJson(response.data as Map<String, dynamic>);
      }
      if (response.statusCode == 404) {

        return null;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 ||
          e.message?.contains('404') == true) {

        return null;
      }
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to fetch active work period.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<WorkPeriodModel> startWorkPeriod({
    required String employeeId,
    required DateTime arrivalDate,
    required String arrivalTimeType,
  }) async {
    try {
      final response = await dio.post(
        '$_baseEmployees/$employeeId/work-periods/start',
        data: {
          'arrivalDate': DateFormatter.toApiUtcIso8601String(arrivalDate),
          'arrivalTimeType': arrivalTimeType,
          'employeeId': int.tryParse(employeeId) ?? employeeId,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return WorkPeriodModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to start work period');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to start work period.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createWithdrawal({
    required String periodId,
    required double amount,
    required DateTime date,
    int financialAccountId = 1,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '$_basePeriods/$periodId/withdrawals',
        data: {
          'date': DateFormatter.toApiUtcIso8601String(date),
          'amount': amount,
          'financialAccountId': financialAccountId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Failed to record withdrawal');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to record withdrawal.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createBonus({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '$_basePeriods/$periodId/bonuses',
        data: {
          'date': DateFormatter.toApiUtcIso8601String(date),
          'amount': amount,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Failed to record bonus');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(e, fallback: 'Failed to record bonus.'),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<WorkPeriodModel> completeWorkPeriod({
    required String periodId,
    required DateTime departureDate,
  }) async {
    try {
      final response = await dio.post(
        '$_basePeriods/$periodId/complete',
        data: {
          'departureDate': DateFormatter.toApiUtcIso8601String(departureDate),
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return WorkPeriodModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to complete work period');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to complete work period.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> settleWorkPeriod({
    required String periodId,
    int financialAccountId = 1,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '$_basePeriods/$periodId/settle',
        data: {
          'financialAccountId': financialAccountId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to settle work period');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to settle work period.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<WorkPeriodModel>> getWorkPeriodHistory(String employeeId) async {
    try {
      final response = await dio.get(
        '$_baseEmployees/$employeeId/work-periods',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items;
        if (data is Map && data['items'] is List) {
          items = data['items'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }
        final list = items
            .map((e) => WorkPeriodModel.fromJson(e as Map<String, dynamic>))
            .where((model) => model.departureDate != null)
            .toList();
        list.sort((a, b) => b.arrivalDate.compareTo(a.arrivalDate));
        return list;
      } else {
        throw ServerException('Failed to load work period history');
      }
    } on DioException catch (e) {
      throw ServerException(
        DioErrorParser.parseMessage(
          e,
          fallback: 'Failed to fetch work period history.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
