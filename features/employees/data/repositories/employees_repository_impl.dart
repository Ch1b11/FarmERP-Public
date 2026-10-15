import 'dart:convert';

import '../../../../core/di/injection_container.dart';
import '../../../../core/sync/sync_service.dart';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/sync/pending_mutation.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/i_employees_repository.dart';
import '../datasources/departments_local_data_source.dart';
import '../datasources/departments_remote_data_source.dart';
import '../datasources/employees_local_data_source.dart';
import '../datasources/employees_remote_data_source.dart';
import '../models/employee_model.dart';

class EmployeesRepositoryImpl implements IEmployeesRepository {
  final IEmployeesRemoteDataSource remoteDataSource;
  final IEmployeesLocalDataSource localDataSource;
  final IDepartmentsRemoteDataSource deptRemoteDataSource;
  final IDepartmentsLocalDataSource deptLocalDataSource;
  final INetworkInfo networkInfo;
  final StorageService storageService;
  final SyncService? syncService;
  final Uuid uuid;

  EmployeesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.deptRemoteDataSource,
    required this.deptLocalDataSource,
    required this.networkInfo,
    required this.storageService,
    this.syncService,
    this.uuid = const Uuid(),
  });

  @override
  Future<Either<Failure, List<Employee>>> getEmployees({
    String? search,
    String? departmentId,
    bool forceRefresh = false,
  }) async {
    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {

        final allRemote = <EmployeeModel>[];
        int page = 1;
        const pageSize = 50;
        while (true) {
          final batch = await remoteDataSource.getEmployees(
            page: page,
            pageSize: pageSize,
            search: search,
            departmentId: departmentId != null
                ? int.tryParse(departmentId)
                : null,
          );
          allRemote.addAll(batch);
          if (batch.length < pageSize) break;
          page++;
        }

        if (search == null && departmentId == null) {
          await localDataSource.cacheEmployees(allRemote);
          return Right(await localDataSource.getCachedEmployees());
        } else {
          for (final emp in allRemote) {
            await localDataSource.cacheEmployee(emp);
          }
          final cached = await localDataSource.getCachedEmployees();
          final lower = search?.toLowerCase();
          return Right(
            cached.where((e) {
              final matchesSearch =
                  lower == null ||
                  lower.isEmpty ||
                  e.fullName.toLowerCase().contains(lower) ||
                  (e.jobTitle?.toLowerCase().contains(lower) ?? false);
              final matchesDept =
                  departmentId == null || e.departmentId == departmentId;
              return matchesSearch && matchesDept;
            }).toList(),
          );
        }
      } catch (e) {
        final cached = await localDataSource.getCachedEmployees();
        if (cached.isNotEmpty) return Right(cached);
        if (e is ServerException) return Left(ServerFailure(e.message));
        return Left(ServerFailure(e.toString()));
      }
    } else {
      final cached = await localDataSource.getCachedEmployees();
      if (search != null && search.isNotEmpty) {
        final lower = search.toLowerCase();
        return Right(
          cached
              .where(
                (e) =>
                    e.fullName.toLowerCase().contains(lower) ||
                    (e.jobTitle?.toLowerCase().contains(lower) ?? false),
              )
              .toList(),
        );
      }
      if (departmentId != null) {
        return Right(
          cached.where((e) => e.departmentId == departmentId).toList(),
        );
      }
      return Right(cached);
    }
  }

  @override
  Future<Either<Failure, List<Employee>>> getCachedEmployees() async {
    try {
      return Right(await localDataSource.getCachedEmployees());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Employee>> getEmployeeById(String id) async {
    final cached = await localDataSource.getCachedEmployeeById(id);

    if (int.tryParse(id) == null) {
      if (cached != null) return Right(cached);
      return const Left(CacheFailure('Employee not found in local cache'));
    }

    final isOnline = await networkInfo.isConnected;
    if (isOnline) {
      try {
        final remote = await remoteDataSource.getEmployeeById(id);
        await localDataSource.cacheEmployee(remote);
        return Right(remote);
      } catch (e) {
        if (cached != null) return Right(cached);
        if (e is ServerException) return Left(ServerFailure(e.message));
        return Left(ServerFailure(e.toString()));
      }
    } else {
      if (cached != null) return Right(cached);
      return const Left(CacheFailure('Employee not found in local cache'));
    }
  }

  @override
  Future<Either<Failure, Employee?>> getCachedEmployeeById(String id) async {
    try {
      final cached = await localDataSource.getCachedEmployeeById(id);
      return Right(cached);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  static final RegExp _uuidPattern = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  @override
  Future<Either<Failure, Employee>> createEmployee({
    required String firstName,
    String? middleName,
    required String lastName,
    String? nationalId,
    String? mobileNumber,
    String? jobTitle,
    String? departmentId,
    required double dailyWage,
  }) async {
    final tempId = uuid.v4();
    final computedFullName = (middleName != null && middleName.isNotEmpty)
        ? '$firstName $middleName $lastName'.trim()
        : '$firstName $lastName'.trim();
    final resolvedDeptId = (departmentId != null && departmentId.isNotEmpty)
        ? (storageService.getServerId(departmentId) ?? departmentId)
        : departmentId;

    final optimistic = EmployeeModel(
      id: tempId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      fullName: computedFullName,
      nationalId: nationalId,
      mobileNumber: mobileNumber,
      jobTitle: jobTitle,
      departmentId: resolvedDeptId,
      dailyWage: dailyWage,
      isSynced: false,
    );

    await localDataSource.cacheEmployee(optimistic);

    await _queueMutation(
      method: HttpMethod.post,
      endpoint: '/api/v1/workforce/employees',
      payload: optimistic.toJson(),
      tempId: tempId,
    );

    return Right(optimistic);
  }

  @override
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
  }) async {
    final computedFullName = (middleName != null && middleName.isNotEmpty)
        ? '$firstName $middleName $lastName'.trim()
        : '$firstName $lastName'.trim();
    final resolvedDeptId = (departmentId != null && departmentId.isNotEmpty)
        ? (storageService.getServerId(departmentId) ?? departmentId)
        : departmentId;

    final cached = await localDataSource.getCachedEmployeeById(id);

    final optimistic = EmployeeModel(
      id: id,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      fullName: computedFullName,
      nationalId: nationalId,
      mobileNumber: mobileNumber,
      jobTitle: jobTitle,
      departmentId: resolvedDeptId,
      departmentName: cached?.departmentName,
      dailyWage: dailyWage,
      isActive: cached?.isActive ?? true,
      isSynced: false,
    );

    await localDataSource.cacheEmployee(optimistic);

    final resolvedId = storageService.getServerId(id) ?? id;
    await _queueMutation(
      method: HttpMethod.put,
      endpoint: '/api/v1/workforce/employees/$resolvedId',
      payload: optimistic.toJson(forUpdate: true),
    );

    return Right(optimistic);
  }

  @override
  Future<Either<Failure, void>> deleteEmployee(String id) async {

    await localDataSource.deleteCachedEmployee(id);

    final entries = storageService.getMutationsFifo();
    bool hasPurgedCreation = false;
    for (final entry in entries) {
      try {
        final map = json.decode(entry.value) as Map<String, dynamic>;
        final isMatch = map['tempId'] == id ||
            (entry.value.contains(id) &&
                map['method']?.toString().toLowerCase().contains('post') ==
                    true);
        if (isMatch) {
          await storageService.removeMutationAt(entry.key);
          hasPurgedCreation = true;
        }
      } catch (_) {}
    }

    final isUnsyncedTempUuid = hasPurgedCreation ||
        (_uuidPattern.hasMatch(id) && storageService.getServerId(id) == null);

    if (!isUnsyncedTempUuid) {
      final resolvedId = storageService.getServerId(id) ?? id;
      await _queueMutation(
        method: HttpMethod.delete,
        endpoint: '/api/v1/workforce/employees/$resolvedId',
      );
    }

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deactivateEmployee(String id) async {
    final cached = await localDataSource.getCachedEmployeeById(id);
    if (cached != null) {
      final updated = EmployeeModel.fromEntity(
        cached.copyWith(isActive: false, isSynced: false),
      );
      await localDataSource.cacheEmployee(updated);
    }
    final resolvedId = storageService.getServerId(id) ?? id;
    await _queueMutation(
      method: HttpMethod.patch,
      endpoint: '/api/v1/workforce/employees/$resolvedId/deactivate',
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Department>>> getDepartments() async {
    final isOnline = await networkInfo.isConnected;
    if (isOnline) {
      try {
        final remote = await deptRemoteDataSource.getDepartments();
        await deptLocalDataSource.cacheDepartments(remote);
        return Right(remote);
      } catch (_) {
        return Right(await deptLocalDataSource.getCachedDepartments());
      }
    } else {
      return Right(await deptLocalDataSource.getCachedDepartments());
    }
  }

  @override
  Stream<List<Employee>> watchEmployees() {
    return localDataSource.watchEmployees().map((models) => models.toList());
  }

  Future<void> _queueMutation({
    required HttpMethod method,
    required String endpoint,
    Map<String, dynamic>? payload,
    String? tempId,
  }) async {
    final mutation = PendingMutation(
      id: uuid.v4(),
      method: method,
      endpoint: endpoint,
      payload: payload,
      timestamp: DateTime.now().toUtc(),
      tempId: tempId,
      collection: 'employees',
      farmId: storageService.activeFarmId,
    );
    await storageService.addMutation(
      mutation.id,
      json.encode(mutation.toJson()),
    );
    final sync =
        syncService ??
        (sl.isRegistered<SyncService>() ? sl<SyncService>() : null);
    if (await networkInfo.isConnected) {
      sync?.processQueue();
    }
  }
}
