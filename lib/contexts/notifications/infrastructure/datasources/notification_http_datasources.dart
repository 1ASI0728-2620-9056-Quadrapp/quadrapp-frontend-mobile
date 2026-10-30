import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/datasources/notification_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/dto/notification_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

Map<String, dynamic> _asObject(Object? data, String what) {
  if (data is! Map<String, dynamic>) {
    throw ParseException('$what no es un objeto JSON.');
  }
  return data;
}

/// `/notification-subscriptions`.
class AlertSubscriptionHttpDataSource
    implements AlertSubscriptionRemoteDataSource {
  const AlertSubscriptionHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<AlertSubscriptionDto>> list() async {
    final response = await _dio.get<Object?>('/notification-subscriptions');
    final data = response.data;
    if (data is! List<dynamic>) {
      throw const ParseException('La lista de suscripciones no es un arreglo.');
    }
    return [
      for (final item in data)
        AlertSubscriptionDto.fromJson(_asObject(item, 'La suscripción')),
    ];
  }

  @override
  Future<AlertSubscriptionDto> create(
    AlertSubscriptionRequestDto request,
  ) async {
    final response = await _dio.post<Object?>(
      '/notification-subscriptions',
      data: request.toJson(),
    );
    return AlertSubscriptionDto.fromJson(
      _asObject(response.data, 'La suscripción'),
    );
  }

  @override
  Future<AlertSubscriptionDto> setActive(
    AlertSubscriptionId id,
    AlertSubscriptionActiveRequestDto request,
  ) async {
    final response = await _dio.patch<Object?>(
      '/notification-subscriptions/${id.value}',
      data: request.toJson(),
    );
    return AlertSubscriptionDto.fromJson(
      _asObject(response.data, 'La suscripción'),
    );
  }

  @override
  Future<void> remove(AlertSubscriptionId id) async {
    await _dio.delete<Object?>('/notification-subscriptions/${id.value}');
  }
}

/// `/notification-preferences`.
class NotificationPreferencesHttpDataSource
    implements NotificationPreferencesRemoteDataSource {
  const NotificationPreferencesHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<NotificationPreferencesDto> get() async {
    final response = await _dio.get<Object?>('/notification-preferences');
    return NotificationPreferencesDto.fromJson(
      _asObject(response.data, 'Las preferencias'),
    );
  }

  @override
  Future<NotificationPreferencesDto> save(
    NotificationPreferencesDto dto,
  ) async {
    final response = await _dio.put<Object?>(
      '/notification-preferences',
      data: dto.toJson(),
    );
    return NotificationPreferencesDto.fromJson(
      _asObject(response.data, 'Las preferencias'),
    );
  }
}

/// `/device-tokens`.
class DeviceTokenHttpDataSource implements DeviceTokenRemoteDataSource {
  const DeviceTokenHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<void> register(DeviceTokenRequestDto request) async {
    await _dio.post<Object?>('/device-tokens', data: request.toJson());
  }

  /// El token va en el cuerpo, nunca en la URL. La ruta es pública (sin sesión)
  /// para poder reintentar la baja pendiente después de cerrar sesión.
  @override
  Future<void> unregister(DeviceTokenUnregisterRequestDto request) async {
    await _dio.post<Object?>(
      '/device-tokens/unregister',
      data: request.toJson(),
    );
  }
}
