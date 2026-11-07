// US13, US14, TS08 (a Quadrapp solo llegan los minutos del ETA)
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Por qué no hay ETA aunque se pueda calcular.
enum EtaIssue {
  /// El conductor está a más de 2 horas del campus: la asesoría solo admite
  /// hasta 120 minutos (US13 esc. 2). Cuando se acerque, aparece sola.
  tooFar,
}

/// Lo que se sabe del tiempo de llegada del conductor.
class EtaState extends Equatable {
  const EtaState({
    this.estimate,
    this.manualMinutes,
    this.permission,
    this.hasDestination = false,
    this.isEstimating = false,
    this.autoEnabled = true,
    this.trafficEnabled = false,
    this.trafficAvailable = false,
    this.updatedAt,
    this.issue,
  });

  /// El ETA vigente: el manual (que baja con el tiempo) si el conductor lo
  /// eligió; si no, el estimado con su ubicación; `null` si no hay ninguno (el
  /// conductor debe elegirlo).
  final EtaEstimate? estimate;

  /// Los minutos que eligió el conductor a mano, si eligió (los que eligió, no
  /// los que quedan).
  final int? manualMinutes;

  /// El último estado conocido del permiso de ubicación (`null` si no se
  /// consultó).
  final LocationPermissionStatus? permission;

  /// ¿La sede elegida tiene coordenadas? Sin ellas solo hay ETA manual.
  final bool hasDestination;

  /// Se está calculando el ETA automático.
  final bool isEstimating;

  /// El modo automático está encendido (el conductor puede apagarlo).
  final bool autoEnabled;

  /// El conductor activó el tráfico en tiempo real: su posición, redondeada,
  /// va al proveedor de mapas (no a Quadrapp).
  final bool trafficEnabled;

  /// Hay un proveedor de mapas (sin clave no lo hay y el interruptor no se
  /// ofrece).
  final bool trafficAvailable;

  /// Cuándo se calculó por última vez el ETA (reloj monótono), aunque no haya
  /// cambiado lo bastante para publicar uno nuevo. `null` sin ETA.
  final Duration? updatedAt;

  /// Por qué no hay ETA, si no hay y no es solo «aún no eligió».
  final EtaIssue? issue;

  bool get isManual => manualMinutes != null;

  /// El tráfico se está usando: está activado y hay proveedor.
  bool get usesTraffic => trafficAvailable && trafficEnabled;

  /// ¿Se puede pedir la ubicación (después de explicar para qué)?
  bool get canUseLocation =>
      hasDestination && permission == LocationPermissionStatus.denied;

  EtaState copyWith({
    EtaEstimate? estimate,
    int? manualMinutes,
    LocationPermissionStatus? permission,
    bool? hasDestination,
    bool? isEstimating,
    bool? autoEnabled,
    bool? trafficEnabled,
    Duration? updatedAt,
    EtaIssue? issue,
    bool clearEstimate = false,
    bool clearManual = false,
    bool clearUpdatedAt = false,
    bool clearIssue = false,
  }) => EtaState(
    estimate: clearEstimate ? null : (estimate ?? this.estimate),
    manualMinutes: clearManual ? null : (manualMinutes ?? this.manualMinutes),
    permission: permission ?? this.permission,
    hasDestination: hasDestination ?? this.hasDestination,
    isEstimating: isEstimating ?? this.isEstimating,
    autoEnabled: autoEnabled ?? this.autoEnabled,
    trafficEnabled: trafficEnabled ?? this.trafficEnabled,
    trafficAvailable: trafficAvailable,
    updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    issue: clearIssue ? null : (issue ?? this.issue),
  );

  @override
  List<Object?> get props => [
    estimate,
    manualMinutes,
    permission,
    hasDestination,
    isEstimating,
    autoEnabled,
    trafficEnabled,
    trafficAvailable,
    updatedAt,
    issue,
  ];
}

Stream<void> _everyMinute() =>
    Stream<void>.periodic(const Duration(minutes: 1));

