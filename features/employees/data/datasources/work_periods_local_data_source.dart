import 'dart:convert';

import '../../../../core/services/storage_service.dart';
import '../models/work_period_model.dart';

abstract class IWorkPeriodsLocalDataSource {
  Future<WorkPeriodModel?> getActiveWorkPeriod(String employeeId);
  Future<WorkPeriodModel?> getWorkPeriodById(String id);
  Future<List<WorkPeriodModel>> getWorkPeriodHistory(String employeeId);
  Future<List<WorkPeriodModel>> getAllWorkPeriods();
  Future<void> cacheWorkPeriod(WorkPeriodModel workPeriod);
  Future<void> cacheWorkPeriods(
    List<WorkPeriodModel> workPeriods, {
    String? employeeId,
  });
  Future<void> deleteCachedWorkPeriod(String id);
  Future<void> replaceTempId(String tempId, String serverId);
  Stream<List<WorkPeriodModel>> watchWorkPeriods();
  Stream<List<WorkPeriodModel>> watchWorkPeriodHistory(String employeeId);
  Stream<WorkPeriodModel?> watchActiveWorkPeriod(String employeeId);
}

class WorkPeriodsLocalDataSourceImpl implements IWorkPeriodsLocalDataSource {
  final StorageService storageService;

  WorkPeriodsLocalDataSourceImpl({required this.storageService});

