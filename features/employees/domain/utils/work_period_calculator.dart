class WorkPeriodCalculator {
  const WorkPeriodCalculator._();

  static double calculateWorkedDays({
    required DateTime arrivalDate,
    DateTime? departureDate,
    required String arrivalTimeType,
  }) {
    final endDate = departureDate ?? DateTime.now();
    final arrivalOnly = DateTime(
      arrivalDate.year,
      arrivalDate.month,
      arrivalDate.day,
    );
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    if (endOnly.isBefore(arrivalOnly)) return 0.0;

    final daysDiff = endOnly.difference(arrivalOnly).inDays;
    final adjustment = arrivalTimeType == 'Morning' ? 1.0 : 0.5;
    return daysDiff + adjustment;
  }

  static double calculateTotalSalary({
    required double workedDays,
    required double dailyWage,
  }) {
    return workedDays * dailyWage;
  }

  static double calculateNetPayable({
    required double totalSalary,
    required double totalWithdrawals,
    required double totalBonuses,
  }) {
    return totalSalary - totalWithdrawals + totalBonuses;
  }

  static String formatWorkedDays(double workedDays) {
    return workedDays % 1 == 0
        ? workedDays.toInt().toString()
        : workedDays.toStringAsFixed(1);
  }
}
