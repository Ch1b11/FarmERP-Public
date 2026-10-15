import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_editor_sheet.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';

class EmployeeEditorSheet extends StatefulWidget {
  final Employee? employee;

  const EmployeeEditorSheet({super.key, this.employee});

  static Future<void> show(BuildContext context, {Employee? employee}) {
    final bloc = context.read<EmployeesBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EmployeeEditorSheet(employee: employee),
      ),
    );
  }

  @override
  State<EmployeeEditorSheet> createState() => _EmployeeEditorSheetState();
}

class _EmployeeEditorSheetState extends State<EmployeeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _nationalIdCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _wageCtrl;
  String? _selectedDeptId;
  Employee? _loadedEmployee;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _loadedEmployee = e;
    _firstNameCtrl = TextEditingController(text: e?.firstName ?? '');
    _middleNameCtrl = TextEditingController(text: e?.middleName ?? '');
    _lastNameCtrl = TextEditingController(text: e?.lastName ?? '');
    _nationalIdCtrl = TextEditingController(text: e?.nationalId ?? '');
    _mobileCtrl = TextEditingController(text: e?.mobileNumber ?? '');
    _jobTitleCtrl = TextEditingController(text: e?.jobTitle ?? '');
    _wageCtrl = TextEditingController(
      text: (e != null && e.dailyWage != null)
          ? e.dailyWage!.toStringAsFixed(2)
          : '',
    );
    _selectedDeptId = e?.departmentId;

    if (e != null) {
      _loadFullEmployeeDetails();
    }
  }

  Future<void> _loadFullEmployeeDetails() async {
    final emp = widget.employee;
    if (emp == null) return;

    final repo = context.read<EmployeesBloc>().getEmployeesUseCase.repository;

    final cachedResult = await repo.getCachedEmployeeById(emp.id);
    cachedResult.fold((_) {}, (cachedEmp) {
      if (cachedEmp != null && mounted) {
        _populateFromFullEmployee(cachedEmp);
      }
    });

    final remoteResult = await repo.getEmployeeById(emp.id);
    remoteResult.fold((_) {}, (remoteEmp) {
      if (mounted) {
        _populateFromFullEmployee(remoteEmp);
      }
    });
  }

  void _populateFromFullEmployee(Employee fullEmp) {
    setState(() {
      _loadedEmployee = fullEmp;
      if (_firstNameCtrl.text.isEmpty && fullEmp.firstName.isNotEmpty) {
        _firstNameCtrl.text = fullEmp.firstName;
      }
      if (_lastNameCtrl.text.isEmpty && fullEmp.lastName.isNotEmpty) {
        _lastNameCtrl.text = fullEmp.lastName;
      }
      if (_middleNameCtrl.text.isEmpty && fullEmp.middleName != null) {
        _middleNameCtrl.text = fullEmp.middleName!;
      }
      if (_nationalIdCtrl.text.isEmpty && fullEmp.nationalId != null) {
        _nationalIdCtrl.text = fullEmp.nationalId!;
      }
      if (_mobileCtrl.text.isEmpty && fullEmp.mobileNumber != null) {
        _mobileCtrl.text = fullEmp.mobileNumber!;
      }
      if (_jobTitleCtrl.text.isEmpty && fullEmp.jobTitle != null) {
        _jobTitleCtrl.text = fullEmp.jobTitle!;
      }
      if (_wageCtrl.text.isEmpty && fullEmp.dailyWage != null) {
        _wageCtrl.text = fullEmp.dailyWage!.toStringAsFixed(2);
      }
      if (_selectedDeptId == null && fullEmp.departmentId != null) {
        _selectedDeptId = fullEmp.departmentId;
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _mobileCtrl.dispose();
    _jobTitleCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  InputDecoration _dec(
    AppLocalizations l10n,
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _onSave(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;

    final wageText = _wageCtrl.text.trim();
    final parsedWage = double.tryParse(wageText) ?? 0.0;
    final refEmp = _loadedEmployee ?? widget.employee;
    final wageVal =
        (refEmp != null &&
            refEmp.dailyWage != null &&
            (parsedWage - refEmp.dailyWage!).abs() < 0.0001)
        ? refEmp.dailyWage!
        : parsedWage;

    final firstName = _firstNameCtrl.text.trim();
    final middleName = _middleNameCtrl.text.trim().isEmpty
        ? null
        : _middleNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final nationalId = _nationalIdCtrl.text.trim().isEmpty
        ? null
        : _nationalIdCtrl.text.trim();
    final mobileNumber = _mobileCtrl.text.trim().isEmpty
        ? null
        : _mobileCtrl.text.trim();
    final jobTitle = _jobTitleCtrl.text.trim().isEmpty
        ? null
        : _jobTitleCtrl.text.trim();

    if (widget.employee == null) {
      ctx.read<EmployeesBloc>().add(
        EmployeeCreateRequested(
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          nationalId: nationalId,
          mobileNumber: mobileNumber,
          jobTitle: jobTitle,
          departmentId: _selectedDeptId,
          dailyWage: wageVal,
        ),
      );
    } else {
      final old = refEmp!;
      final oldMiddle = _nullIfEmpty(old.middleName);
      final oldNationalId = _nullIfEmpty(old.nationalId);
      final oldMobile = _nullIfEmpty(old.mobileNumber);
      final oldJobTitle = _nullIfEmpty(old.jobTitle);

      final computedFullName = (middleName != null && middleName.isNotEmpty)
          ? '$firstName $middleName $lastName'.trim()
          : '$firstName $lastName'.trim();
      final hasNameChanged =
          firstName != old.firstName.trim() ||
          middleName != oldMiddle ||
          lastName != old.lastName.trim();
      final fullName = hasNameChanged ? computedFullName : old.fullName;

      final updated = Employee(
        id: old.id,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        fullName: fullName,
        nationalId: nationalId,
        mobileNumber: mobileNumber,
        jobTitle: jobTitle,
        departmentId: _selectedDeptId,
        departmentName: _selectedDeptId == old.departmentId
            ? old.departmentName
            : null,
        dailyWage: wageVal,
        isSynced: old.isSynced,
      );

      final isUnchanged =
          firstName == old.firstName.trim() &&
          middleName == oldMiddle &&
          lastName == old.lastName.trim() &&
          nationalId == oldNationalId &&
          mobileNumber == oldMobile &&
          jobTitle == oldJobTitle &&
          _selectedDeptId == old.departmentId &&
          (old.dailyWage != null && (wageVal - old.dailyWage!).abs() < 0.0001);

      if (isUnchanged || updated == old) {
        Navigator.of(ctx).pop();
        return;
      }

      ctx.read<EmployeesBloc>().add(
        EmployeeUpdateRequested(
          id: old.id,
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          nationalId: nationalId,
          mobileNumber: mobileNumber,
          jobTitle: jobTitle,
          departmentId: _selectedDeptId,
          dailyWage: wageVal,
        ),
      );
    }
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.employee != null;

    return AppEditorSheet(
      headerIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isEditing ? Icons.edit_note_rounded : Icons.person_add_rounded,
          color: theme.colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: isEditing ? l10n.editEmployee : l10n.addNewEmployee,
      subtitle: isEditing
          ? l10n.updateEmployeeSubtitle
          : l10n.createEmployeeSubtitle,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextFormField(
              controller: _firstNameCtrl,
              decoration: _dec(
                l10n,
                l10n.employeeFirstNameLabel,
                l10n.employeeFirstNameHint,
                Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.enterEmployeeFirstNameError;
                }
                if (v.trim().length > 50) {
                  return l10n.employeeFirstNameLengthError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _middleNameCtrl,
              decoration: _dec(
                l10n,
                l10n.employeeMiddleNameLabel,
                l10n.employeeMiddleNameHint,
                Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v != null && v.trim().length > 50) {
                  return l10n.employeeMiddleNameLengthError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lastNameCtrl,
              decoration: _dec(
                l10n,
                l10n.employeeLastNameLabel,
                l10n.employeeLastNameHint,
                Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.enterEmployeeLastNameError;
                }
                if (v.trim().length > 50) {
                  return l10n.employeeLastNameLengthError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nationalIdCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(
                l10n,
                l10n.nationalIdLabel,
                l10n.nationalIdHint,
                Icons.badge_outlined,
              ),
              validator: (v) {
                if (v != null && v.trim().length > 20) {
                  return l10n.nationalIdLengthError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec(
                l10n,
                l10n.mobileNumberLabel,
                l10n.mobileNumberHint,
                Icons.phone_outlined,
              ),
              validator: (v) {
                if (v != null && v.trim().length > 20) {
                  return l10n.mobileNumberLengthError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _jobTitleCtrl,
              decoration: _dec(
                l10n,
                l10n.jobTitleLabel,
                l10n.jobTitleHint,
                Icons.work_outline_rounded,
              ),
              validator: (v) {
                if (v != null && v.trim().length > 50) {
                  return l10n.jobTitleLengthError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _wageCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: _dec(
                l10n,
                l10n.dailyWageLabel,
                l10n.dailyWageHint,
                Icons.payments_outlined,
              ),
              validator: (v) {
                final val = double.tryParse(v?.trim() ?? '');
                if (val == null || val < 0 || val > 1000000) {
                  return l10n.dailyWageError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            BlocBuilder<EmployeesBloc, EmployeesState>(
              buildWhen: (p, c) {
                if (c is! EmployeesLoaded) return false;
                if (p is! EmployeesLoaded) return true;
                return p.departments != c.departments;
              },
              builder: (context, state) {
                final depts = state is EmployeesLoaded
                    ? state.departments
                    : <Department>[];
                final safeDeptId =
                    (_selectedDeptId != null &&
                        depts.any((d) => d.id.toString() == _selectedDeptId))
                    ? _selectedDeptId
                    : null;
                return DropdownButtonFormField<String?>(
                  key: ValueKey(safeDeptId),
                  initialValue: safeDeptId,
                  decoration: InputDecoration(
                    labelText: l10n.departmentLabel,
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.noDepartment),
                    ),
                    ...depts.map(
                      (d) => DropdownMenuItem<String?>(
                        value: d.id.toString(),
                        child: Text(d.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedDeptId = v),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        AppActionButton(
          label: l10n.cancel,
          isFilled: false,
          onTap: () => Navigator.of(context).pop(),
        ),
        AppActionButton(
          label: isEditing ? l10n.saveEmployee : l10n.createEmployee,
          isFilled: true,
          leadingIcon: Icon(
            isEditing ? Icons.check : Icons.add,
            color: theme.colorScheme.onPrimary,
            size: 18,
          ),
          onTap: () => _onSave(context),
        ),
      ],
    );
  }
}
