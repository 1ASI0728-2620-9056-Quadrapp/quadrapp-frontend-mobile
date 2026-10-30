import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/mock_notifications_state.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/datasources/notification_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/dto/notification_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

const _locales = {'en-US', 'es-419'};
const _platforms = {'ANDROID', 'IOS', 'WEB'};

/// Un error con los errores por campo (RFC 9457): 400 por defecto; 409 para un
/// conflicto con un recurso existente.
Never _invalid(String field, String code, {int status = 400}) =>
    throw mockHttpError(
      status,
      title: status == 409 ? 'Conflict' : 'Bad Request',
      extra: {
        'errors': {
          field: [code],
        },
      },
    );

/// Suscripciones desde [MockWorld]. Valida como el servidor: días 1 a 7,
/// horas `"HH:mm"` con `to` posterior a `from`, estacionamiento existente y
/// sin duplicados (409). El JSON sigue docs/07 y se lee con el mismo DTO que el
/// datasource HTTP.
class MockAlertSubscriptionRemoteDataSource
    implements AlertSubscriptionRemoteDataSource {
  const MockAlertSubscriptionRemoteDataSource(this._world);

  final MockWorld _world;

  MockNotificationsState get _state => _world.notifications;

  @override
  Future<List<AlertSubscriptionDto>> list() async {
    await _world.gate();
    return [
      for (final sub in _state.subscriptions)
        AlertSubscriptionDto.fromJson(sub.toJson()),
    ];
  }

  @override
  Future<AlertSubscriptionDto> create(
    AlertSubscriptionRequestDto request,
  ) async {
    await _world.gate();
    if (_world.lot(request.lotId) == null) {
      throw mockHttpError(404, title: 'Not Found');
    }
    final days = request.days.toSet();
    if (days.isEmpty || days.any((day) => day < 1 || day > 7)) {
      _invalid('days', '1..7');
    }
    if (!_hhmm.hasMatch(request.from)) _invalid('from', 'HH:mm');
    if (!_hhmm.hasMatch(request.to)) _invalid('to', 'HH:mm');
    // "HH:mm" se ordena igual como texto que como hora.
    if (request.to.compareTo(request.from) <= 0) _invalid('to', 'after-from');

    final sortedDays = days.toList()..sort();
    final duplicate = _state.active.any(
      (sub) =>
          sub.lotId == request.lotId &&
          sub.from == request.from &&
          sub.to == request.to &&
          sub.days.toSet().difference(days).isEmpty &&
          days.difference(sub.days.toSet()).isEmpty,
    );
    if (duplicate) _invalid('slot', 'duplicate', status: 409);

    final created = MockSubscription(
      id: _state.nextSubscriptionId(),
      lotId: request.lotId,
      days: sortedDays,
      from: request.from,
      to: request.to,
    );
    _state.subscriptions.add(created);
    return AlertSubscriptionDto.fromJson(created.toJson());
  }

  @override
  Future<AlertSubscriptionDto> setActive(
    AlertSubscriptionId id,
    AlertSubscriptionActiveRequestDto request,
  ) async {
    await _world.gate();
    final found = _state.subscriptions
        .where((sub) => sub.id == id.value)
        .firstOrNull;
    if (found == null) throw mockHttpError(404, title: 'Not Found');
    // Reactivar una franja idéntica a otra activa choca con ella (409).
    if (request.active && !found.active) {
      final duplicate = _state.active.any(
        (sub) =>
            sub.lotId == found.lotId &&
            sub.from == found.from &&
            sub.to == found.to &&
            sub.days.toSet().difference(found.days.toSet()).isEmpty &&
            found.days.toSet().difference(sub.days.toSet()).isEmpty,
      );
      if (duplicate) _invalid('slot', 'duplicate', status: 409);
    }
    found.active = request.active;
    return AlertSubscriptionDto.fromJson(found.toJson());
  }

  @override
  Future<void> remove(AlertSubscriptionId id) async {
    await _world.gate();
    final before = _state.subscriptions.length;
    _state.subscriptions.removeWhere((sub) => sub.id == id.value);
    if (_state.subscriptions.length == before) {
      throw mockHttpError(404, title: 'Not Found');
    }
  }
}

/// Preferencias desde [MockWorld]. `PUT` reemplaza todos los campos.
class MockNotificationPreferencesRemoteDataSource
    implements NotificationPreferencesRemoteDataSource {
  const MockNotificationPreferencesRemoteDataSource(this._world);

  final MockWorld _world;

  MockNotificationsState get _state => _world.notifications;

  @override
  Future<NotificationPreferencesDto> get() async {
    await _world.gate();
    return NotificationPreferencesDto.fromJson(_state.preferencesJson());
  }

  @override
  Future<NotificationPreferencesDto> save(
    NotificationPreferencesDto dto,
  ) async {
    await _world.gate();
    if (!_locales.contains(dto.locale)) _invalid('locale', 'en-US|es-419');
    _state
      ..pushEnabled = dto.pushEnabled
      ..saturationAlerts = dto.saturationAlerts
      ..lowArrivalAlerts = dto.lowArrivalAlerts
      ..staleDataAlerts = dto.staleDataAlerts
      ..eventAlerts = dto.eventAlerts
      ..locale = dto.locale;
    return NotificationPreferencesDto.fromJson(_state.preferencesJson());
  }
}

/// Tokens de dispositivo desde [MockWorld]. Registrar es idempotente; dar de
/// baja uno que no existe responde 404 (la app lo trata como éxito).
class MockDeviceTokenRemoteDataSource implements DeviceTokenRemoteDataSource {
  const MockDeviceTokenRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<void> register(DeviceTokenRequestDto request) async {
    await _world.gate();
    if (request.token.isEmpty || request.token.length > 512) {
      _invalid('token', 'invalid');
    }
    if (!_platforms.contains(request.platform)) _invalid('platform', 'invalid');
    _world.notifications.deviceTokens.add(request.token);
  }

  @override
  Future<void> unregister(DeviceTokenUnregisterRequestDto request) async {
    await _world.gate();
    if (!_world.notifications.deviceTokens.remove(request.token)) {
      throw mockHttpError(404, title: 'Not Found');
    }
  }
}
