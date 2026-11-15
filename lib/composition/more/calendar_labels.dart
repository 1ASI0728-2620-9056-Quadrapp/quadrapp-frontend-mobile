// US35
import 'package:intl/intl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';

const AppTimeFormatter _time = AppTimeFormatter();

String eventTypeLabel(AppLocalizations l10n, CalendarEventType type) =>
    switch (type) {
      CalendarEventType.campusEvent => l10n.more_typeEvent,
      CalendarEventType.classes => l10n.more_typeClasses,
      CalendarEventType.exams => l10n.more_typeExams,
      CalendarEventType.recess => l10n.more_typeRecess,
    };

String impactLabel(AppLocalizations l10n, DemandImpact impact) =>
    switch (impact) {
      DemandImpact.low => l10n.more_impactLow,
      DemandImpact.medium => l10n.more_impactMedium,
      DemandImpact.high => l10n.more_impactHigh,
    };

QaTone impactTone(DemandImpact impact) => switch (impact) {
  DemandImpact.low => QaTone.free,
  DemandImpact.medium => QaTone.limited,
  DemandImpact.high => QaTone.full,
};

/// «Todo el campus», «Monterrico» o «Monterrico · Pabellón C».
String eventScope(AppLocalizations l10n, CalendarEvent event) {
  final lot = event.lotName;
  if (event.isCampusWide || lot == null) return l10n.more_wholeCampus;
  final zone = event.zoneName;
  return zone == null ? lot : '$lot · $zone';
}

/// El último día de un periodo de días completos (su fin es la medianoche
/// siguiente).
DateTime _lastDay(CalendarEvent event) =>
    event.endsAt.subtract(const Duration(minutes: 1));

/// La fecha corta de la insignia: «08 oct» o «05–09 oct» (o «28 oct–02 nov»).
String eventBadge(CalendarEvent event, String locale) {
  final start = _time.toLima(event.startsAt);
  final end = _time.toLima(
    event.type.isAcademicPeriod ? _lastDay(event) : event.startsAt,
  );
  final day = DateFormat('dd', locale);
  final dayMonth = DateFormat('dd MMM', locale);
  if (start.year == end.year && start.month == end.month) {
    return start.day == end.day
        ? dayMonth.format(start)
        : '${day.format(start)}–${dayMonth.format(end)}';
  }
  return '${dayMonth.format(start)}–${dayMonth.format(end)}';
}

/// El detalle de la fila: el horario de un evento («09:00–17:00») o el tipo
/// del periodo («Exámenes»), y su alcance.
String eventDetail(AppLocalizations l10n, CalendarEvent event) {
  final scope = eventScope(l10n, event);
  if (event.type.isAcademicPeriod) {
    return '${eventTypeLabel(l10n, event.type)} · $scope';
  }
  final hm = DateFormat.Hm();
  final start = hm.format(_time.toLima(event.startsAt));
  final end = hm.format(_time.toLima(event.endsAt));
  return '$start–$end · $scope';
}

/// La fecha completa para la ventana de detalle: «jue., 15 oct. 2026,
/// 09:00–17:00» o «del 5 al 9 oct. 2026».
String eventWhen(AppLocalizations l10n, CalendarEvent event, String locale) {
  final date = DateFormat.yMMMEd(locale);
  final start = _time.toLima(event.startsAt);
  if (event.type.isAcademicPeriod) {
    final end = _time.toLima(_lastDay(event));
    final same =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return same
        ? date.format(start)
        : l10n.more_dateRange(date.format(start), date.format(end));
  }
  final hm = DateFormat.Hm();
  return '${date.format(start)} · ${hm.format(start)}–'
      '${hm.format(_time.toLima(event.endsAt))}';
}
