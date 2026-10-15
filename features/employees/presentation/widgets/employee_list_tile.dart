import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_item_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/employee.dart';
import '../utils/employee_ui_helper.dart';

class EmployeeListTile extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeListTile({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivateEmployee),
        content: Text(
          '${l10n.deactivateEmployeePrompt}\n\n(${employee.fullName})',
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
              onDelete();
            },
            child: Text(l10n.deactivateEmployee),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppItemCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push('/employees/${employee.id}'),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          EmployeeUiHelper.getInitials(employee.firstName, employee.lastName),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        employee.fullName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (employee.jobTitle != null && employee.jobTitle!.isNotEmpty)
            Text(
              employee.jobTitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (employee.departmentName != null &&
              employee.departmentName!.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    employee.departmentName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: AppStatusBadge(
        label: employee.isSynced ? l10n.synced : l10n.pendingSync,
        icon: employee.isSynced
            ? Icons.check_circle_outline_rounded
            : Icons.cloud_upload_outlined,
        color: employee.isSynced
            ? theme.colorScheme.primary
            : Colors.amber.shade700,
      ),
      actions: [
        IconButton.outlined(
          tooltip: l10n.employeeProfile,
          icon: const Icon(Icons.person_outline, size: 18),
          onPressed: () => context.push('/employees/${employee.id}'),
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: l10n.editEmployee,
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: l10n.deleteEmployee,
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          onPressed: () => _showDeleteConfirmation(context),
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }
}
