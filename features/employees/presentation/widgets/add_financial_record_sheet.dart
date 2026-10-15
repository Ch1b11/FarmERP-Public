import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_editor_sheet.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/employee_profile_bloc.dart';
import '../bloc/employee_profile_event.dart';

enum FinancialRecordType { withdrawal, bonus }

class AddFinancialRecordSheet extends StatefulWidget {
  final FinancialRecordType type;
  final String periodId;

  const AddFinancialRecordSheet({
    super.key,
    required this.type,
    required this.periodId,
  });

  static Future<void> show(
    BuildContext context, {
    required FinancialRecordType type,
    required String periodId,
  }) {
    final bloc = context.read<EmployeeProfileBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddFinancialRecordSheet(type: type, periodId: periodId),
      ),
    );
  }

  @override
  State<AddFinancialRecordSheet> createState() =>
      _AddFinancialRecordSheetState();
}

class _AddFinancialRecordSheetState extends State<AddFinancialRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isWithdrawal => widget.type == FinancialRecordType.withdrawal;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final notes = _notesCtrl.text.trim().isEmpty
        ? null
        : _notesCtrl.text.trim();

    if (_isWithdrawal) {
      context.read<EmployeeProfileBloc>().add(
        WithdrawalSubmitted(
          periodId: widget.periodId,
          amount: amount,
          date: _selectedDate,
          notes: notes,
        ),
      );
    } else {
      context.read<EmployeeProfileBloc>().add(
        BonusSubmitted(
          periodId: widget.periodId,
          amount: amount,
          date: _selectedDate,
          notes: notes,
        ),
      );
    }

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accentColor = _isWithdrawal
        ? Colors.orange.shade800
        : Colors.green.shade700;
    final title = _isWithdrawal ? l10n.addWithdrawal : l10n.addBonus;
    final icon = _isWithdrawal
        ? Icons.money_off_rounded
        : Icons.add_circle_outline_rounded;

    return AppEditorSheet(
      headerIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accentColor, size: 24),
      ),
      title: title,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: '${l10n.amount} *',
                hintText: l10n.amountHint,
                suffixText: 'EGP',
                prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.amountRequired;
                }
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return l10n.invalidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.date,
                  prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: l10n.notesHint,
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v != null && v.length > 500) {
                  return l10n.notesLengthError;
                }
                return null;
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
          label: l10n.save,
          isFilled: true,
          color: accentColor,
          onTap: _submit,
        ),
      ],
    );
  }
}