  @override
  Future<WorkPeriodModel?> getActiveWorkPeriod(String employeeId) async {
    final box = storageService.workPeriodsBox;
    WorkPeriodModel? active;

    for (final raw in box.values) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        final model = WorkPeriodModel.fromLocalJson(map);
        final matchesEmployee = model.employeeId == employeeId ||
            storageService.getServerId(model.employeeId) == employeeId ||
            storageService.getClientId(model.employeeId) == employeeId;
        if (matchesEmployee && model.departureDate == null) {
          if (active == null || model.arrivalDate.isAfter(active.arrivalDate)) {
            active = model;
          }
        }
      } catch (_) {}
    }
    return active;
  }

  @override
  Future<List<WorkPeriodModel>> getAllWorkPeriods() async {
    final box = storageService.workPeriodsBox;
    final list = <WorkPeriodModel>[];
    for (final raw in box.values) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        list.add(WorkPeriodModel.fromLocalJson(map));
      } catch (_) {}
    }
    return list;
  }

  @override
  Future<List<WorkPeriodModel>> getWorkPeriodHistory(String employeeId) async {
    final box = storageService.workPeriodsBox;
    final history = <WorkPeriodModel>[];
    for (final raw in box.values) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        final model = WorkPeriodModel.fromLocalJson(map);
        final matchesEmployee = model.employeeId == employeeId ||
            storageService.getServerId(model.employeeId) == employeeId ||
            storageService.getClientId(model.employeeId) == employeeId;
        if (matchesEmployee && model.departureDate != null) {

          if (!model.isSynced) {
            final serverId = storageService.getServerId(model.id);
            if (serverId != null && box.containsKey(serverId)) {
              continue;
            }
          }

          final isDuplicate = history.any((h) {
            if (h.id == model.id) return true;
            final hServerId = storageService.getServerId(h.id);
            final mServerId = storageService.getServerId(model.id);
            if (hServerId != null && (hServerId == model.id || hServerId == mServerId)) {
              return true;
            }
            if (mServerId != null && (mServerId == h.id || mServerId == hServerId)) {
              return true;
            }
            if (h.arrivalDate.isAtSameMomentAs(model.arrivalDate) &&
                h.departureDate != null &&
                model.departureDate != null &&
                h.departureDate!.isAtSameMomentAs(model.departureDate!)) {
              return true;
            }
            return false;
          });
          if (isDuplicate) {
            continue;
          }
          var effectiveModel = model;
          var dailyWage = model.dailyWage;
          if (dailyWage == 0.0) {
            final empRaw = storageService.employeesBox.get(employeeId);
            if (empRaw != null) {
              try {
                final empJson = json.decode(empRaw) as Map<String, dynamic>;
                final rawWage = empJson['dailyWage'] ?? empJson['DailyWage'];
                if (rawWage is num) {
                  dailyWage = rawWage.toDouble();
                } else if (rawWage != null) {
                  dailyWage = double.tryParse(rawWage.toString()) ?? 0.0;
                }
              } catch (_) {}
            }
          }

          var workedDays = model.totalWorkedDays ?? 0.0;
          if (workedDays == 0.0 && model.departureDate != null) {
            final arrivalOnly = DateTime(
              model.arrivalDate.year,
              model.arrivalDate.month,
              model.arrivalDate.day,
            );
            final departureOnly = DateTime(
              model.departureDate!.year,
              model.departureDate!.month,
              model.departureDate!.day,
            );
            final daysDiff = departureOnly.isBefore(arrivalOnly)
                ? 0
                : departureOnly.difference(arrivalOnly).inDays;
            final adjustment = model.arrivalTimeType == 'Morning' ? 1.0 : 0.5;
            workedDays = daysDiff + adjustment;
          }

          var totalSalary = model.totalSalary ?? 0.0;
          if (totalSalary == 0.0) {
            totalSalary = workedDays * dailyWage;
          }
          var finalSalary = model.finalSalary ?? 0.0;
          if (finalSalary == 0.0 &&
              (totalSalary > 0 ||
                  model.totalWithdrawals > 0 ||
                  model.totalBonuses > 0)) {
            finalSalary =
                totalSalary - model.totalWithdrawals + model.totalBonuses;
          }

          if (model.totalWorkedDays != workedDays ||
              model.dailyWage != dailyWage ||
              model.totalSalary != totalSalary ||
              model.finalSalary != finalSalary) {
            effectiveModel = WorkPeriodModel.fromEntity(
              model.copyWith(
                dailyWage: dailyWage,
                totalWorkedDays: workedDays,
                totalSalary: totalSalary,
                finalSalary: finalSalary,
              ),
            );
            await box.put(model.id, json.encode(effectiveModel.toLocalJson()));
          }

          history.add(effectiveModel);
        }
      } catch (_) {}
    }
    history.sort((a, b) => b.arrivalDate.compareTo(a.arrivalDate));
    return history;
  }

  @override
  Future<WorkPeriodModel?> getWorkPeriodById(String id) async {
    final raw = storageService.workPeriodsBox.get(id);
    if (raw == null) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return WorkPeriodModel.fromLocalJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheWorkPeriod(WorkPeriodModel workPeriod) async {
    await storageService.workPeriodsBox.put(
      workPeriod.id,
      json.encode(workPeriod.toLocalJson()),
    );
  }

  @override
  Future<void> cacheWorkPeriods(
    List<WorkPeriodModel> workPeriods, {
    String? employeeId,
  }) async {
    final box = storageService.workPeriodsBox;

    final keysToRemove = <String>{};
    for (final wp in workPeriods) {
      final clientTempId = storageService.getClientId(wp.id);
      if (clientTempId != null && clientTempId != wp.id) {
        keysToRemove.add(clientTempId);
      }
    }

    final incomingIds = workPeriods.map((wp) => wp.id).toSet();

    if (employeeId != null) {
      for (final key in box.keys) {
        final kStr = key.toString();
        if (!incomingIds.contains(kStr)) {
          final raw = box.get(key);
          if (raw != null) {
            try {
              final map = json.decode(raw) as Map<String, dynamic>;
              final empId = map['employeeId']?.toString();
              final isForEmp = empId == employeeId ||
                  storageService.getServerId(empId ?? '') == employeeId ||
                  storageService.getClientId(empId ?? '') == employeeId;
              if (isForEmp && map['isSynced'] == true) {
                keysToRemove.add(kStr);
              }
            } catch (_) {}
          }
        }
      }
    }

    if (keysToRemove.isNotEmpty) {
      await box.deleteAll(keysToRemove.toList());
    }

    final mapToPut = <String, String>{};
    for (final wp in workPeriods) {
      final existingRaw = box.get(wp.id);
      if (existingRaw != null) {
        try {
          final existingMap = json.decode(existingRaw) as Map<String, dynamic>;
          final existingModel = WorkPeriodModel.fromLocalJson(existingMap);
          if (!existingModel.isSynced) {

            mapToPut[wp.id] = existingRaw;
            continue;
          }
        } catch (_) {}
      }
      mapToPut[wp.id] = json.encode(wp.toLocalJson());
    }
    await box.putAll(mapToPut);
  }

  @override
  Future<void> deleteCachedWorkPeriod(String id) async {
    await storageService.workPeriodsBox.delete(id);
  }

  @override
  Future<void> replaceTempId(String tempId, String serverId) async {
    final box = storageService.workPeriodsBox;
    final raw = box.get(tempId);
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      map['id'] = serverId;
      map['workPeriodId'] = int.tryParse(serverId) ?? serverId;
      map['isSynced'] = true;
      await box.put(serverId, json.encode(map));
      await box.delete(tempId);
    }
  }

  @override
  Stream<List<WorkPeriodModel>> watchWorkPeriods() {
    return storageService.workPeriodsBox.watch().asyncMap(
      (_) async => getAllWorkPeriods(),
    );
  }

  @override
  Stream<List<WorkPeriodModel>> watchWorkPeriodHistory(String employeeId) {
    return storageService.workPeriodsBox.watch().asyncMap(
      (_) async => getWorkPeriodHistory(employeeId),
    );
  }

  @override
  Stream<WorkPeriodModel?> watchActiveWorkPeriod(String employeeId) {
    return storageService.workPeriodsBox.watch().asyncMap(
      (_) async => getActiveWorkPeriod(employeeId),
    );
  }
}
