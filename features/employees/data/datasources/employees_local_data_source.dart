import 'dart:convert';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/sort_utils.dart';
import '../models/employee_model.dart';

abstract class IEmployeesLocalDataSource {
  Future<List<EmployeeModel>> getCachedEmployees();
  Future<EmployeeModel?> getCachedEmployeeById(String id);
  Future<void> cacheEmployees(List<EmployeeModel> employees);
  Future<void> cacheEmployee(EmployeeModel employee);
  Future<void> deleteCachedEmployee(String id);
  Future<void> replaceTempId(String tempId, String serverId);
  Stream<List<EmployeeModel>> watchEmployees();
}

class EmployeesLocalDataSourceImpl implements IEmployeesLocalDataSource {
  final StorageService storageService;

  EmployeesLocalDataSourceImpl({required this.storageService});

  @override
  Future<List<EmployeeModel>> getCachedEmployees() async {
    final box = storageService.employeesBox;
    final items = <EmployeeModel>[];
    for (final raw in box.values) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        items.add(EmployeeModel.fromLocalJson(map));
      } catch (_) {}
    }
    items.sort((a, b) => SortUtils.compareIds(a.id, b.id));
    return items;
  }

  @override
  Future<EmployeeModel?> getCachedEmployeeById(String id) async {
    var raw = storageService.employeesBox.get(id);
    if (raw == null) {
      final intId = int.tryParse(id);
      if (intId != null) {
        raw = storageService.employeesBox.get(intId);
      }
    }
    if (raw == null) {
      final mappedServerId = storageService.getServerId(id);
      if (mappedServerId != null) {
        raw = storageService.employeesBox.get(mappedServerId);
      }
    }
    if (raw == null) {
      final mappedClientId = storageService.getClientId(id);
      if (mappedClientId != null) {
        raw = storageService.employeesBox.get(mappedClientId);
      }
    }
    if (raw != null) {
      try {
        return EmployeeModel.fromLocalJson(
          json.decode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    for (final val in storageService.employeesBox.values) {
      try {
        final map = json.decode(val) as Map<String, dynamic>;
        final model = EmployeeModel.fromLocalJson(map);
        if (model.id == id ||
            storageService.getServerId(model.id) == id ||
            storageService.getClientId(model.id) == id) {
          return model;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<void> cacheEmployees(List<EmployeeModel> employees) async {
    final box = storageService.employeesBox;

    final incomingIds = employees.map((e) => e.id).toSet();
    final keysToRemove = <String>[];
    for (final key in box.keys) {
      final kStr = key.toString();
      if (!incomingIds.contains(kStr)) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final map = json.decode(raw);
            if (map is Map && map['isSynced'] == true) {
              keysToRemove.add(kStr);
            }
          } catch (_) {}
        }
      }
    }
    if (keysToRemove.isNotEmpty) {
      await box.deleteAll(keysToRemove);
    }

    final itemsToPut = <String, String>{};
    for (final emp in employees) {
      final merged = _mergeWithExisting(emp);
      itemsToPut[merged.id] = json.encode(merged.toLocalJson());
    }
    await box.putAll(itemsToPut);
  }

  @override
  Future<void> cacheEmployee(EmployeeModel employee) async {
    final merged = _mergeWithExisting(employee);
    await storageService.employeesBox.put(
      merged.id,
      json.encode(merged.toLocalJson()),
    );
  }

  EmployeeModel _mergeWithExisting(EmployeeModel incoming) {
    final raw = storageService.employeesBox.get(incoming.id);
    if (raw == null) return incoming;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final existing = EmployeeModel.fromLocalJson(map);
      return incoming.copyWith(
        dailyWage: (incoming.dailyWage != null && incoming.dailyWage! > 0)
            ? incoming.dailyWage
            : existing.dailyWage,
        nationalId: incoming.nationalId ?? existing.nationalId,
        mobileNumber: incoming.mobileNumber ?? existing.mobileNumber,
      );
    } catch (_) {
      return incoming;
    }
  }

  @override
  Future<void> deleteCachedEmployee(String id) async {
    await storageService.employeesBox.delete(id);
  }

  @override
  Future<void> replaceTempId(String tempId, String serverId) async {
    final box = storageService.employeesBox;
    final raw = box.get(tempId);
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      map['id'] = serverId;
      map['employeeId'] = int.tryParse(serverId) ?? serverId;
      map['isSynced'] = true;
      await box.put(serverId, json.encode(map));
      await box.delete(tempId);
    }
  }

  @override
  Stream<List<EmployeeModel>> watchEmployees() {
    return storageService.employeesBox.watch().asyncMap(
      (_) async => getCachedEmployees(),
    );
  }
}
