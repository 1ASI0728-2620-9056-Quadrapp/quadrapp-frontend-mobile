// US14
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// «Tu llegada se actualizó hace 1 min», o «se acaba de actualizar» si pasaron
/// menos de 10 segundos (no «hace 0 s»).
String etaUpdatedText(AppLocalizations l10n, Duration age) =>
    age < const Duration(seconds: 10)
    ? l10n.eta_updatedNow
    : l10n.eta_updatedAgo(lotAgeText(l10n, age));
