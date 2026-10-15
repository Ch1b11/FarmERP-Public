import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String fullName;
  final String? nationalId;
  final String? mobileNumber;
  final String? jobTitle;
  final String? departmentId;
  final String? departmentName;
  final double? dailyWage;
  final bool isActive;
  final bool isSynced;

  int? get departmentIdInt => int.tryParse(departmentId ?? '');

  const Employee({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.fullName,
    this.nationalId,
    this.mobileNumber,
    this.jobTitle,
    this.departmentId,
    this.departmentName,
    this.dailyWage,
    this.isActive = true,
    this.isSynced = true,
  });

  Employee copyWith({
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
    return Employee(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          id == other.id &&
          firstName == other.firstName &&
          middleName == other.middleName &&
          lastName == other.lastName &&
          fullName == other.fullName &&
          nationalId == other.nationalId &&
          mobileNumber == other.mobileNumber &&
          jobTitle == other.jobTitle &&
          departmentId == other.departmentId &&
          departmentName == other.departmentName &&
          (dailyWage == other.dailyWage ||
              (dailyWage != null &&
                  other.dailyWage != null &&
                  (dailyWage! - other.dailyWage!).abs() < 0.0001)) &&
          isActive == other.isActive &&
          isSynced == other.isSynced);

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    middleName,
    lastName,
    fullName,
    nationalId,
    mobileNumber,
    jobTitle,
    departmentId,
    departmentName,
    dailyWage,
    isActive,
    isSynced,
  );

  @override
  List<Object?> get props => [
    id,
    firstName,
    middleName,
    lastName,
    fullName,
    nationalId,
    mobileNumber,
    jobTitle,
    departmentId,
    departmentName,
    dailyWage,
    isActive,
    isSynced,
  ];
}
