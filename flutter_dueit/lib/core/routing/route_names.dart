abstract class RouteNames {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String businessSetup = '/business-setup';

  // Shell Tabs
  static const String dashboard = '/dashboard';
  static const String dues = '/dues';
  static const String customers = '/customers';
  static const String insights = '/insights';
  static const String settings = '/settings';

  // Drilldown Sub-routes
  static const String customerDetails = '/customer/:id';
  static const String dueDetails = '/due/:id';
  static const String addDue = '/add-due';
  static const String notifications = '/notifications';
}
