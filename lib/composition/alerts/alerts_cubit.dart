// US23, US24, US33
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_state.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Alertas y preferencias: las preferencias de notificación (US24) y
/// las franjas a las que se suscribe el conductor (US23, US33).
///
/// Estados (`ViewState<AlertsOverview>`):
/// - `ViewLoading` (con `previous` al recargar): skeleton o el contenido;
/// - `ViewError`: no se pudo leer **nada** (con `previous` si ya había algo);
/// - `ViewData`: llegó todo;
/// - `ViewPartial`: llegó una parte (preferencias o franjas) y se ve lo que
///   hay.
///
/// Los interruptores cambian al instante y se guardan en segundo plano; si el
/// servidor no los guarda, vuelven a su valor y la pantalla lo avisa
/// ([notices]). El permiso de notificaciones solo se pide al activarlas o al
/// suscribirse a una franja, con contexto (docs/05, regla 11).
class AlertsCubit extends Cubit<ViewState<AlertsOverview>> {
  AlertsCubit({
    required this._getPreferences,
    required this._savePreferences,
    required this._listSubscriptions,
    required this._createSubscription,
    required this._setActive,
    required this._removeSubscription,
    required this._activateDevice,
  }) : super(const ViewInitial());

  final GetNotificationPreferences _getPreferences;
  final SaveNotificationPreferences _savePreferences;
  final ListAlertSubscriptions _listSubscriptions;
  final CreateAlertSubscription _createSubscription;
  final SetAlertSubscriptionActive _setActive;
  final RemoveAlertSubscription _removeSubscription;
  final ActivateDeviceNotifications _activateDevice;

  final StreamController<AlertsNotice> _notices =
      StreamController<AlertsNotice>.broadcast();

  /// Los avisos breves para la pantalla.
  Stream<AlertsNotice> get notices => _notices.stream;

  /// Cuántos cambios locales de preferencias hubo: un guardado solo reemplaza
  /// lo que se ve si no hubo cambios después de él.
  int _preferencesVersion = 0;

  /// Lo último que el servidor confirmó: a eso se vuelve si no guarda un
  /// cambio (sin pedirlo de nuevo, que puede fallar igual).
  NotificationPreferences? _confirmed;
  Future<void> _saves = Future<void>.value();

