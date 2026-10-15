import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_editor_sheet.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/domain/entities/finance_account.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/work_period.dart';
import '../../domain/utils/work_period_calculator.dart';
import '../bloc/employee_profile_bloc.dart';
import '../bloc/employee_profile_event.dart';
import '../bloc/employee_profile_state.dart';

class CompletePeriodSheet extends StatefulWidget {
  final WorkPeriod period;
  final Employee employee;

  const CompletePeriodSheet({
    super.key,
    required this.period,
    required this.employee,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkPeriod period,
    required Employee employee,
  }) {
    final bloc = context.read<EmployeeProfileBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CompletePeriodSheet(period: period, employee: employee),
      ),
    );
  }

  @override
  State<CompletePeriodSheet> createState() => _CompletePeriodSheetState();
}

class _CompletePeriodSheetState extends State<CompletePeriodSheet> {
  late DateTime _departureDate;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _departureDate = now.isBefore(widget.period.arrivalDate)
        ? widget.period.arrivalDate
        : now;

    final blocState = context.read<EmployeeProfileBloc>().state;
    if (blocState is EmployeeProfileLoaded &&
        blocState.financeAccounts.isNotEmpty) {
      final defaultAcc =
          blocState.financeAccounts.firstWhereOrNull((a) => a.isDefault) ??
          blocState.financeAccounts.firstOrNull;
      _selectedAccountId = defaultAcc?.id.toString() ?? '1';
    } else {
      _selectedAccountId = '1';
    }
  }

  Future<void> _pickDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: widget.period.arrivalDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  void _submit({required bool hasInsufficientFunds}) {
    if (hasInsufficientFunds) return;
    final accountId = _selectedAccountId ?? '1';
    context.read<EmployeeProfileBloc>().add(
      PeriodCompletionSubmitted(
        periodId: widget.period.id,
        departureDate: _departureDate,
        accountId: accountId,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final workedDays = WorkPeriodCalculator.calculateWorkedDays(
      arrivalDate: widget.period.arrivalDate,
      departureDate: _departureDate,
      arrivalTimeType: widget.period.arrivalTimeType,
    );
    final wage = widget.period.dailyWage > 0
        ? widget.period.dailyWage
        : (widget.employee.dailyWage ?? 0.0);
    final totalSalary = WorkPeriodCalculator.calculateTotalSalary(
      workedDays: workedDays,
      dailyWage: wage,
    );
    final netPayable = WorkPeriodCalculator.calculateNetPayable(
      totalSalary: totalSalary,
      totalWithdrawals: widget.period.totalWithdrawals,
      totalBonuses: widget.period.totalBonuses,
    );

    final workedDaysStr = WorkPeriodCalculator.formatWorkedDays(workedDays);

    final blocState = context.watch<EmployeeProfileBloc>().state;
    final accounts = blocState is EmployeeProfileLoaded
        ? blocState.financeAccounts
        : const <FinanceAccount>[];

    final effectiveAccountId = accounts.isNotEmpty
        ? (accounts.any((a) => a.id.toString() == _selectedAccountId)
              ? _selectedAccountId!
              : accounts.first.id.toString())
        : (_selectedAccountId == '2' ? '2' : '1');

    final selectedAccount = accounts.firstWhereOrNull(
      (a) => a.id.toString() == effectiveAccountId,
    );
    final hasInsufficientFunds =
        selectedAccount != null &&
        netPayable > 0 &&
        selectedAccount.balance < netPayable;

    return AppEditorSheet(
      headerIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.archive_outlined,
          color: theme.colorScheme.onErrorContainer,
          size: 24,
        ),
      ),
      title: l10n.completeAndArchivePeriod,
      subtitle: l10n.completePeriodDesc,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.departureDate,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDepartureDate,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              child: Text(
                DateFormat('yyyy-MM-dd').format(_departureDate),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (accounts.isNotEmpty) ...[
            Text(
              l10n.paymentSource,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: effectiveAccountId,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account.id.toString(),
                  child: Text(
                    '${account.name} (${account.balance.toStringAsFixed(2)} EGP)',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedAccountId = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (hasInsufficientFunds) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.insufficientAccountFunds} (${selectedAccount.name}: ${selectedAccount.balance.toStringAsFixed(2)} EGP < ${netPayable.toStringAsFixed(2)} EGP)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  theme,
                  label: l10n.workedDays,
                  value: '$workedDaysStr ${l10n.days}',
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  theme,
                  label: l10n.totalSalary,
                  value: '${totalSalary.toStringAsFixed(2)} EGP',
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  theme,
                  label: l10n.withdrawals,
                  value:
                      '-${widget.period.totalWithdrawals.toStringAsFixed(2)} EGP',
                  valueColor: Colors.red.shade700,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  theme,
                  label: l10n.bonuses,
                  value:
                      '+${widget.period.totalBonuses.toStringAsFixed(2)} EGP',
                  valueColor: Colors.green.shade700,
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  theme,
                  label: l10n.netPayable,
                  value: '${netPayable.toStringAsFixed(2)} EGP',
                  isBold: true,
                  valueColor: Colors.amber.shade900,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      actions: [
        AppActionButton(
          label: l10n.cancel,
          isFilled: false,
          onTap: () => Navigator.pop(context),
        ),
        AppActionButton(
          label: l10n.confirmPayment,
          isFilled: true,
          color: hasInsufficientFunds
              ? theme.disabledColor
              : theme.colorScheme.error,
          onTap: () => _submit(hasInsufficientFunds: hasInsufficientFunds),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme, {
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
