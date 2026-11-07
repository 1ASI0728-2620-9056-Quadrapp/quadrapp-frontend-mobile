import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/parking_configuration_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/lot_layout_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/parking_lot_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/selected_lot_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

import '../../helpers/fake_http_adapter.dart';
import 'support.dart';

const lotId = LotId(1);

DioException _dioError(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

class _FakeLotRemote implements ParkingLotRemoteDataSource {
  _FakeLotRemote({this.onList, this.onGet});

  Future<List<ParkingLotDto>> Function()? onList;
  Future<ParkingLotDto> Function()? onGet;

  @override
  Future<List<ParkingLotDto>> list() => onList!();

  @override
  Future<ParkingLotDto> get(LotId lotId) => onGet!();
}

class _FakeLayoutRemote implements LotLayoutRemoteDataSource {
  _FakeLayoutRemote(this.handler);

  Future<LayoutFetch> Function(int? knownVersion) handler;
  final List<int?> knownVersions = [];

  @override
  Future<LayoutFetch> fetch(LotId lotId, {int? knownVersion}) {
    knownVersions.add(knownVersion);
    return handler(knownVersion);
  }
}

class _ThrowingStore extends InMemoryKeyValueStore {
  @override
  Future<void> setString(String key, String value) =>
      throw StateError('disco lleno');
}

void main() {
  const mapper = ParkingConfigurationMapper();

  group('ParkingConfigurationMapper', () {
    test('convierte un estacionamiento de docs/07', () {
      final lot = mapper.toLot(ParkingLotDto.fromJson(lotJson(1)));

      expect(lot.id, lotId);
      expect(lot.name, 'Estacionamiento 1');
      expect(lot.address, 'Av. Prueba 1');
      expect(lot.latitude, -12.1035);
      expect(lot.layoutVersion, 4);
      expect(lot.staleAfter, const Duration(seconds: 180));
      expect(lot.hasCoordinates, isTrue);
    });

    test('el umbral de saturación llega del servidor o es 90 por defecto', () {
      final withThreshold = mapper.toLot(
        ParkingLotDto.fromJson(lotJson(1)..['saturationThresholdPct'] = 85),
      );
      final without = mapper.toLot(ParkingLotDto.fromJson(lotJson(1)));

      expect(withThreshold.saturationThresholdPct, 85);
      expect(without.saturationThresholdPct, 90);
    });

    test('las coordenadas y la dirección son opcionales (docs/06)', () {
      final json = lotJson(1)
        ..remove('latitude')
        ..['longitude'] = null
        ..remove('address');

      final lot = mapper.toLot(ParkingLotDto.fromJson(json));

      expect(lot.hasCoordinates, isFalse);
      expect(lot.address, isNull);
    });

    test('las coordenadas enteras se leen como double', () {
      final lot = mapper.toLot(
        ParkingLotDto.fromJson(lotJson(1, latitude: -12, longitude: -77)),
      );

      expect(lot.latitude, -12.0);
      expect(lot.longitude, -77.0);
    });

    test('un layoutVersion 0 es sin distribución publicada', () {
      final lot = mapper.toLot(
        ParkingLotDto.fromJson(lotJson(3, layoutVersion: 0)),
      );

      expect(lot.hasPublishedLayout, isFalse);
    });

    test('convierte la distribución con posiciones', () {
      final layout = mapper.toLayout(
        LotLayoutDto.fromJson(layoutJson()),
        lotId,
      );

      expect(layout, sampleLayout());
      expect(layout.canDrawMap, isTrue);
    });

    test('zonas con niveles: la descripción vacía es "sin descripción" y una '
        'zona sin niveles queda vacía', () {
      final json = layoutJson();
      final zones = json['zones']! as List<Object?>;
      (zones.first! as Map<String, Object?>)['description'] = '   ';
      zones.add({'id': 12, 'name': 'Pabellón C'});

      final layout = mapper.toLayout(LotLayoutDto.fromJson(json), lotId);

      expect(layout.zones.first.description, isNull);
      expect(layout.zones.last.levels, isEmpty);
      expect(layout.zones.last.spaces, isEmpty);
      expect(layout.spaceCount, 4);
    });

    test('las posiciones pueden faltar: solo se muestra la lista', () {
      final layout = mapper.toLayout(
        LotLayoutDto.fromJson(layoutJson(withPositions: false)),
        lotId,
      );

      expect(layout.canDrawMap, isFalse);
      expect(layout.spaceCount, 4);
    });
  });

  group('DTO', () {
    test('un campo obligatorio faltante es ParseFailure', () async {
      final json = lotJson(1)..remove('name');

      final result = await guardResult(
        () async => ParkingLotDto.fromJson(json),
      );

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('un campo de otro tipo es ParseFailure', () async {
      final json = layoutJson()..['version'] = 'cuatro';

      final result = await guardResult(
        () async => LotLayoutDto.fromJson(json),
      );

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('la distribución sin zonas es válida (lista vacía)', () {
      final dto = LotLayoutDto.fromJson({'version': 1});

      expect(dto.zones, isEmpty);
    });
  });

  group('ParkingLotHttpDataSource', () {
    test('GET /parking-lots lee la lista', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse([lotJson(1), lotJson(2)]),
      );

      final lots = await ParkingLotHttpDataSource(dioWith(adapter)).list();

      expect(adapter.requests.single.path, '/parking-lots');
      expect(lots.map((l) => l.id), [1, 2]);
    });

    test('GET /parking-lots/{id} lee un estacionamiento', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse(lotJson(1)));

      final lot = await ParkingLotHttpDataSource(dioWith(adapter)).get(lotId);

      expect(adapter.requests.single.path, '/parking-lots/1');
      expect(lot.name, 'Estacionamiento 1');
    });

    test('un cuerpo que no es un arreglo es ParseException', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse({'a': 1}));

      await expectLater(
        ParkingLotHttpDataSource(dioWith(adapter)).list(),
        throwsA(isA<ParseException>()),
      );
    });

    test('un elemento que no es un objeto es ParseFailure', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse([1]));

      final result = await guardResult(
        ParkingLotHttpDataSource(dioWith(adapter)).list,
      );

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('un 404 llega como NotFoundFailure', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'title': 'Not found'}, status: 404),
      );

      final result = await guardResult(
        () => ParkingLotHttpDataSource(dioWith(adapter)).get(lotId),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('LotLayoutHttpDataSource', () {
    test('sin versión conocida no manda If-None-Match', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse(layoutJson()));

      final fetch = await LotLayoutHttpDataSource(
        dioWith(adapter),
      ).fetch(lotId);

      expect(adapter.requests.single.path, '/parking-lots/1/layout');
      expect(
        adapter.requests.single.headers.containsKey('If-None-Match'),
        isFalse,
      );
      expect(fetch, isA<LayoutFetched>());
    });

    test('con versión conocida manda If-None-Match: "v4"', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse(layoutJson()));

      await LotLayoutHttpDataSource(
        dioWith(adapter),
      ).fetch(lotId, knownVersion: 4);

      expect(adapter.requests.single.headers['If-None-Match'], '"v4"');
    });

    test('un 304 no es un error: conserva la copia local', () async {
      final adapter = FakeHttpAdapter((_) => emptyResponse(304));

      final fetch = await LotLayoutHttpDataSource(
        dioWith(adapter),
      ).fetch(lotId, knownVersion: 4);

      expect(fetch, isA<LayoutNotModified>());
    });

    test('un 200 con una versión nueva trae la distribución', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(layoutJson(version: 5)),
      );

      final fetch = await LotLayoutHttpDataSource(
        dioWith(adapter),
      ).fetch(lotId, knownVersion: 4);

      expect((fetch as LayoutFetched).dto.version, 5);
    });

    test('un 404 sigue siendo un error', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'title': 'No layout'}, status: 404),
      );

      final result = await guardResult(
        () => LotLayoutHttpDataSource(dioWith(adapter)).fetch(lotId),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('un cuerpo que no es un objeto es ParseException', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse([1]));

      await expectLater(
        LotLayoutHttpDataSource(dioWith(adapter)).fetch(lotId),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('LotLayoutCacheDataSource', () {
    test('guarda y lee bajo el prefijo cache.; se borra con él', () async {
      final store = InMemoryKeyValueStore();
      final cache = LotLayoutCacheDataSource(store);

      await cache.write(lotId, LotLayoutDto.fromJson(layoutJson()));

      expect((await cache.read(lotId))!.version, 4);
      await store.removeByPrefix(StoreKeys.cache);
      expect(await cache.read(lotId), isNull);
    });

    test('una copia corrupta se ignora', () async {
      final store = InMemoryKeyValueStore();
      await store.setString('${StoreKeys.cache}layout.1', '[no json');

      expect(await LotLayoutCacheDataSource(store).read(lotId), isNull);
    });
  });

  group('ParkingLotReaderImpl', () {
    test('convierte los DTO en entidades', () async {
      final reader = ParkingLotReaderImpl(
        remote: _FakeLotRemote(
          onList: () async => [
            ParkingLotDto.fromJson(lotJson(1)),
            ParkingLotDto.fromJson(lotJson(3, layoutVersion: 0)),
          ],
        ),
      );

      final result = await reader.list();

      expect(result.valueOrNull!.map((l) => l.id.value), [1, 3]);
      expect(result.valueOrNull!.last.hasPublishedLayout, isFalse);
    });

    test('get devuelve el estacionamiento', () async {
      final reader = ParkingLotReaderImpl(
        remote: _FakeLotRemote(
          onGet: () async => ParkingLotDto.fromJson(lotJson(1)),
        ),
      );

      expect((await reader.get(lotId)).valueOrNull, lotEntity(1));
    });

    test('las excepciones de red y de parseo llegan como Failure', () async {
      final network = ParkingLotReaderImpl(
        remote: _FakeLotRemote(
          onList: () => Future.error(
            _dioError(DioExceptionType.connectionError),
          ),
        ),
      );
      final parse = ParkingLotReaderImpl(
        remote: _FakeLotRemote(
          onGet: () async => ParkingLotDto.fromJson({'id': 1}),
        ),
      );

      expect((await network.list()).failureOrNull, isA<NetworkFailure>());
      expect((await parse.get(lotId)).failureOrNull, isA<ParseFailure>());
    });
  });

  group('LotLayoutReaderImpl', () {
    late InMemoryKeyValueStore store;
    late _FakeLayoutRemote remote;

    LotLayoutReaderImpl build({KeyValueStore? withStore}) =>
        LotLayoutReaderImpl(
          remote: remote,
          cache: LotLayoutCacheDataSource(withStore ?? store),
        );

    setUp(() {
      store = InMemoryKeyValueStore();
      remote = _FakeLayoutRemote(
        (_) async => LayoutFetched(LotLayoutDto.fromJson(layoutJson())),
      );
    });

    test('la primera vez no manda versión y guarda la distribución', () async {
      final result = await build().read(lotId);

      expect(result.valueOrNull, sampleLayout());
      expect(remote.knownVersions, [null]);
      expect(await LotLayoutCacheDataSource(store).read(lotId), isNotNull);
    });

    test('la segunda vez pide con la versión guardada y un 304 conserva la '
        'copia local', () async {
      await build().read(lotId);
      remote.handler = (_) async => const LayoutNotModified();

      final result = await build().read(lotId);

      expect(remote.knownVersions, [null, 4]);
      expect(result.valueOrNull, sampleLayout());
    });

    test('una versión nueva reemplaza la copia local', () async {
      await build().read(lotId);
      remote.handler = (_) async =>
          LayoutFetched(LotLayoutDto.fromJson(layoutJson(version: 5)));

      final result = await build().read(lotId);

      expect(result.valueOrNull!.version, 5);
      expect((await LotLayoutCacheDataSource(store).read(lotId))!.version, 5);
    });

    test('sin conexión devuelve la copia local', () async {
      await build().read(lotId);
      remote.handler = (_) =>
          Future.error(_dioError(DioExceptionType.connectionTimeout));

      final result = await build().read(lotId);

      expect(result.valueOrNull, sampleLayout());
    });

    test('sin conexión y sin copia local es NetworkFailure', () async {
      remote.handler = (_) =>
          Future.error(_dioError(DioExceptionType.connectionError));

      final result = await build().read(lotId);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('una copia local no tapa un 401 ni un 404', () async {
      await build().read(lotId);
      remote.handler = (_) =>
          Future.error(_dioError(DioExceptionType.badResponse, status: 401));
      expect(
        (await build().read(lotId)).failureOrNull,
        isA<UnauthorizedFailure>(),
      );

      remote.handler = (_) =>
          Future.error(_dioError(DioExceptionType.badResponse, status: 404));
      expect((await build().read(lotId)).failureOrNull, isA<NotFoundFailure>());
    });

    test('un 304 sin copia local es ParseFailure (el contrato no se '
        'cumple)', () async {
      remote.handler = (_) async => const LayoutNotModified();

      final result = await build().read(lotId);

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('un JSON que no coincide es ParseFailure y no usa la copia '
        'local', () async {
      await build().read(lotId);
      remote.handler = (_) async =>
          LayoutFetched(LotLayoutDto.fromJson({'zones': <Object?>[]}));

      expect((await build().read(lotId)).failureOrNull, isA<ParseFailure>());
    });

    test('una caché que no se puede escribir no falla la consulta', () async {
      final result = await build(withStore: _ThrowingStore()).read(lotId);

      expect(result.valueOrNull, sampleLayout());
    });
  });

  group('SelectedLotStoreImpl', () {
    test('guarda, lee y borra el estacionamiento elegido', () async {
      final store = SelectedLotStoreImpl(InMemoryKeyValueStore());

      expect(await store.read(), isNull);
      await store.save(const LotId(7));
      expect(await store.read(), const LotId(7));
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('vive bajo el prefijo user.: se borra al cerrar sesión', () async {
      final kv = InMemoryKeyValueStore();
      await SelectedLotStoreImpl(kv).save(const LotId(7));
      await kv.setString('${StoreKeys.device}locale', 'es');

      await kv.removeByPrefix(StoreKeys.user);

      expect(await SelectedLotStoreImpl(kv).read(), isNull);
      expect(await kv.getString('${StoreKeys.device}locale'), 'es');
    });

    test('un valor que no es un número se ignora', () async {
      final kv = InMemoryKeyValueStore();
      await kv.setString('${StoreKeys.user}selectedLot', 'abc');

      expect(await SelectedLotStoreImpl(kv).read(), isNull);
    });
  });
}
