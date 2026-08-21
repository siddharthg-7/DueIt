import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import '../../domain/entities/dashboard_financial_metrics.dart';
import '../../domain/services/dashboard_financial_calculator.dart';

export '../../domain/entities/dashboard_financial_metrics.dart';
export '../../domain/services/dashboard_financial_calculator.dart';

/// Provider for reactive Dashboard financial planning and collection metrics
final dashboardMetricsProvider = Provider<DashboardFinancialMetrics>((ref) {
  final duesState = ref.watch(duesControllerProvider);
  final dues = duesState.dues;
  final payments = duesState.payments;

  return DashboardFinancialCalculator.calculate(
    dues: dues,
    payments: payments,
  );
});
