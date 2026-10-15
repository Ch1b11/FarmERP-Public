import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class EmployeeUiHelper {
  const EmployeeUiHelper._();

  static String getInitials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  static String resolveMessage(AppLocalizations l10n, String keyOrMessage) {
    switch (keyOrMessage) {
      case 'employeeCreated':
        return l10n.employeeCreated;
      case 'employeeUpdated':
        return l10n.employeeUpdated;
      case 'employeeDeleted':
        return l10n.employeeDeleted;
      case 'employeeDeactivated':
        return l10n.employeeDeactivated;
      case 'startWorkPeriodSuccess':
        return l10n.startWorkPeriodSuccess;
      case 'withdrawalAddedSuccess':
        return l10n.withdrawalAddedSuccess;
      case 'bonusAddedSuccess':
        return l10n.bonusAddedSuccess;
      case 'periodCompletedSuccess':
        return l10n.periodCompletedSuccess;
      case 'deleteEmployeeActivePeriodWarning':
        return l10n.deleteEmployeeActivePeriodWarning;
      case 'deleteEmployeeHasHistory':
        return l10n.deleteEmployeeHasHistory;
      default:
        return keyOrMessage;
    }
  }

  static Color getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.amber.shade700;
  }
}
