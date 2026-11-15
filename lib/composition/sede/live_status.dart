// US07
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El chip con el estado **real** de la conexión en vivo; con los datos de la
/// caché, «sin conexión»; sin observación ([link] nulo), ningún chip.
QaLiveBadge? liveBadgeOf(
  AppLocalizations l10n, {
  required bool offline,
  RealtimeLink? link,
}) {
  final live = offline
      ? (QaLiveStatus.offline, l10n.home_liveOffline)
      : switch (link) {
          null => null,
          RealtimeLink.live => (QaLiveStatus.live, l10n.home_liveOnline),
          RealtimeLink.connecting => (
            QaLiveStatus.reconnecting,
            l10n.home_liveConnecting,
          ),
          RealtimeLink.reconnecting => (
            QaLiveStatus.reconnecting,
            l10n.home_liveReconnecting,
          ),
        };
  return live == null ? null : QaLiveBadge(status: live.$1, label: live.$2);
}

/// La causa de un error de carga, en palabras del conductor (nunca el mensaje
/// del servidor).
String loadErrorText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.lots_errorNetwork,
      _ => l10n.lots_errorGeneric,
    };
