// US13 (mapa de la llegada); TS08: la posición se redondea y no se pide permiso
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_approximate_position.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

class _MockPermission extends Mock implements LocationPermissionGateway {}

class _MockPositions extends Mock implements PositionSource {}

void main() {
  late _MockPermission permission;
  late _MockPositions positions;
  late GetApproximatePosition useCase;

  setUp(() {
    permission = _MockPermission();
    positions = _MockPositions();
    useCase = GetApproximatePosition(
      permission: permission,
      positions: positions,
    );
  });

  test('con permiso, la posición redondeada a unos 100 m', () async {
    when(permission.status).thenAnswer(
      (_) async => LocationPermissionStatus.granted,
    );
    when(positions.currentPosition).thenAnswer(
      (_) async =>
          const GeoPoint(latitude: -12.103_456, longitude: -76.962_987),
    );

    final result = await useCase(const NoParams());

    expect(
      result,
      isA<Success<GeoPoint?>>().having(
        (s) => s.value,
        'value',
        const GeoPoint(latitude: -12.103, longitude: -76.963),
      ),
    );
    verifyNever(permission.request);
  });

  test('sin permiso: null, sin pedirlo ni leer la posición', () async {
    when(permission.status).thenAnswer(
      (_) async => LocationPermissionStatus.denied,
    );

    final result = await useCase(const NoParams());

    expect(
      result,
      isA<Success<GeoPoint?>>().having((s) => s.value, 'value', isNull),
    );
    verifyNever(permission.request);
    verifyNever(positions.currentPosition);
  });

  test('sin señal: null', () async {
    when(permission.status).thenAnswer(
      (_) async => LocationPermissionStatus.granted,
    );
    when(positions.currentPosition).thenAnswer((_) async => null);

    final result = await useCase(const NoParams());

    expect(
      result,
      isA<Success<GeoPoint?>>().having((s) => s.value, 'value', isNull),
    );
  });
}
