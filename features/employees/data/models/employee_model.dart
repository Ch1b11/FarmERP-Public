import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.firstName,
    super.middleName,
    required super.lastName,
    required super.fullName,
    super.nationalId,
    super.mobileNumber,
    super.jobTitle,
    super.departmentId,
    super.departmentName,
    super.dailyWage,
    super.isActive = true,
    super.isSynced = true,
  });

  static String? _sanitizeNullable(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['employeeId'] ?? json['EmployeeId'] ?? json['id'] ?? json['Id'];
    final firstName = (json['firstName'] ?? json['FirstName'] ?? '').toString();
    final middleName = _sanitizeNullable(
      json['middleName'] ?? json['MiddleName'],
    );
    final lastName = (json['lastName'] ?? json['LastName'] ?? '').toString();
    final fullName =
        (json['fullName'] ?? json['FullName']) as String? ??
        (middleName != null && middleName.isNotEmpty
            ? '$firstName $middleName $lastName'.trim()
            : '$firstName $lastName'.trim());
    final rawWage = json['dailyWage'] ?? json['DailyWage'];
    final wage = rawWage != null
        ? (rawWage is num
              ? rawWage.toDouble()
              : double.tryParse(rawWage.toString()))
        : null;
    final rawDeptId =
        json['departmentId'] ??
        json['DepartmentId'] ??
        json['departmentID'] ??
        json['DepartmentID'];
    final deptId = rawDeptId?.toString();
    final rawIsActive = json['isActive'] ?? json['IsActive'];

    return EmployeeModel(
      id: rawId?.toString() ?? '',
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      fullName: fullName,
      nationalId: _sanitizeNullable(
        json['nationalId'] ?? json['NationalId'] ?? json['NationalID'],
      ),
      mobileNumber: _sanitizeNullable(
        json['mobileNumber'] ?? json['MobileNumber'],
      ),
      jobTitle: _sanitizeNullable(
        json['jobTitle'] ?? json['JobTitle'] ?? json['role'] ?? json['Role'],
      ),
      departmentId: deptId,
      departmentName: _sanitizeNullable(
        json['departmentName'] ?? json['DepartmentName'],
      ),
      dailyWage: wage,
      isActive: rawIsActive is bool ? rawIsActive : true,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  @override
  EmployeeModel copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? fullName,
    String? nationalId,
    String? mobileNumber,
    String? jobTitle,
    String? departmentId,
    String? departmentName,
    double? dailyWage,
    bool? isActive,
    bool? isSynced,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      jobTitle: jobTitle ?? this.jobTitle,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      dailyWage: dailyWage ?? this.dailyWage,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson({bool forUpdate = false}) {
    int? parsedDeptId;
    if (departmentId != null && departmentId!.trim().isNotEmpty) {
      parsedDeptId = int.tryParse(departmentId!.trim());
    }

    final map = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
    };

    if (middleName != null && middleName!.trim().isNotEmpty) {
      map['middleName'] = middleName!.trim();
    }
    if (nationalId != null && nationalId!.trim().isNotEmpty) {
      map['nationalId'] = nationalId!.trim();
    }
    if (mobileNumber != null && mobileNumber!.trim().isNotEmpty) {
      map['mobileNumber'] = mobileNumber!.trim();
    }
    if (jobTitle != null && jobTitle!.trim().isNotEmpty) {
      map['jobTitle'] = jobTitle!.trim();
    }

    if (parsedDeptId != null) {
      map['departmentId'] = parsedDeptId;
    } else if (departmentId != null && departmentId!.trim().isNotEmpty) {
      map['departmentId'] = departmentId!.trim();
    }

    if (dailyWage != null) {
      map['dailyWage'] = dailyWage;
    }

    if (forUpdate) {
      map['isActive'] = isActive;
    }

    return map;
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'employeeId': int.tryParse(id),
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'fullName': fullName,
      'nationalId': nationalId,
      'mobileNumber': mobileNumber,
      'jobTitle': jobTitle,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'dailyWage': dailyWage,
      'isActive': isActive,
      'isSynced': isSynced,
    };
  }

  factory EmployeeModel.fromLocalJson(Map<String, dynamic> json) {
    final rawId =
        json['id']?.toString() ?? json['employeeId']?.toString() ?? '';
    final rawWage = json['dailyWage'] ?? json['DailyWage'];
    final wage = rawWage != null
        ? (rawWage is num
              ? rawWage.toDouble()
              : double.tryParse(rawWage.toString()))
        : null;
    final rawDeptId = json['departmentId'] ?? json['DepartmentId'];
    final deptId = rawDeptId?.toString();
    final rawIsActive = json['isActive'] ?? json['IsActive'];

    return EmployeeModel(
      id: rawId,
      firstName: (json['firstName'] ?? '').toString(),
      middleName: _sanitizeNullable(json['middleName']),
      lastName: (json['lastName'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      nationalId: _sanitizeNullable(json['nationalId'] ?? json['NationalId']),
      mobileNumber: _sanitizeNullable(
        json['mobileNumber'] ?? json['MobileNumber'],
      ),
      jobTitle: _sanitizeNullable(json['jobTitle'] ?? json['Role']),
      departmentId: deptId,
      departmentName: _sanitizeNullable(json['departmentName']),
      dailyWage: wage,
      isActive: rawIsActive is bool ? rawIsActive : true,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  factory EmployeeModel.fromEntity(Employee e) {
    return EmployeeModel(
      id: e.id,
      firstName: e.firstName,
      middleName: e.middleName,
      lastName: e.lastName,
      fullName: e.fullName,
      nationalId: e.nationalId,
      mobileNumber: e.mobileNumber,
      jobTitle: e.jobTitle,
      departmentId: e.departmentId,
      departmentName: e.departmentName,
      dailyWage: e.dailyWage,
      isActive: e.isActive,
      isSynced: e.isSynced,
    );
  }
}