/// El tiempo de llegada, compartido por Inicio y Predicción. Lo manual manda;
/// si el conductor no eligió, se estima con su ubicación (si dio el permiso y
/// el modo automático está encendido), con el tráfico del momento si lo activó
/// y, si no, en el teléfono. **A Quadrapp solo llegan los minutos** (TS08).
///
/// Se mantiene al día solo (US14): cada minuto, en primer plano, se vuelve a
/// calcular y el ETA manual baja con el reloj. En el ETA automático, un cambio
/// de menos de 2 minutos se ignora (es ruido del tráfico o del GPS) y no se
/// publica un ETA nuevo; al llegar siempre se publica.
///
/// - Sin coordenadas de la sede, sin permiso o sin posición, no hay ETA
///   automático y la app sigue en modo manual, sin mostrar un error.
/// - A más de 2 horas ([EtaIssue.tooFar]) no hay ETA: la asesoría solo admite
///   hasta 120 minutos.
/// - El permiso se pide solo con [useLocation] o al encender el modo
///   automático, que la pantalla llama después de explicar para qué (nunca al
///   abrir la app).
/// - Las preferencias (modo automático y tráfico) se guardan en el teléfono y
///   se borran al cerrar sesión.
class EtaCubit extends Cubit<EtaState> {
  EtaCubit({
    required this._estimateArrivalEta,
    required this._getPermissionStatus,
    required this._requestPermission,
    required this._getPreferences,
    required this._savePreferences,
    required this._clock,
    bool trafficAvailable = false,
    this._ticker = _everyMinute,
  }) : super(EtaState(trafficAvailable: trafficAvailable));

  final EstimateArrivalEta _estimateArrivalEta;
  final GetLocationPermissionStatus _getPermissionStatus;
  final RequestLocationPermission _requestPermission;
  final GetEtaPreferences _getPreferences;
  final SaveEtaPreferences _savePreferences;
  final Clock _clock;
  final Stream<void> Function() _ticker;

  // Se cancela en `_stopTimer` (al terminar el ETA y en `close`).
  StreamSubscription<void>? _timer;
  GeoPoint? _destination;
  bool _preferencesLoaded = false;

  /// Cuándo eligió el conductor su ETA manual (reloj monótono): desde ahí baja.
  Duration? _manualSetAt;

  /// Cambió la sede elegida: recalcula con sus coordenadas.
  Future<void> setDestination(ParkingLot? lot) async {
    _destination = lot != null && lot.hasCoordinates
        ? GeoPoint(latitude: lot.latitude!, longitude: lot.longitude!)
        : null;
    emit(state.copyWith(hasDestination: _destination != null));
    await refresh(force: true);
  }

  /// Vuelve a decidir el ETA (lo manual manda). Con [force] publica el
  /// resultado aunque cambie poco (una decisión del conductor o de la sede).
  Future<void> refresh({bool force = false}) async {
    if (!_preferencesLoaded) await _loadPreferences();
    if (isClosed) return;
    final chosen = state.manualMinutes;
    final permission = (await _getPermissionStatus(
      const NoParams(),
    )).valueOrNull;
    if (isClosed) return;
    final canAutomate =
        state.autoEnabled &&
        _destination != null &&
        permission == LocationPermissionStatus.granted;
    if (chosen == null && !canAutomate) {
      _stopTimer();
      emit(
        state.copyWith(
          permission: permission,
          clearEstimate: true,
          clearIssue: true,
          clearUpdatedAt: true,
          isEstimating: false,
        ),
      );
      return;
    }

    final remaining = chosen == null ? null : _remaining(chosen);
    emit(state.copyWith(permission: permission, isEstimating: chosen == null));
    final result = await _estimateArrivalEta(
      EstimateArrivalEtaParams(
        destination: _destination,
        manualMinutes: remaining,
        useTraffic: state.usesTraffic,
      ),
    );
    if (isClosed) return;
    final now = _clock.monotonic();
    switch (result) {
      case Err():
        // Más de 120 minutos: sin ETA, con el motivo. Sigue mirando por si el
        // conductor se acerca.
        emit(
          state.copyWith(
            clearEstimate: true,
            isEstimating: false,
            issue: EtaIssue.tooFar,
            updatedAt: now,
          ),
        );
        _startTimer();
      case Success(value: final estimate):
        if (estimate == null) {
          emit(
            state.copyWith(
              clearEstimate: true,
              clearIssue: true,
              clearUpdatedAt: true,
              isEstimating: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              estimate: _stable(estimate, force: force),
              clearIssue: true,
              isEstimating: false,
              updatedAt: now,
            ),
          );
        }
        // Se sigue mirando mientras haya algo que se actualice solo: el ETA
        // automático, o el manual que aún no llegó a cero.
        if (canAutomate && chosen == null || (remaining ?? 0) > 0) {
          _startTimer();
        } else {
          _stopTimer();
        }
    }
  }

