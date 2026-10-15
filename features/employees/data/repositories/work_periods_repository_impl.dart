import 'dart:convert';

import '../../../../core/di/injection_container.dart';
import '../../../../core/sync/sync_service.dart';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/sync/pending_mutation.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/work_period.dart';
import '../../domain/repositories/i_work_periods_repository.dart';
import '../datasources/work_periods_local_data_source.dart';
import '../datasources/work_periods_remote_data_source.dart';
import '../models/work_period_model.dart';

class WorkPeriodsRepositoryImpl implements IWorkPeriodsRepository {
  final IWorkPeriodsRemoteDataSource remoteDataSource;
  final IWorkPeriodsLocalDataSource localDataSource;
  final INetworkInfo networkInfo;
  final StorageService storageService;
  final SyncService? syncService;
  final Uuid uuid;

  WorkPeriodsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.storageService,
    this.syncService,
    this.uuid = const Uuid(),
  });

  double _getEmployeeDailyWage(String employeeId) {
    try {
      final raw = storageService.employeesBox.get(employeeId);
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final wage = decoded['dailyWage'] ?? decoded['DailyWage'];
        if (wage is num) return wage.toDouble();
        if (wage != null) return double.tryParse(wage.toString()) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  double _calculateWorkedDays(
    DateTime arrivalDate,
    String arrivalTimeType,
    DateTime departureDate,
  ) {
    final arrivalOnly = DateTime(
      arrivalDate.year,
      arrivalDate.month,
      arrivalDate.day,
    );
    final departureOnly = DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
    );
    if (departureOnly.isBefore(arrivalOnly)) return 0.0;
    final daysDiff = departureOnly.difference(arrivalOnly).inDays;
    final adjustment = arrivalTimeType == 'Morning' ? 1.0 : 0.5;
    return daysDiff + adjustment;
  }

  Future<void> _cleanUpSyncedTempWorkPeriods(String employeeId) async {
    try {
      final allLocal = await localDataSource.getAllWorkPeriods();
      for (final c in allLocal) {
        final isForEmp = c.employeeId == employeeId ||
            storageService.getServerId(c.employeeId) == employeeId ||
            storageService.getClientId(c.employeeId) == employeeId;
        if (isForEmp && int.tryParse(c.id) == null) {
          final serverId = storageService.getServerId(c.id);
          if (serverId != null) {
            await localDataSource.deleteCachedWorkPeriod(c.id);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, WorkPeriod?>> getActiveWorkPeriod(
    String employeeId,
  ) async {

    if (int.tryParse(employeeId) == null) {
      final cached = await localDataSource.getActiveWorkPeriod(employeeId);
      return Right(cached);
    }

    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {
        await _cleanUpSyncedTempWorkPeriods(employeeId);
        final remote = await remoteDataSource.getActiveWorkPeriod(employeeId);
        if (remote != null) {
          final clientId = storageService.getClientId(remote.id) ?? remote.id;

          final cachedById =
              await localDataSource.getWorkPeriodById(remote.id) ??
              await localDataSource.getWorkPeriodById(clientId);
          if (cachedById != null &&
              cachedById.departureDate != null &&
              !cachedById.isSynced) {
            return const Right(null);
          }

          final allLocal = await localDataSource.getAllWorkPeriods();
          final isCompletedLocally = allLocal.any(
            (p) =>
                p.employeeId == employeeId &&
                (p.id == remote.id || p.id == clientId) &&
                p.departureDate != null &&
                !p.isSynced,
          );
          if (isCompletedLocally) {
            return const Right(null);
          }

          final cached = await localDataSource.getActiveWorkPeriod(employeeId);
          if (cached != null && cached.departureDate != null) {
            return const Right(null);
          }

          final hasPendingFinancials =
              cached != null &&
              (!cached.isSynced ||
                  cached.totalBonuses > remote.totalBonuses ||
                  cached.totalWithdrawals > remote.totalWithdrawals);

          final effectiveBonuses =
              (hasPendingFinancials &&
                  cached.totalBonuses > remote.totalBonuses)
              ? cached.totalBonuses
              : remote.totalBonuses;
          final effectiveWithdrawals =
              (hasPendingFinancials &&
                  cached.totalWithdrawals > remote.totalWithdrawals)
              ? cached.totalWithdrawals
              : remote.totalWithdrawals;
          final effectiveTotalSalary =
              remote.totalSalary ??
              ((remote.totalWorkedDays ?? cached?.totalWorkedDays ?? 0.0) *
                  remote.dailyWage);
          final effectiveFinalSalary =
              remote.finalSalary ??
              (effectiveTotalSalary - effectiveWithdrawals + effectiveBonuses);

          final merged = WorkPeriodModel.fromEntity(
            remote.copyWith(
              totalBonuses: effectiveBonuses,
              totalWithdrawals: effectiveWithdrawals,
              totalSalary: effectiveTotalSalary,
              finalSalary: effectiveFinalSalary,
              isSynced:
                  (hasPendingFinancials &&
                      (effectiveBonuses > remote.totalBonuses ||
                          effectiveWithdrawals > remote.totalWithdrawals))
                  ? false
                  : true,
            ),
          );
          await localDataSource.cacheWorkPeriod(merged);
          return Right(merged);
        } else {

          final cached = await localDataSource.getActiveWorkPeriod(employeeId);
          if (cached != null &&
              !cached.isSynced &&
              cached.departureDate == null) {
            return Right(cached);
          }
          return const Right(null);
        }
      } catch (_) {
        final cached = await localDataSource.getActiveWorkPeriod(employeeId);
        return Right(cached);
      }
    } else {
      final cached = await localDataSource.getActiveWorkPeriod(employeeId);
      return Right(cached);
    }
  }

  @override
  Future<Either<Failure, WorkPeriod?>> getCachedActiveWorkPeriod(
    String employeeId,
  ) async {
    try {
      final cached = await localDataSource.getActiveWorkPeriod(employeeId);
      return Right(cached);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkPeriod>> startWorkPeriod({
    required String employeeId,
    required DateTime arrivalDate,
    required String arrivalTimeType,
  }) async {
    final tempId = uuid.v4();
    final initialWage = _getEmployeeDailyWage(employeeId);
    final optimistic = WorkPeriodModel(
      id: tempId,
      employeeId: employeeId,
      arrivalDate: arrivalDate,
      arrivalTimeType: arrivalTimeType,
      departureDate: null,
      dailyWage: initialWage,
      isSynced: false,
    );

    final resolvedEmployeeId =
        storageService.getServerId(employeeId) ?? employeeId;
    final payload = optimistic.toJson();
    payload['employeeId'] =
        int.tryParse(resolvedEmployeeId) ?? resolvedEmployeeId;

    await _queueMutation(
      method: HttpMethod.post,
      endpoint:
          '/api/v1/workforce/employees/$resolvedEmployeeId/work-periods/start',
      payload: payload,
      tempId: tempId,
    );
    await localDataSource.cacheWorkPeriod(optimistic);
    return Right(optimistic);
  }

  int _getDefaultFinancialAccountId() {
    try {
      final box = storageService.financeAccountsBox;
      int? defaultId;
      int? firstValidId;

      for (final raw in box.values) {
        try {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          final rawId = decoded['id'] ?? decoded['Id'];
          final id = rawId is int
              ? rawId
              : int.tryParse(rawId?.toString() ?? '');
          final isDefault =
              decoded['isDefault'] as bool? ??
              decoded['IsDefault'] as bool? ??
              false;
          final active =
              decoded['active'] as bool? ?? decoded['Active'] as bool? ?? true;

          if (id != null && id > 0 && active) {
            firstValidId ??= id;
            if (isDefault) {
              defaultId = id;
              break;
            }
          }
        } catch (_) {}
      }

      return defaultId ?? firstValidId ?? 1;
    } catch (_) {
      return 1;
    }
  }

  @override
  Future<Either<Failure, WorkPeriod>> addWithdrawal({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final clientId = storageService.getClientId(periodId) ?? periodId;
    final serverId = storageService.getServerId(periodId) ?? periodId;

    final cached =
        await localDataSource.getWorkPeriodById(periodId) ??
        await localDataSource.getWorkPeriodById(clientId) ??
        await localDataSource.getWorkPeriodById(serverId);

    WorkPeriodModel? updated;
    if (cached != null) {
      final newWithdrawals = cached.totalWithdrawals + amount;
      final newTotalSalary =
          cached.totalSalary ??
          (cached.totalWorkedDays ?? 0.0) * cached.dailyWage;
      final newFinalSalary =
          newTotalSalary - newWithdrawals + cached.totalBonuses;
      updated = WorkPeriodModel.fromEntity(
        cached.copyWith(
          totalWithdrawals: newWithdrawals,
          finalSalary: newFinalSalary,
          isSynced: false,
        ),
      );
    }

    final resolvedPeriodId = storageService.getServerId(periodId) ?? periodId;
    final accountIntId = _getDefaultFinancialAccountId();

    final mutationPayload = {
      'date': DateFormatter.toApiUtcIso8601String(date),
      'amount': amount,
      'financialAccountId': accountIntId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    await _queueMutation(
      method: HttpMethod.post,
      endpoint: '/api/v1/workforce/work-periods/$resolvedPeriodId/withdrawals',
      payload: mutationPayload,
      parentId: periodId,
    );
    if (updated != null) {
      await localDataSource.cacheWorkPeriod(updated);
      syncService?.processQueue();
      return Right(updated);
    }
    syncService?.processQueue();
    return const Left(CacheFailure('Work period not found in local cache'));
  }

  @override
  Future<Either<Failure, WorkPeriod>> addBonus({
    required String periodId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final clientId = storageService.getClientId(periodId) ?? periodId;
    final serverId = storageService.getServerId(periodId) ?? periodId;

    final cached =
        await localDataSource.getWorkPeriodById(periodId) ??
        await localDataSource.getWorkPeriodById(clientId) ??
        await localDataSource.getWorkPeriodById(serverId);

    WorkPeriodModel? updated;
    if (cached != null) {
      final newBonuses = cached.totalBonuses + amount;
      final newTotalSalary =
          cached.totalSalary ??
          (cached.totalWorkedDays ?? 0.0) * cached.dailyWage;
      final newFinalSalary =
          newTotalSalary - cached.totalWithdrawals + newBonuses;
      updated = WorkPeriodModel.fromEntity(
        cached.copyWith(
          totalBonuses: newBonuses,
          finalSalary: newFinalSalary,
          isSynced: false,
        ),
      );
    }

    final resolvedPeriodId = storageService.getServerId(periodId) ?? periodId;

    final mutationPayload = {
      'date': DateFormatter.toApiUtcIso8601String(date),
      'amount': amount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    await _queueMutation(
      method: HttpMethod.post,
      endpoint: '/api/v1/workforce/work-periods/$resolvedPeriodId/bonuses',
      payload: mutationPayload,
      parentId: periodId,
    );
    if (updated != null) {
      await localDataSource.cacheWorkPeriod(updated);
      syncService?.processQueue();
      return Right(updated);
    }
    syncService?.processQueue();
    return const Left(CacheFailure('Work period not found in local cache'));
  }

  @override
  Future<Either<Failure, WorkPeriod>> completeAndSettlePeriod({
    required String periodId,
    required DateTime departureDate,
    required String accountId,
  }) async {
    final clientId = storageService.getClientId(periodId) ?? periodId;
    final serverId = storageService.getServerId(periodId) ?? periodId;

    var cached =
        await localDataSource.getWorkPeriodById(periodId) ??
        await localDataSource.getWorkPeriodById(clientId) ??
        await localDataSource.getWorkPeriodById(serverId);

    if (cached == null) {
      final allLocal = await localDataSource.getAllWorkPeriods();
      for (final p in allLocal) {
        if (p.id == periodId || p.id == clientId || p.id == serverId) {
          cached = p;
          break;
        }
      }
    }

    final totalWithdrawals = cached?.totalWithdrawals ?? 0.0;
    final totalBonuses = cached?.totalBonuses ?? 0.0;

    double workedDays = cached?.totalWorkedDays ?? 0.0;
    if ((workedDays == 0.0 || workedDays.isNaN) && cached != null) {
      workedDays = _calculateWorkedDays(
        cached.arrivalDate,
        cached.arrivalTimeType,
        departureDate,
      );
    }

    var dailyWage = cached?.dailyWage ?? 0.0;
    if (dailyWage == 0.0 && cached != null) {
      dailyWage = _getEmployeeDailyWage(cached.employeeId);
    }

    final totalSalary = workedDays * dailyWage;

    final finalSalary = totalSalary - totalWithdrawals + totalBonuses;

    final updated = WorkPeriodModel(
      id: cached?.id ?? periodId,
      employeeId: cached?.employeeId ?? '',
      arrivalDate: cached?.arrivalDate ?? DateTime.now(),
      arrivalTimeType: cached?.arrivalTimeType ?? 'Morning',
      departureDate: departureDate,
      dailyWage: dailyWage,
      totalWithdrawals: totalWithdrawals,
      totalBonuses: totalBonuses,
      totalWorkedDays: workedDays,
      totalSalary: totalSalary,
      finalSalary: finalSalary,
      isSynced: false,
    );

    final resolvedPeriodId = storageService.getServerId(periodId) ?? periodId;

    await _queueMutation(
      method: HttpMethod.post,
      endpoint: '/api/v1/workforce/work-periods/$resolvedPeriodId/complete',
      payload: {
        'departureDate': DateFormatter.toApiUtcIso8601String(departureDate),
      },
      parentId: periodId,
    );

    var accountIntId = int.tryParse(accountId);
    if (accountIntId == null || accountIntId <= 0) {
      accountIntId = _getDefaultFinancialAccountId();
    }

    await _queueMutation(
      method: HttpMethod.post,
      endpoint: '/api/v1/workforce/work-periods/$resolvedPeriodId/settle',
      payload: {
        'financialAccountId': accountIntId,
        'notes': 'Settlement on completion',
      },
      parentId: periodId,
    );

    await localDataSource.cacheWorkPeriod(updated);
    syncService?.processQueue();
    return Right(updated);
  }

  @override
  Future<Either<Failure, List<WorkPeriod>>> getWorkPeriodHistory(
    String employeeId,
  ) async {

    if (int.tryParse(employeeId) == null) {
      final cached = await localDataSource.getWorkPeriodHistory(employeeId);
      return Right(cached);
    }

    final isOnline = await networkInfo.isConnected;
    if (isOnline) {
      try {
        final remote = await remoteDataSource.getWorkPeriodHistory(employeeId);
        final mergedList = <WorkPeriod>[];

        for (final period in remote) {
          final cached = await localDataSource.getWorkPeriodById(period.id);
          final hasPendingFinancials =
              cached != null &&
              (!cached.isSynced ||
                  cached.totalBonuses > period.totalBonuses ||
                  cached.totalWithdrawals > period.totalWithdrawals);

          final effectiveWorkedDays =
              (cached != null &&
                  !cached.isSynced &&
                  (cached.totalWorkedDays ?? 0) > 0)
              ? cached.totalWorkedDays
              : (period.totalWorkedDays ?? cached?.totalWorkedDays);

          final effectiveDailyWage =
              (cached != null && !cached.isSynced && cached.dailyWage > 0)
              ? cached.dailyWage
              : (period.dailyWage > 0
                    ? period.dailyWage
                    : (cached?.dailyWage ?? _getEmployeeDailyWage(employeeId)));

          final effectiveBonuses =
              (hasPendingFinancials &&
                  cached.totalBonuses > period.totalBonuses)
              ? cached.totalBonuses
              : period.totalBonuses;
          final effectiveWithdrawals =
              (hasPendingFinancials &&
                  cached.totalWithdrawals > period.totalWithdrawals)
              ? cached.totalWithdrawals
              : period.totalWithdrawals;

          final effectiveTotalSalary =
              (cached != null &&
                  !cached.isSynced &&
                  cached.totalSalary != null &&
                  cached.totalSalary! > 0)
              ? cached.totalSalary!
              : (period.totalSalary ??
                    ((effectiveWorkedDays ?? 0.0) * effectiveDailyWage));

          final effectiveFinalSalary =
              (cached != null && !cached.isSynced && cached.finalSalary != null)
              ? cached.finalSalary!
              : (period.finalSalary ??
                    (effectiveTotalSalary -
                        effectiveWithdrawals +
                        effectiveBonuses));

          final isPeriodSynced =
              !(hasPendingFinancials || (cached != null && !cached.isSynced));

          final merged = WorkPeriodModel.fromEntity(
            period.copyWith(
              departureDate: period.departureDate ?? cached?.departureDate,
              totalWorkedDays: effectiveWorkedDays,
              dailyWage: effectiveDailyWage,
              totalBonuses: effectiveBonuses,
              totalWithdrawals: effectiveWithdrawals,
              totalSalary: effectiveTotalSalary,
              finalSalary: effectiveFinalSalary,
              isSynced: isPeriodSynced,
            ),
          );
          mergedList.add(merged);
        }

        await _cleanUpSyncedTempWorkPeriods(employeeId);

        final allLocal = await localDataSource.getAllWorkPeriods();
        final remoteIds = remote.map((p) => p.id).toSet();
        for (final p in remote) {
          final clientId = storageService.getClientId(p.id);
          if (clientId != null) remoteIds.add(clientId);
        }

        for (final c in allLocal) {
          final isForEmployee = c.employeeId == employeeId ||
              storageService.getServerId(c.employeeId) == employeeId ||
              storageService.getClientId(c.employeeId) == employeeId;
          if (!isForEmployee || c.departureDate == null) {
            continue;
          }

          final serverId = storageService.getServerId(c.id);
          if (remoteIds.contains(c.id) ||
              (serverId != null && remoteIds.contains(serverId))) {
            if (int.tryParse(c.id) == null) {
              await localDataSource.deleteCachedWorkPeriod(c.id);
            }
            continue;
          }

          if (c.isSynced) {
            await localDataSource.deleteCachedWorkPeriod(c.id);
            continue;
          }

          final isDuplicateInRemote = remote.any((r) =>
              r.arrivalDate.isAtSameMomentAs(c.arrivalDate) &&
              r.departureDate != null &&
              r.departureDate!.isAtSameMomentAs(c.departureDate!));
          if (isDuplicateInRemote) {
            if (int.tryParse(c.id) == null) {
              await localDataSource.deleteCachedWorkPeriod(c.id);
            }
            continue;
          }

          var workedDays = c.totalWorkedDays ?? 0.0;
          if (workedDays == 0.0) {
            workedDays = _calculateWorkedDays(
              c.arrivalDate,
              c.arrivalTimeType,
              c.departureDate!,
            );
          }
          var dailyWage = c.dailyWage;
          if (dailyWage == 0.0) {
            dailyWage = _getEmployeeDailyWage(employeeId);
          }
          final totalSalary = (c.totalSalary != null && c.totalSalary! > 0)
              ? c.totalSalary!
              : (workedDays * dailyWage);
          final finalSalary = (c.finalSalary != null && c.finalSalary! != 0.0)
              ? c.finalSalary!
              : (totalSalary - c.totalWithdrawals + c.totalBonuses);
          final completeModel = WorkPeriodModel.fromEntity(
            c.copyWith(
              totalWorkedDays: workedDays,
              dailyWage: dailyWage,
              totalSalary: totalSalary,
              finalSalary: finalSalary,
            ),
          );
          mergedList.add(completeModel);
        }

        final modelsToCache = mergedList
            .map((p) => p is WorkPeriodModel ? p : WorkPeriodModel.fromEntity(p))
            .toList();
        await localDataSource.cacheWorkPeriods(
          modelsToCache,
          employeeId: employeeId,
        );

        mergedList.sort((a, b) => b.arrivalDate.compareTo(a.arrivalDate));
        return Right(mergedList);
      } catch (_) {
        final cached = await localDataSource.getWorkPeriodHistory(employeeId);
        return Right(cached);
      }
    } else {
      final cached = await localDataSource.getWorkPeriodHistory(employeeId);
      return Right(cached);
    }
  }

  @override
  Future<Either<Failure, List<WorkPeriod>>> getCachedWorkPeriodHistory(
    String employeeId,
  ) async {
    try {
      final cached = await localDataSource.getWorkPeriodHistory(employeeId);
      return Right(cached);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> discardOfflineWorkPeriod(
    String periodId,
  ) async {
    try {
      await localDataSource.deleteCachedWorkPeriod(periodId);

      final entries = storageService.getMutationsFifo();
      for (final entry in entries) {
        try {
          final decoded = json.decode(entry.value) as Map<String, dynamic>;
          final pId = decoded['parentId']?.toString();
          final tId = decoded['tempId']?.toString();
          final ep = decoded['endpoint']?.toString() ?? '';

          if (pId == periodId ||
              tId == periodId ||
              ep.contains('/$periodId/')) {
            await storageService.removeMutationAt(entry.key);
          }
        } catch (_) {}
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<WorkPeriod>> watchWorkPeriods() {
    return localDataSource.watchWorkPeriods().map((models) => models.toList());
  }

  @override
  Stream<List<WorkPeriod>> watchWorkPeriodHistory(String employeeId) {
    return localDataSource
        .watchWorkPeriodHistory(employeeId)
        .map((models) => models.toList());
  }

  @override
  Stream<WorkPeriod?> watchActiveWorkPeriod(String employeeId) {
    return localDataSource.watchActiveWorkPeriod(employeeId);
  }

  Future<void> _queueMutation({
    required HttpMethod method,
    required String endpoint,
    Map<String, dynamic>? payload,
    String? tempId,
    String? parentId,
  }) async {
    final mutation = PendingMutation(
      id: uuid.v4(),
      method: method,
      endpoint: endpoint,
      payload: payload,
      timestamp: DateTime.now(),
      tempId: tempId,
      parentId: parentId,
      collection: 'work_periods',
    );
    await storageService.addMutation(
      mutation.id,
      json.encode(mutation.toJson()),
    );
    final sync =
        syncService ??
        (sl.isRegistered<SyncService>() ? sl<SyncService>() : null);
    sync?.processQueue();
  }
}
