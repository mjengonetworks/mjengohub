/// Support feature route paths only (no screen imports).
/// Screens use this to navigate without importing [AppRoutes] (avoids circular imports).
abstract class SupportRoutePaths {
  SupportRoutePaths._();

  static const support = '/support';
  static const issue = '/support/issue';
  static const tickets = '/support/tickets';
  static const ticketDetail = '/support/ticket/detail';
  static const safety = '/support/safety';
}
