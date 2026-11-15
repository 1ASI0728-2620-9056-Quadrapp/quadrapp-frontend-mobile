// US06, US08
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El tono de la píldora de disponibilidad.
QaTone toneOfAvailability(SpaceAvailability availability) =>
    switch (availability) {
      SpaceAvailability.good => QaTone.free,
      SpaceAvailability.limited => QaTone.limited,
      SpaceAvailability.full => QaTone.full,
      SpaceAvailability.noData => QaTone.unknown,
    };

/// «Buena», «Limitada», «Llena» o «Sin datos»: traducidos, nunca el código.
String availabilityLabel(
  AppLocalizations l10n,
  SpaceAvailability availability,
) => switch (availability) {
  SpaceAvailability.good => l10n.zones_availabilityGood,
  SpaceAvailability.limited => l10n.zones_availabilityLimited,
  SpaceAvailability.full => l10n.zones_availabilityFull,
  SpaceAvailability.noData => l10n.zones_availabilityNoData,
};

/// El estado de un espacio en una palabra.
String spaceStatusLabel(AppLocalizations l10n, SpaceStatus status) =>
    switch (status) {
      SpaceStatus.free => l10n.space_free,
      SpaceStatus.occupied => l10n.space_occupied,
      SpaceStatus.unknown => l10n.space_unknown,
    };

/// Por qué un espacio no tiene información confiable (US08).
String unknownReasonLabel(AppLocalizations l10n, UnknownReason? reason) =>
    switch (reason) {
      UnknownReason.noHeartbeat => l10n.zones_reasonNoHeartbeat,
      UnknownReason.lowBattery => l10n.zones_reasonLowBattery,
      UnknownReason.noSensor => l10n.zones_reasonNoSensor,
      null => l10n.zones_reasonWaiting,
    };

/// El tono de un estado de espacio.
QaTone toneOfSpace(SpaceStatus status) => switch (status) {
  SpaceStatus.free => QaTone.free,
  SpaceStatus.occupied => QaTone.occupied,
  SpaceStatus.unknown => QaTone.unknown,
};
