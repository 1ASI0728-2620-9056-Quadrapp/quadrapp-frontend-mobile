// US13, US15 (la categoría se muestra traducida, nunca el código)
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El tono de una categoría de llegada: buena es verde, limitada es ámbar y
/// baja es roja. Cada tono lleva además su ícono y su texto: la categoría
/// nunca se comunica solo con el color.
QaTone toneOfCategory(ArrivalCategory category) => switch (category) {
  ArrivalCategory.high => QaTone.free,
  ArrivalCategory.limited => QaTone.limited,
  ArrivalCategory.low => QaTone.full,
};

/// «Buena disponibilidad», «Disponibilidad limitada» o «Poca disponibilidad».
String categoryLabel(AppLocalizations l10n, ArrivalCategory category) =>
    switch (category) {
      ArrivalCategory.high => l10n.home_categoryHigh,
      ArrivalCategory.limited => l10n.home_categoryLimited,
      ArrivalCategory.low => l10n.home_categoryLow,
    };

/// La frase del héroe para una categoría.
String categoryStatement(AppLocalizations l10n, ArrivalCategory category) =>
    switch (category) {
      ArrivalCategory.high => l10n.home_statementHigh,
      ArrivalCategory.limited => l10n.home_statementLimited,
      ArrivalCategory.low => l10n.home_statementLow,
    };

/// «Alta», «Media» o «Baja»: el nivel de confianza (otro tipo distinto de la
/// categoría de llegada, aunque comparta algunas palabras).
String confidenceLabel(AppLocalizations l10n, ConfidenceLevel level) =>
    switch (level) {
      ConfidenceLevel.high => l10n.home_confidenceHigh,
      ConfidenceLevel.medium => l10n.home_confidenceMedium,
      ConfidenceLevel.low => l10n.home_confidenceLow,
    };

/// El porcentaje de una probabilidad de 0 a 1, redondeado: «82».
int percentOf(double probability) => (probability * 100).round().clamp(0, 100);