  AlertsOverview? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    ViewInitial() || ViewEmpty() => null,
  };

  /// Carga todo (primera carga, reintento y deslizar para recargar).
  Future<void> load() async {
    emit(ViewLoading(previous: _current));
    final results = await Future.wait([
      _getPreferences(const NoParams()),
      _listSubscriptions(const NoParams()),
    ]);
    if (isClosed) return;
    final preferencesResult = results[0] as Result<NotificationPreferences>;
    final subscriptionsResult = results[1] as Result<List<AlertSubscription>>;
    final preferences = preferencesResult.valueOrNull;
    final subscriptions = subscriptionsResult.valueOrNull;
    _confirmed = preferences ?? _confirmed;

    if (preferences == null && subscriptions == null) {
      emit(
        ViewError(
          preferencesResult.failureOrNull ?? const UnknownFailure(),
          previous: _current,
        ),
      );
      return;
    }
    final overview = AlertsOverview(
      preferences: preferences,
      subscriptions: subscriptions,
      preferencesFailure: preferencesResult.failureOrNull,
      subscriptionsFailure: subscriptionsResult.failureOrNull,
    );
    emit(
      preferences == null || subscriptions == null
          ? ViewPartial(
              overview,
              missing: {
                if (preferences == null) 'preferences',
                if (subscriptions == null) 'subscriptions',
              },
            )
          : ViewData(overview),
    );
  }

  Future<void> refresh() => load();

  // ------------------------------------------------------------ preferencias

  /// El interruptor general. Activar pide el permiso (con contexto) y registra
  /// este teléfono; si el conductor no lo da, el interruptor no cambia.
  /// Desactivar solo lo guarda: el servidor omite el envío (US24 esc. 2).
  Future<void> setPushEnabled({required bool enabled}) async {
    final preferences = _current?.preferences;
    if (preferences == null || preferences.pushEnabled == enabled) return;
    if (enabled) {
      switch (await _activateDevice(const NoParams())) {
        case Err():
          _notify(AlertsNotice.activationFailed);
          return;
        case Success(value: final activation):
          final notice = switch (activation) {
            DeviceActivation.registered => null,
            DeviceActivation.permissionDenied => AlertsNotice.permissionDenied,
            DeviceActivation.permissionBlocked =>
              AlertsNotice.permissionBlocked,
            DeviceActivation.tokenUnavailable ||
            DeviceActivation.registrationFailed =>
              AlertsNotice.activationFailed,
          };
          if (notice != null) {
            _notify(notice);
            return;
          }
      }
    }
    _changePreferences((p) => p.copyWith(pushEnabled: enabled));
  }

  /// Enciende o apaga una alerta de «Avísame cuando».
  Future<void> setPreference(
    AlertPreference kind, {
    required bool value,
  }) async {
    final preferences = _current?.preferences;
    if (preferences == null || preferenceValue(preferences, kind) == value) {
      return;
    }
    _changePreferences((p) => withPreference(p, kind, value: value));
  }

  /// Aplica el cambio al instante y lo guarda en segundo plano, de uno en uno
  /// y siempre con lo último que ve el conductor.
  void _changePreferences(
    NotificationPreferences Function(NotificationPreferences current) change,
  ) {
    final current = _current?.preferences;
    if (current == null) return;
    _preferencesVersion++;
    _update((overview) => overview.copyWith(preferences: change(current)));
    _saves = _saves.then((_) => _saveLatest());
  }

  Future<void> _saveLatest() async {
    final preferences = _current?.preferences;
    if (preferences == null || isClosed) return;
    final version = _preferencesVersion;
    switch (await _savePreferences(preferences)) {
      case Success(value: final saved):
        _confirmed = saved;
        if (version == _preferencesVersion) {
          _update((overview) => overview.copyWith(preferences: saved));
        }
      case Err():
        // El servidor no lo guardó: se vuelve a lo último que confirmó.
        _notify(AlertsNotice.saveFailed);
        final confirmed = _confirmed;
        if (confirmed != null && !isClosed) {
          _preferencesVersion++;
          _update((overview) => overview.copyWith(preferences: confirmed));
        }
    }
  }

  // ----------------------------------------------------------------- franjas

  /// Suscribe al conductor a una franja (US33 esc. 1) y habilita este teléfono
  /// (esc. 2). Devuelve el resultado para que la ventana de crear muestre sus
  /// errores (franja repetida, hora inválida, sin conexión); un permiso negado
  /// no es un error: la franja queda y se avisa.
  Future<Result<CreatedAlertSubscription>> createSubscription(
    CreateAlertSubscriptionParams params,
  ) async {
    final result = await _createSubscription(params);
    if (isClosed) return result;
    if (result case Success(value: final created)) {
      _update(
        (overview) => overview.copyWith(
          subscriptions: [...?overview.subscriptions, created.subscription],
        ),
      );
      _notify(switch (created.device) {
        DeviceActivation.registered => AlertsNotice.created,
        DeviceActivation.permissionDenied => AlertsNotice.createdDenied,
        DeviceActivation.permissionBlocked => AlertsNotice.createdBlocked,
        DeviceActivation.tokenUnavailable ||
        DeviceActivation.registrationFailed => AlertsNotice.createdNoDevice,
      });
    }
    return result;
  }

  /// Activa o desactiva una franja sin perderla (US33 esc. 3). Cambia al
  /// instante; si el servidor no lo acepta, vuelve atrás.
  Future<void> setSubscriptionActive(
    AlertSubscription subscription, {
    required bool active,
  }) async {
    if (subscription.active == active) return;
    _replaceSubscription(subscription.copyWith(active: active));
    final result = await _setActive(
      SetAlertSubscriptionActiveParams(id: subscription.id, active: active),
    );
    if (isClosed) return;
    switch (result) {
      case Success(value: final updated):
        _replaceSubscription(updated);
      case Err(:final failure):
        _replaceSubscription(subscription);
        _notify(
          failure is ValidationFailure && failure.errors.containsKey('slot')
              ? AlertsNotice.slotDuplicate
              : AlertsNotice.slotFailed,
        );
    }
  }

  /// Da de baja una franja definitivamente; las demás no cambian.
  Future<void> removeSubscription(AlertSubscription subscription) async {
    final result = await _removeSubscription(subscription.id);
    if (isClosed) return;
    if (result.isSuccess) {
      _update(
        (overview) => overview.copyWith(
          subscriptions: [
            for (final item
                in overview.subscriptions ?? const <AlertSubscription>[])
              if (item.id != subscription.id) item,
          ],
        ),
      );
      _notify(AlertsNotice.deleted);
    } else {
      _notify(AlertsNotice.deleteFailed);
    }
  }

  void _replaceSubscription(AlertSubscription updated) => _update(
    (overview) => overview.copyWith(
      subscriptions: [
        for (final item
            in overview.subscriptions ?? const <AlertSubscription>[])
          if (item.id == updated.id) updated else item,
      ],
    ),
  );

  // ------------------------------------------------------------------ estado

  void _notify(AlertsNotice notice) {
    if (!_notices.isClosed) _notices.add(notice);
  }

  /// Aplica [change] al contenido actual; si no hay contenido que mostrar, lo
  /// ignora.
  void _update(AlertsOverview Function(AlertsOverview current) change) {
    final current = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      _ => null,
    };
    if (current == null || isClosed) return;
    final next = change(current);
    emit(switch (state) {
      ViewPartial(:final missing) => ViewPartial(next, missing: missing),
      _ => ViewData(next),
    });
  }

  @override
  Future<void> close() async {
    await _notices.close();
    return super.close();
  }
}
