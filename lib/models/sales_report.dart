class SalesReport {
  final String id;
  final DateTime date;
  final double totalSales;
  final int transactionCount;
  final double taxCollected;
  final Map<String, int> productsSold; // product name -> quantity
  final Map<String, double> categoryRevenue; // category -> revenue

  SalesReport({
    required this.id,
    required this.date,
    required this.totalSales,
    required this.transactionCount,
    required this.taxCollected,
    required this.productsSold,
    required this.categoryRevenue,
  });

  double get netSales => totalSales - taxCollected;
  double get averageTransaction => transactionCount > 0 ? totalSales / transactionCount : 0;
}

class ReportPeriod {
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  ReportPeriod({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  static ReportPeriod today() {
    final now = DateTime.now();
    return ReportPeriod(
      label: 'Today',
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return ReportPeriod(
      label: 'This Week',
      startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod thisMonth() {
    final now = DateTime.now();
    return ReportPeriod(
      label: 'This Month',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    return ReportPeriod(
      label: 'Last Month',
      startDate: lastMonth,
      endDate: DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, lastDayOfLastMonth.day, 23, 59, 59),
    );
  }
}
