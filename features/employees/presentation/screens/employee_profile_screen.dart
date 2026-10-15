import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/layout_manager/adaptive_layout_manager.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_content_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/work_period.dart';
import '../../domain/utils/work_period_calculator.dart';
import '../bloc/employee_profile_bloc.dart';
import '../bloc/employee_profile_event.dart';
import '../bloc/employee_profile_state.dart';
import '../utils/employee_ui_helper.dart';
import '../widgets/add_financial_record_sheet.dart';
import '../widgets/complete_period_sheet.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<EmployeeProfileBloc>()..add(ProfileLoadRequested(employeeId)),
      child: EmployeeProfileView(employeeId: employeeId),
    );
  }
}

class EmployeeProfileView extends StatefulWidget {
  final String employeeId;

  const EmployeeProfileView({super.key, required this.employeeId});

  @override
  State<EmployeeProfileView> createState() => _EmployeeProfileViewState();
}

class _EmployeeProfileViewState extends State<EmployeeProfileView> {
  DateTime _selectedArrivalDate = DateTime.now();
  String _selectedShift = 'Morning';

  Future<void> _pickArrivalDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedArrivalDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedArrivalDate = picked;
      });
    }
  }

  void _handleDelete(BuildContext context, EmployeeProfileLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final hasHistory =
        state.activePeriod != null || state.workHistory.isNotEmpty;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasHistory ? l10n.deactivateEmployee : l10n.deleteEmployee),
        content: Text(
          hasHistory
              ? '${l10n.deactivateEmployeePrompt}\n\n(${state.employee.fullName})'
              : '${l10n.deleteEmployeePrompt}\n\n(${state.employee.fullName})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (hasHistory) {
                context.read<EmployeeProfileBloc>().add(
                  const ProfileDeactivateRequested(),
                );
              } else {
                context.read<EmployeeProfileBloc>().add(
                  const ProfileDeleteRequested(),
                );
              }
            },
            child: Text(hasHistory ? l10n.deactivateEmployee : l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<EmployeeProfileBloc, EmployeeProfileState>(
      listener: (context, state) {
        if (state is EmployeeProfileLoaded) {
          if (state.isDeleted) {
            SnackBarUtils.showSuccess(context, l10n.employeeDeleted);
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/employees');
            }
            return;
          }
          if (state.successMessage != null) {
            SnackBarUtils.showSuccess(
              context,
              EmployeeUiHelper.resolveMessage(l10n, state.successMessage!),
            );
          }
          if (state.errorMessage != null) {
            SnackBarUtils.showError(
              context,
              EmployeeUiHelper.resolveMessage(l10n, state.errorMessage!),
            );
          }
        } else if (state is EmployeeProfileError) {
          SnackBarUtils.showError(
            context,
            EmployeeUiHelper.resolveMessage(l10n, state.message),
          );
        }
      },
      builder: (context, state) {
        if (state is EmployeeProfileLoading ||
            state is EmployeeProfileInitial) {
          return const EmployeeProfileSkeleton();
        }

        if (state is EmployeeProfileError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.employeeNotFound,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppActionButton(
                    label: l10n.retry,
                    isFilled: true,
                    width: 140,
                    onTap: () {
                      context.read<EmployeeProfileBloc>().add(
                        ProfileLoadRequested(widget.employeeId),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        if (state is EmployeeProfileLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<EmployeeProfileBloc>().add(
                ProfileLoadRequested(widget.employeeId),
              );
            },
            child: AdaptiveLayoutManager(
              mobileLayout: (ctx) => _buildMobileLayout(ctx, state),
              tabletLayout: (ctx) => _buildTabletLayout(ctx, state),
              desktopLayout: (ctx) => _buildDesktopLayout(ctx, state),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, EmployeeProfileLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(context, state),
          const SizedBox(height: 16),
          if (state.activePeriod != null)
            _buildActivePeriodCard(context, state.employee, state.activePeriod!)
          else
            _buildInactivePeriodCard(context, state),
          const SizedBox(height: 16),
          _buildWorkHistorySection(context, state.workHistory, state.employee),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, EmployeeProfileLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildHeaderCard(context, state)),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: state.activePeriod != null
                    ? _buildActivePeriodCard(
                        context,
                        state.employee,
                        state.activePeriod!,
                      )
                    : _buildInactivePeriodCard(context, state),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWorkHistorySection(context, state.workHistory, state.employee),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    EmployeeProfileLoaded state,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildHeaderCard(context, state)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: state.activePeriod != null
                        ? _buildActivePeriodCard(
                            context,
                            state.employee,
                            state.activePeriod!,
                          )
                        : _buildInactivePeriodCard(context, state),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildWorkHistorySection(
                context,
                state.workHistory,
                state.employee,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, EmployeeProfileLoaded state) {
    final employee = state.employee;
    final activePeriod = state.activePeriod;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isActive = activePeriod != null;
    final accentColor = EmployeeUiHelper.getStatusColor(isActive);

    return AppContentCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Text(
                  EmployeeUiHelper.getInitials(
                    employee.firstName,
                    employee.lastName,
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (employee.jobTitle != null &&
                        employee.jobTitle!.isNotEmpty)
                      Text(
                        employee.jobTitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: isActive ? l10n.activeStatus : l10n.inactiveStatus,
                icon: isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: accentColor,
                fontSize: 11,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                tooltip: l10n.deleteEmployee,
                onPressed: () => _handleDelete(context, state),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.badge_outlined,
            label: l10n.nationalIdLabel,
            value:
                (employee.nationalId != null && employee.nationalId!.isNotEmpty)
                ? employee.nationalId!
                : 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.phone_outlined,
            label: l10n.mobileNumberLabel,
            value:
                (employee.mobileNumber != null &&
                    employee.mobileNumber!.isNotEmpty)
                ? employee.mobileNumber!
                : 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.business_outlined,
            label: l10n.departmentLabel,
            value:
                (employee.departmentName != null &&
                    employee.departmentName!.isNotEmpty)
                ? employee.departmentName!
                : 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.payments_outlined,
            label: l10n.dailyWageLabel,
            value: employee.dailyWage != null
                ? '${employee.dailyWage!.toStringAsFixed(2)} EGP'
                : '—',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePeriodCard(
    BuildContext context,
    Employee employee,
    WorkPeriod period,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('yyyy-MM-dd').format(period.arrivalDate);
    final shiftLabel = period.arrivalTimeType == 'Morning'
        ? l10n.morningShiftLabel
        : l10n.afternoonShiftLabel;

    final workedDays = WorkPeriodCalculator.calculateWorkedDays(
      arrivalDate: period.arrivalDate,
      arrivalTimeType: period.arrivalTimeType,
    );
    final baseWage = period.dailyWage > 0
        ? period.dailyWage
        : (employee.dailyWage ?? 0.0);
    final totalSalary = WorkPeriodCalculator.calculateTotalSalary(
      workedDays: workedDays,
      dailyWage: baseWage,
    );
    final netPayable = WorkPeriodCalculator.calculateNetPayable(
      totalSalary: totalSalary,
      totalWithdrawals: period.totalWithdrawals,
      totalBonuses: period.totalBonuses,
    );

    final workedDaysStr = WorkPeriodCalculator.formatWorkedDays(workedDays);
    final baseRateStr = '${baseWage.toStringAsFixed(2)} EGP';
    final totalSalaryStr = '${totalSalary.toStringAsFixed(2)} EGP';
    final netPayableStr = '${netPayable.toStringAsFixed(2)} EGP';

    return AppContentCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activeEmployment,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      l10n.activeWorkPeriodDetails,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  AppStatusBadge(
                    label: period.isSynced ? l10n.synced : l10n.pendingSync,
                    icon: period.isSynced
                        ? Icons.check_circle_outline_rounded
                        : Icons.cloud_upload_outlined,
                    color: period.isSynced
                        ? theme.colorScheme.primary
                        : Colors.amber.shade700,
                  ),
                  if (!period.isSynced) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Discard Offline Record',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () =>
                          _showDiscardConfirmation(context, period.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetailTile(
            context,
            title: l10n.arrivalDate,
            subtitle: dateStr,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 10),
          _buildDetailTile(
            context,
            title: l10n.shift,
            subtitle: shiftLabel,
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 520;
              final spacing = isWide ? 12.0 : 10.0;
              final crossAxisCount = isWide ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                  crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildKpiBlock(
                      context,
                      title: l10n.workedDays,
                      value: workedDaysStr,
                      icon: Icons.calendar_month_rounded,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildKpiBlock(
                      context,
                      title: l10n.baseRate,
                      value: baseRateStr,
                      icon: Icons.payments_rounded,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildKpiBlock(
                      context,
                      title: l10n.totalSalary,
                      value: totalSalaryStr,
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildKpiBlock(
                      context,
                      title: l10n.withdrawals,
                      value:
                          '-${period.totalWithdrawals.toStringAsFixed(2)} EGP',
                      icon: Icons.money_off_rounded,
                      color: Colors.red.shade700,
                      valueColor: Colors.red.shade700,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildKpiBlock(
                      context,
                      title: l10n.bonuses,
                      value: '+${period.totalBonuses.toStringAsFixed(2)} EGP',
                      icon: Icons.add_circle_outline_rounded,
                      color: Colors.green.shade700,
                      valueColor: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildKpiBlock(
                      context,
                      title: l10n.netPayable,
                      value: netPayableStr,
                      icon: Icons.savings_rounded,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppActionButton(
                      label: l10n.addWithdrawal,
                      isFilled: false,
                      color: Colors.orange.shade800,
                      leadingIcon: const Icon(
                        Icons.money_off_rounded,
                        size: 18,
                      ),
                      onTap: () {
                        AddFinancialRecordSheet.show(
                          context,
                          type: FinancialRecordType.withdrawal,
                          periodId: period.id,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    AppActionButton(
                      label: l10n.addBonus,
                      isFilled: false,
                      color: Colors.green.shade700,
                      leadingIcon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                      ),
                      onTap: () {
                        AddFinancialRecordSheet.show(
                          context,
                          type: FinancialRecordType.bonus,
                          periodId: period.id,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    AppActionButton(
                      label: l10n.completeAndArchivePeriod,
                      isFilled: true,
                      color: theme.colorScheme.error,
                      leadingIcon: const Icon(Icons.archive_outlined, size: 18),
                      onTap: () {
                        CompletePeriodSheet.show(
                          context,
                          period: period,
                          employee: employee,
                        );
                      },
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppActionButton(
                            label: l10n.addWithdrawal,
                            isFilled: false,
                            color: Colors.orange.shade800,
                            leadingIcon: const Icon(
                              Icons.money_off_rounded,
                              size: 18,
                            ),
                            onTap: () {
                              AddFinancialRecordSheet.show(
                                context,
                                type: FinancialRecordType.withdrawal,
                                periodId: period.id,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppActionButton(
                            label: l10n.addBonus,
                            isFilled: false,
                            color: Colors.green.shade700,
                            leadingIcon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            onTap: () {
                              AddFinancialRecordSheet.show(
                                context,
                                type: FinancialRecordType.bonus,
                                periodId: period.id,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppActionButton(
                      label: l10n.completeAndArchivePeriod,
                      isFilled: true,
                      color: theme.colorScheme.error,
                      leadingIcon: const Icon(Icons.archive_outlined, size: 18),
                      onTap: () {
                        CompletePeriodSheet.show(
                          context,
                          period: period,
                          employee: employee,
                        );
                      },
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBlock(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$title: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInactivePeriodCard(
    BuildContext context,
    EmployeeProfileLoaded state,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedArrivalDate);

    return AppContentCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noActiveWorkPeriod,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    Text(
                      l10n.noActiveWorkPeriodDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            l10n.arrivalDate,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: state.isSubmitting ? null : () => _pickArrivalDate(context),
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
              child: Text(dateStr, style: theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.shift,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedShift,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.schedule_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'Morning',
                child: Text(l10n.morningShiftLabel),
              ),
              DropdownMenuItem(
                value: 'Afternoon',
                child: Text(l10n.afternoonShiftLabel),
              ),
            ],
            onChanged: state.isSubmitting
                ? null
                : (val) {
                    if (val != null) {
                      setState(() {
                        _selectedShift = val;
                      });
                    }
                  },
          ),
          const SizedBox(height: 24),
          AppActionButton(
            label: l10n.startWorkPeriodAction,
            isFilled: true,
            isLoading: state.isSubmitting,
            loadingLabel: l10n.startingPeriod,
            leadingIcon: const Icon(Icons.play_arrow_rounded),
            onTap: state.isSubmitting
                ? null
                : () {
                    context.read<EmployeeProfileBloc>().add(
                      StartWorkPeriodSubmitted(
                        arrivalDate: _selectedArrivalDate,
                        arrivalTimeType: _selectedShift,
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  void _showDiscardConfirmation(BuildContext context, String periodId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard Offline Record'),
        content: const Text(
          'Are you sure you want to discard this unsynced work period record from local storage? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<EmployeeProfileBloc>().add(
                DiscardWorkPeriodRequested(periodId),
              );
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHistorySection(
    BuildContext context,
    List<WorkPeriod> history, [
    Employee? employee,
  ]) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.workHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (history.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${history.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 48,
                        color: theme.colorScheme.outline.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noWorkHistory,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _buildWorkHistoryItem(context, item, employee);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkHistoryItem(
    BuildContext context,
    WorkPeriod item, [
    Employee? employee,
  ]) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final arrivalStr = DateFormat.yMMMd().format(item.arrivalDate);
    final departureStr = item.departureDate != null
        ? DateFormat.yMMMd().format(item.departureDate!)
        : '-';

    var workedDays = item.totalWorkedDays ?? 0.0;
    if (workedDays == 0.0 && item.departureDate != null) {
      workedDays = WorkPeriodCalculator.calculateWorkedDays(
        arrivalDate: item.arrivalDate,
        departureDate: item.departureDate,
        arrivalTimeType: item.arrivalTimeType,
      );
    }
    final workedDaysStr = WorkPeriodCalculator.formatWorkedDays(workedDays);

    final wage = item.dailyWage > 0
        ? item.dailyWage
        : (employee?.dailyWage ?? 0.0);
    final calculatedTotalSalary =
        item.totalSalary ??
        WorkPeriodCalculator.calculateTotalSalary(
          workedDays: workedDays,
          dailyWage: wage,
        );
    final finalSalary =
        item.finalSalary ??
        WorkPeriodCalculator.calculateNetPayable(
          totalSalary: calculatedTotalSalary,
          totalWithdrawals: item.totalWithdrawals,
          totalBonuses: item.totalBonuses,
        );

    final isMorning = item.arrivalTimeType == 'Morning';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          '$arrivalStr → $departureStr',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMorning
                      ? Colors.blue.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMorning ? l10n.morning : l10n.afternoon,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMorning
                        ? Colors.blue.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: item.isSynced ? l10n.synced : l10n.pendingSync,
                icon: item.isSynced
                    ? Icons.check_circle_outline_rounded
                    : Icons.cloud_upload_outlined,
                color: item.isSynced
                    ? theme.colorScheme.primary
                    : Colors.amber.shade700,
              ),
              if (!item.isSynced) ...[
                const Spacer(),
                IconButton(
                  tooltip: 'Discard Offline Record',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _showDiscardConfirmation(context, item.id),
                ),
              ],
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              const spacing = 10.0;
              final crossAxisCount = isWide ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                  crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildHistoryMetricCard(
                      title: l10n.workedDays,
                      value: '$workedDaysStr ${l10n.days}',
                      icon: Icons.calendar_month_rounded,
                      color: Colors.blue.shade700,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildHistoryMetricCard(
                      title: l10n.baseRate,
                      value: '${item.dailyWage.toStringAsFixed(2)} EGP',
                      icon: Icons.payments_rounded,
                      color: Colors.teal.shade700,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildHistoryMetricCard(
                      title: l10n.totalSalary,
                      value: '${calculatedTotalSalary.toStringAsFixed(2)} EGP',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.indigo.shade600,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildHistoryMetricCard(
                      title: l10n.withdrawals,
                      value: '-${item.totalWithdrawals.toStringAsFixed(2)} EGP',
                      valueColor: Colors.red.shade700,
                      icon: Icons.money_off_rounded,
                      color: Colors.red.shade700,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildHistoryMetricCard(
                      title: l10n.bonuses,
                      value: '+${item.totalBonuses.toStringAsFixed(2)} EGP',
                      valueColor: Colors.green.shade700,
                      icon: Icons.add_circle_outline_rounded,
                      color: Colors.green.shade700,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildHistoryMetricCard(
                      title: l10n.finalSalary,
                      value: '${finalSalary.toStringAsFixed(2)} EGP',
                      valueColor: Colors.green.shade700,
                      icon: Icons.savings_rounded,
                      color: Colors.amber.shade800,
                      isBold: true,
                      theme: theme,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMetricCard({
    required String title,
    required String value,
    Color? valueColor,
    required IconData icon,
    required Color color,
    bool isBold = false,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
