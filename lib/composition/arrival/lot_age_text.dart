// US05 esc. 4
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// La antigüedad de un dato como texto relativo: "20 s", "3 min" o "2 h" (con
/// "hace" o "ago" según el idioma). Siempre se calcula con la hora del
/// servidor más el tiempo transcurrido localmente, nunca con el reloj del
/// teléfono (`Freshness.age`).
String lotAgeText(AppLocalizations l10n, Duration age) {
  if (age.inSeconds < 60) return l10n.time_agoSeconds(age.inSeconds);
  if (age.inMinutes < 60) return l10n.time_agoMinutes(age.inMinutes);
  return l10n.time_agoHours(age.inHours);
}