  /// El conductor eligió su tiempo de llegada a mano. Fuera de 0 a 120 se
  /// ignora (la pantalla no lo ofrece). Desde ese momento baja solo con el
  /// reloj: «llego en 20 minutos» es una hora de llegada, no un número fijo.
  Future<void> chooseManual(int minutes) async {
    if (EtaMinutes.create(minutes).valueOrNull == null) return;
    _manualSetAt = _clock.monotonic();
    emit(state.copyWith(manualMinutes: minutes));
    await refresh(force: true);
  }

  /// El conductor quiere el ETA automático: quita lo manual, enciende el modo
  /// automático y, si el permiso aún se puede pedir, lo pide (la pantalla ya
  /// explicó para qué).
  Future<void> useLocation() async {
    _manualSetAt = null;
    emit(state.copyWith(clearManual: true, autoEnabled: true));
    await _savePreferences(_preferences);
    final permission = (await _getPermissionStatus(
      const NoParams(),
    )).valueOrNull;
    if (permission == LocationPermissionStatus.denied) {
      await _requestPermission(const NoParams());
    }
    await refresh(force: true);
  }

  /// Enciende o apaga el modo automático. Apagado, la app no usa la ubicación y
  /// solo hay ETA manual; encendido, equivale a [useLocation].
  Future<void> setAutoEnabled({required bool enabled}) async {
    if (enabled) return useLocation();
    emit(state.copyWith(autoEnabled: false));
    await _savePreferences(_preferences);
    await refresh(force: true);
  }

  /// Activa o desactiva el tráfico en tiempo real. Activarlo es la decisión del
  /// conductor de que su ubicación, redondeada, vaya al proveedor de mapas.
  Future<void> setTrafficEnabled({required bool enabled}) async {
    if (state.trafficEnabled == enabled) return;
    emit(state.copyWith(trafficEnabled: enabled));
    await _savePreferences(_preferences);
    await refresh(force: true);
  }

  EtaPreferences get _preferences => EtaPreferences(
    autoEnabled: state.autoEnabled,
    trafficEnabled: state.trafficEnabled,
  );

  Future<void> _loadPreferences() async {
    _preferencesLoaded = true;
    final preferences = (await _getPreferences(const NoParams())).valueOrNull;
    if (preferences == null || isClosed) return;
    emit(
      state.copyWith(
        autoEnabled: preferences.autoEnabled,
        trafficEnabled: preferences.trafficEnabled,
      ),
    );
  }

  /// Lo que le queda al ETA manual: baja con el reloj monótono, redondeando
  /// hacia arriba (a los 59 s de elegir 20 minutos todavía son 20).
  int _remaining(int chosen) {
    final since = _manualSetAt;
    if (since == null) return chosen;
    final left = chosen * 60 - (_clock.monotonic() - since).inSeconds;
    return left <= 0 ? 0 : (left / 60).ceil();
  }

  /// Un cambio pequeño del ETA no se publica: conserva el vigente mientras la
  /// fuente sea la misma y la diferencia sea menor que
  /// [EtaMinutes.minChangeToRecalculate]. Al llegar (0) y con [force], siempre.
  EtaEstimate _stable(EtaEstimate next, {required bool force}) {
    final previous = state.estimate;
    if (force ||
        previous == null ||
        previous.source != next.source ||
        // Lo manual baja con el reloj, sin ruido: se publica cada minuto.
        next.source == EtaSource.manual ||
        next.minutes.value == 0 ||
        next.minutes.changedEnoughFrom(previous.minutes)) {
      return next;
    }
    return previous;
  }

  void _startTimer() {
    _timer ??= _ticker().listen((_) => unawaited(refresh()));
  }

  void _stopTimer() {
    unawaited(_timer?.cancel());
    _timer = null;
  }

  @override
  Future<void> close() async {
    _stopTimer();
    return super.close();
  }
}
