// US05, US07, US09 a US15, US36
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Qué se sabe de la asesoría de llegada de la sede.
enum AdviceStatus {
  /// El conductor todavía no tiene un tiempo de llegada: hay que elegirlo.
  needsEta,

  /// La asesoría llegó y tiene categoría.
  available,

  /// No se pudo obtener, o llegó con una categoría desconocida: no se muestra
  /// ninguna (US15).
  unavailable,
}

/// La asesoría de un horizonte (15, 30, 45 o 60 minutos) para la tarjeta
/// «Cómo puede cambiar». Sin [advice], ese horizonte no está disponible.
class HorizonAdvice extends Equatable {
  const HorizonAdvice(this.horizon, this.advice);

  final ForecastHorizon horizon;
  final ArrivalAdvice? advice;

  /// Solo una asesoría con categoría se puede presentar.
  bool get isAvailable => advice != null && advice!.isAvailable;

  @override
  List<Object?> get props => [horizon, advice];
}

/// Qué cambió en la asesoría cuando cambió el tiempo de llegada (US14): el ETA
/// y la probabilidad de antes y de ahora, y la categoría si cambió. Se muestra
/// unos minutos ([AdviceChange.visibleFor]) y lo reemplaza el siguiente cambio.
class AdviceChange extends Equatable {
  const AdviceChange({
    required this.previousEta,
    required this.eta,
    required this.previousProbability,
    required this.probability,
    required this.at,
    this.previousCategory,
    this.category,
  });

  /// Cuánto se muestra el cambio, contado con el reloj monótono.
  static const Duration visibleFor = Duration(minutes: 3);

  final int previousEta;
  final int eta;
  final double previousProbability;
  final double probability;
  final ArrivalCategory? previousCategory;
  final ArrivalCategory? category;

  /// Cuándo se detectó (reloj monótono).
  final Duration at;

  bool get categoryChanged => previousCategory != category;

  /// ¿Subió la probabilidad de encontrar espacio?
  bool get improved => probability > previousProbability;

  bool isVisible(Clock clock) => clock.monotonic() - at < visibleFor;

  @override
  List<Object?> get props => [
    previousEta,
    eta,
    previousProbability,
    probability,
    previousCategory,
    category,
    at,
  ];
}

/// Lo que muestra Inicio de la sede elegida: su ocupación, la asesoría para el
/// tiempo de llegada, cómo puede cambiar a 15, 30, 45 y 60 minutos y, si está
/// llena, cuándo se libera un espacio. Es estado de presentación: combina tres
/// contextos y no es una entidad del dominio.
class ArrivalOverview extends Equatable {
  const ArrivalOverview({
    required this.lot,
    this.occupancy,
    this.occupancyFailure,
    this.advice,
    this.adviceStatus = AdviceStatus.needsEta,
    this.horizons = const [],
    this.nextAvailability,
    this.link,
    this.lastChange,
  });

  final ParkingLot lot;

  /// La ocupación; `null` si no se pudo leer ([occupancyFailure]) o la sede no
  /// tiene distribución publicada.
  final LotOccupancy? occupancy;
  final Failure? occupancyFailure;

  /// La asesoría para el tiempo de llegada vigente.
  final ArrivalAdvice? advice;
  final AdviceStatus adviceStatus;

  /// Los cuatro horizontes, en orden (con o sin asesoría cada uno).
  final List<HorizonAdvice> horizons;

  /// Cuándo se libera un espacio; solo si la sede está llena (US36).
  final NextAvailability? nextAvailability;

  /// Estado **real** de la conexión en tiempo real (`null` si no se observa).
  final RealtimeLink? link;

  /// Qué cambió en la asesoría la última vez que cambió el tiempo de llegada.
  final AdviceChange? lastChange;

  /// La hora actual **del servidor** (la que informó con la asesoría o la
  /// ocupación más el tiempo transcurrido), nunca la del teléfono; `null` si no
  /// se ha recibido ninguna.
  DateTime? serverNow(Clock clock) {
    final advice = this.advice;
    final adviceServer = advice?.serverTime;
    final adviceReceived = advice?.receivedAt;
    if (adviceServer != null && adviceReceived != null) {
      return adviceServer.add(clock.monotonic() - adviceReceived);
    }
    final freshness = occupancy?.freshness;
    final received = freshness?.receivedAt;
    if (freshness != null && received != null) {
      return freshness.serverTime.add(clock.monotonic() - received);
    }
    return null;
  }

  /// La sede no tiene distribución publicada: se presenta sin disponibilidad
  /// (US04 esc. 2).
  bool get hasNoData => !lot.hasPublishedLayout;

  /// ¿Los datos de ocupación salieron de la caché por falta de conexión?
  bool get isOffline => occupancy?.isFromCache ?? false;

  /// ¿Faltan partes (ocupación, asesoría o algún horizonte)?
  bool get isPartial =>
      !hasNoData &&
      (occupancy == null ||
          adviceStatus == AdviceStatus.unavailable ||
          horizons.any((h) => !h.isAvailable));

  ArrivalOverview copyWith({
    LotOccupancy? occupancy,
    ArrivalAdvice? advice,
    AdviceStatus? adviceStatus,
    List<HorizonAdvice>? horizons,
    NextAvailability? nextAvailability,
    RealtimeLink? link,
    AdviceChange? lastChange,
    bool clearAdvice = false,
    bool clearNextAvailability = false,
    bool clearLink = false,
  }) => ArrivalOverview(
    lot: lot,
    occupancy: occupancy ?? this.occupancy,
    occupancyFailure: occupancy != null ? null : occupancyFailure,
    advice: clearAdvice ? null : (advice ?? this.advice),
    adviceStatus: adviceStatus ?? this.adviceStatus,
    horizons: horizons ?? this.horizons,
    nextAvailability: clearNextAvailability
        ? null
        : (nextAvailability ?? this.nextAvailability),
    link: clearLink ? null : (link ?? this.link),
    lastChange: lastChange ?? this.lastChange,
  );

  @override
  List<Object?> get props => [
    lot,
    occupancy,
    occupancyFailure,
    advice,
    adviceStatus,
    horizons,
    nextAvailability,
    link,
    lastChange,
  ];
}
