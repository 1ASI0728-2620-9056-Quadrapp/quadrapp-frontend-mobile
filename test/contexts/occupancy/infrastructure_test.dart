import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/occupancy_feed.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_reader.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_ws_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/space_change_dto.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/mappers/occupancy_mapper.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/repositories/occupancy_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/repositories/occupancy_realtime_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_web_socket.dart';
import '../../helpers/recording_logger.dart';
import 'support.dart';

const lotId = LotId(1);

class _FakeRemote implements OccupancyRemoteDataSource {
  _FakeRemote(this.handler);

  Future<LotOccupancyDto> Function() handler;
  int calls = 0;

  @override
  Future<LotOccupancyDto> fetch(LotId lotId) {
    calls++;
    return handler();
  }
}

class _ThrowingStore extends InMemoryKeyValueStore {
  @override
  Future<void> setString(String key, String value) =>
      throw StateError('disco lleno');
}

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

void main() {
  const mapper = OccupancyMapper(NoopLogger());

  group('OccupancyMapper', () {
    test('convierte la respuesta de docs/07', () {
      final dto = LotOccupancyDto.fromJson(occupancyJson());

      final occupancy = mapper.toEntity(
        dto,
        lotId,
        receivedAt: const Duration(seconds: 3),
      );

      expect(occupancy.lotId, lotId);
      expect(occupancy.capacity, 4);
      expect(occupancy.free, 1);
      expect(occupancy.unknown, 1);
      expect(occupancy.consolidatedAt, DateTime.utc(2026, 9, 28, 13, 41, 20));
      expect(occupancy.freshness.staleAfter, const Duration(seconds: 180));
      expect(occupancy.freshness.receivedAt, const Duration(seconds: 3));
      expect(occupancy.zones, hasLength(2));
      expect(occupancy.spaces[3].status, SpaceStatus.unknown);
      expect(occupancy.spaces[3].unknownReason, UnknownReason.lowBattery);
      expect(occupancy.source, OccupancySource.network);
    });

    test('la sección occupancy del BFF no trae zonas ni espacios', () {
      final dto = LotOccupancyDto.fromJson(
        occupancyJson(withZonesAndSpaces: false),
      );

      final occupancy = mapper.toEntity(dto, lotId);

      expect(occupancy.zones, isEmpty);
      expect(occupancy.spaces, isEmpty);
    });

    test('el estado se lee sin distinguir mayúsculas', () {
      expect(mapper.parseStatus('free'), SpaceStatus.free);
      expect(mapper.parseStatus('Occupied'), SpaceStatus.occupied);
      expect(mapper.parseStatus('UNKNOWN'), SpaceStatus.unknown);
    });

    test('un estado no reconocido cae en UNKNOWN y deja un aviso', () {
      final logger = RecordingLogger();

      final status = OccupancyMapper(logger).parseStatus('BROKEN');

      expect(status, SpaceStatus.unknown);
      expect(logger.messages.single, contains('BROKEN'));
    });

    test('un motivo no reconocido es null', () {
      expect(mapper.parseReason('NO_SENSOR'), UnknownReason.noSensor);
      expect(mapper.parseReason('NO_HEARTBEAT'), UnknownReason.noHeartbeat);
      expect(mapper.parseReason('???'), isNull);
      expect(mapper.parseReason(null), isNull);
    });

    test('un cambio en tiempo real se convierte con hora UTC', () {
      final change = mapper.toChange(
        SpaceChangeDto.fromJson({
          'eventId': 'e-1',
          'spaceId': 5,
          'status': 'occupied',
          'at': '2026-09-28T13:42:00Z',
        }),
      );

      expect(change.eventId, 'e-1');
      expect(change.spaceId, const SpaceId(5));
      expect(change.status, SpaceStatus.occupied);
      expect(change.at.isUtc, isTrue);
    });
  });

  group('DTO', () {
    test('un campo obligatorio faltante es ParseFailure', () async {
      final json = occupancyJson()..remove('capacity');

      final result = await guardResult(
        () async => LotOccupancyDto.fromJson(json),
      );

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('un campo de otro tipo es ParseFailure', () async {
      final json = occupancyJson()..['free'] = 'muchos';

      final result = await guardResult(
        () async => LotOccupancyDto.fromJson(json),
      );

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('toJson y fromJson son inversos', () {
      final dto = LotOccupancyDto.fromJson(occupancyJson());

      final again = LotOccupancyDto.fromJson(
        jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>,
      );

      expect(again.toJson(), dto.toJson());
    });
  });

  group('OccupancyHttpDataSource (backend)', () {
    Map<String, Object?> summary(
      String scope,
      int id, {
      required int total,
      required int free,
      required int occupied,
      required int unknown,
    }) => {
      'scopeType': scope,
      'scopeId': id,
      'takenAt': '2026-11-14T15:00:00Z',
      'totalSpaces': total,
      'freeCount': free,
      'occupiedCount': occupied,
      'unknownCount': unknown,
    };

    // `SpaceStatusResource[]` del backend, campo por campo, por `spaceId`.
    Map<String, Object?> spaceStatus(
      int spaceId,
      int zoneId,
      String status, {
      String? unknownReason,
    }) => {
      'spaceId': spaceId,
      'zoneId': zoneId,
      'levelId': zoneId * 10,
      'status': status,
      'unknownReason': unknownReason,
      'statusSince': '2026-11-14T14:58:00Z',
      'lastDetectedAt': status == 'UNKNOWN' ? null : '2026-11-14T14:58:00Z',
    };
    final spaceStatuses = [
      spaceStatus(1, 10, 'FREE'),
      spaceStatus(2, 10, 'OCCUPIED'),
      spaceStatus(3, 10, 'UNKNOWN', unknownReason: 'GATEWAY_OFFLINE'),
      spaceStatus(4, 10, 'FREE'),
      spaceStatus(5, 11, 'UNKNOWN', unknownReason: 'NOT_YET_REPORTED'),
      spaceStatus(6, 11, 'OCCUPIED'),
    ];

    ResponseBody backend(RequestOptions options) => switch (options.path) {
      '/parking-lots/1' => jsonResponse({
        'id': 1,
        'name': 'Estacionamiento 1',
        'staleAfterSeconds': 120,
        'layoutVersion': 0,
      }),
      '/parking-lots/1/occupancy' => jsonResponse(
        summary('PARKING_LOT', 1, total: 6, free: 3, occupied: 2, unknown: 1),
      ),
      '/parking-lots/1/zones' => jsonResponse([
        {'id': 10, 'name': 'A', 'sortOrder': 1},
        {'id': 11, 'name': 'B', 'sortOrder': 2},
      ]),
      '/zones/10/occupancy' => jsonResponse(
        summary('ZONE', 10, total: 4, free: 2, occupied: 1, unknown: 1),
      ),
      '/zones/11/occupancy' => jsonResponse(
        summary('ZONE', 11, total: 2, free: 1, occupied: 1, unknown: 0),
      ),
      '/parking-lots/1/spaces/status' => jsonResponse(spaceStatuses),
      _ => jsonResponse({'title': 'Not found'}, status: 404),
    };

    test('arma la ocupación con los conteos del lote y de cada zona', () async {
      final adapter = FakeHttpAdapter(backend);

      final dto = await OccupancyHttpDataSource(dioWith(adapter)).fetch(lotId);

      expect(dto.capacity, 6);
      expect(dto.free, 3);
      expect(dto.occupied, 2);
      expect(dto.unknown, 1);
      expect(dto.consolidatedAt, DateTime.utc(2026, 11, 14, 15));
      expect(dto.serverTime, DateTime.utc(2026, 11, 14, 15));
      expect(dto.staleAfterSeconds, 120);
      expect(dto.zones.map((z) => (z.id, z.free, z.occupied, z.unknown)), [
        (10, 2, 1, 1),
        (11, 1, 1, 0),
      ]);
      final logger = RecordingLogger();
      final entity = OccupancyMapper(
        logger,
      ).toEntity(dto, lotId, receivedAt: Duration.zero);
      expect(entity.isFull, isFalse);
      expect(
        entity.spaces.map((s) => (s.id.value, s.status, s.unknownReason)),
        [
          (1, SpaceStatus.free, null),
          (2, SpaceStatus.occupied, null),
          (3, SpaceStatus.unknown, UnknownReason.noHeartbeat),
          (4, SpaceStatus.free, null),
          (5, SpaceStatus.unknown, null),
          (6, SpaceStatus.occupied, null),
        ],
      );
      // Los motivos del backend se reconocen sin avisos.
      expect(logger.messages, isEmpty);
    });

    test('un backend sin /spaces/status deja los espacios vacíos y conserva '
        'los conteos', () async {
      final adapter = FakeHttpAdapter(
        (options) => options.path == '/parking-lots/1/spaces/status'
            ? jsonResponse({'title': 'Not found'}, status: 404)
            : backend(options),
      );

      final dto = await OccupancyHttpDataSource(dioWith(adapter)).fetch(lotId);

      expect(dto.spaces, isEmpty);
      expect(dto.capacity, 6);
      expect(dto.zones, hasLength(2));
    });

    test('un estado de espacio sin status es ParseException', () async {
      final adapter = FakeHttpAdapter(
        (options) => options.path == '/parking-lots/1/spaces/status'
            ? jsonResponse([
                {'spaceId': 1, 'zoneId': 10, 'levelId': 100},
              ])
            : backend(options),
      );

      await expectLater(
        OccupancyHttpDataSource(dioWith(adapter)).fetch(lotId),
        throwsA(isA<ParseException>()),
      );
    });

    test('un 404 llega como NotFoundFailure', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'title': 'Not found'}, status: 404),
      );

      final result = await guardResult(
        () => OccupancyHttpDataSource(dioWith(adapter)).fetch(lotId),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('un resumen sin conteos es ParseException', () async {
      final adapter = FakeHttpAdapter(
        (options) => options.path == '/parking-lots/1/occupancy'
            ? jsonResponse({'takenAt': '2026-11-14T15:00:00Z'})
            : backend(options),
      );

      await expectLater(
        OccupancyHttpDataSource(dioWith(adapter)).fetch(lotId),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('OccupancyCacheDataSource', () {
    test(
      'guarda y lee con su marca de tiempo, bajo el prefijo cache.',
      () async {
        final store = InMemoryKeyValueStore();
        final cache = OccupancyCacheDataSource(store);
        final dto = LotOccupancyDto.fromJson(occupancyJson());

        await cache.write(lotId, dto, t0);
        final read = await cache.read(lotId);

        expect(read!.storedAt, t0);
        expect(read.dto.toJson(), dto.toJson());
        await store.removeByPrefix(StoreKeys.cache);
        expect(await cache.read(lotId), isNull);
      },
    );

    test('una copia corrupta se ignora', () async {
      final store = InMemoryKeyValueStore();
      await store.setString('${StoreKeys.cache}occupancy.1', '{no json');

      expect(await OccupancyCacheDataSource(store).read(lotId), isNull);
    });
  });

  group('OccupancyReaderImpl', () {
    late FakeClock clock;
    late InMemoryKeyValueStore store;
    late _FakeRemote remote;
    late OccupancyReader reader;

    OccupancyReader build({KeyValueStore? withStore}) => OccupancyReaderImpl(
      remote: remote,
      cache: OccupancyCacheDataSource(withStore ?? store),
      mapper: mapper,
      clock: clock,
    );

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 9, 28, 13, 42));
      store = InMemoryKeyValueStore();
      remote = _FakeRemote(
        () async => LotOccupancyDto.fromJson(occupancyJson()),
      );
      reader = build();
    });

    test('red primero: devuelve el dato del servidor y lo guarda', () async {
      final result = await reader.read(lotId);

      final occupancy = result.valueOrNull!;
      expect(occupancy.source, OccupancySource.network);
      expect(occupancy.freshness.receivedAt, Duration.zero);
      expect(
        await OccupancyCacheDataSource(store).read(lotId),
        isNotNull,
      );
    });

    test('si falla por red devuelve la caché marcada como tal, con su '
        'antigüedad', () async {
      await reader.read(lotId);
      clock.advance(const Duration(minutes: 10));
      remote.handler = () =>
          Future.error(_dioError(DioExceptionType.connectionError));

      final occupancy = (await reader.read(lotId)).valueOrNull!;

      expect(occupancy.isFromCache, isTrue);
      expect(occupancy.freshness.storedAt, DateTime.utc(2026, 9, 28, 13, 42));
      expect(occupancy.freshness.isStale(clock), isTrue);
      expect(
        occupancy.freshness.age(clock),
        const Duration(minutes: 10, seconds: 40),
      );
    });

    test('sin red y sin caché es NetworkFailure', () async {
      remote.handler = () =>
          Future.error(_dioError(DioExceptionType.connectionTimeout));

      final result = await reader.read(lotId);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('una copia vieja no tapa un 401', () async {
      await reader.read(lotId);
      remote.handler = () =>
          Future.error(_dioError(DioExceptionType.badResponse, status: 401));

      expect(
        (await reader.read(lotId)).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
    });

    test('un 404 (sin datos vigentes) llega tal cual', () async {
      remote.handler = () =>
          Future.error(_dioError(DioExceptionType.badResponse, status: 404));

      expect((await reader.read(lotId)).failureOrNull, isA<NotFoundFailure>());
    });

    test('un JSON que no coincide es ParseFailure y no usa la caché', () async {
      await reader.read(lotId);
      remote.handler = () async =>
          LotOccupancyDto.fromJson(occupancyJson()..remove('serverTime'));

      expect((await reader.read(lotId)).failureOrNull, isA<ParseFailure>());
    });

    test('una caché que no se puede escribir no falla la consulta', () async {
      final result = await build(withStore: _ThrowingStore()).read(lotId);

      expect(result.isSuccess, isTrue);
    });
  });

  group('OccupancyRealtimeImpl', () {
    late FakeClock clock;
    late StreamController<OccupancyRealtimeEvent> events;
    late List<Result<LotOccupancy>> snapshots;
    late int snapshotCalls;
    late OccupancyRealtimeImpl realtime;
    late List<Result<LotOccupancy>> emitted;
    late StreamSubscription<Result<LotOccupancy>> subscription;

    _Ds dataSource() => _Ds(events);

    Future<void> settle() => pumpEventQueue(times: 30);

    setUp(() {
      clock = FakeClock();
      events = StreamController<OccupancyRealtimeEvent>.broadcast();
      snapshotCalls = 0;
      snapshots = [Success(sampleOccupancy())];
      realtime = OccupancyRealtimeImpl(
        dataSource: dataSource(),
        reader: _FakeReader(() {
          final index = snapshotCalls++;
          return snapshots[index < snapshots.length
              ? index
              : snapshots.length - 1];
        }),
        mapper: mapper,
        clock: clock,
      );
      emitted = [];
      subscription = realtime.watch(lotId).listen(emitted.add);
    });

    tearDown(() async {
      await subscription.cancel();
      await events.close();
    });

    RealtimeChange change(String id, int space, String status, DateTime at) =>
        RealtimeChange(
          SpaceChangeDto(eventId: id, spaceId: space, status: status, at: at),
        );

    test('emite primero el estado completo', () async {
      await settle();

      expect(emitted, hasLength(1));
      expect(emitted.single.valueOrNull!.free, 1);
    });

    test('la primera conexión no repite la consulta', () async {
      await settle();
      events.add(const RealtimeConnected());
      await settle();

      expect(snapshotCalls, 1);
    });

    test('aplica los cambios y emite la ocupación nueva', () async {
      await settle();
      events
        ..add(const RealtimeConnected())
        ..add(
          change('e1', 1, 'OCCUPIED', t0.add(const Duration(seconds: 5))),
        );
      await settle();

      expect(emitted, hasLength(2));
      expect(emitted.last.valueOrNull!.free, 0);
      expect(emitted.last.valueOrNull!.isFull, isTrue);
    });

    test('ignora un evento repetido y uno fuera de orden', () async {
      await settle();
      final at = t0.add(const Duration(seconds: 5));
      events
        ..add(change('e1', 1, 'OCCUPIED', at))
        ..add(change('e1', 1, 'OCCUPIED', at))
        ..add(change('e2', 1, 'FREE', at.subtract(const Duration(seconds: 2))));
      await settle();

      expect(emitted, hasLength(2));
    });

    test(
      'un estado desconocido del servidor cae en UNKNOWN, no en libre',
      () async {
        await settle();
        events.add(
          change('e1', 1, 'MYSTERY', t0.add(const Duration(seconds: 5))),
        );
        await settle();

        final last = emitted.last.valueOrNull!;
        expect(last.free, 0);
        expect(last.unknown, 2);
      },
    );

    test('al reconectar vuelve a pedir el estado completo', () async {
      await settle();
      snapshots = [
        Success(sampleOccupancy()),
        Success(sampleOccupancy().copyWith(free: 3)),
      ];
      events
        ..add(const RealtimeConnected())
        ..add(const RealtimeDisconnected())
        ..add(const RealtimeConnected());
      await settle();

      expect(snapshotCalls, 2);
      expect(emitted.last.valueOrNull!.free, 3);
    });

    test('un aviso de conteos vuelve a pedir el estado completo', () async {
      await settle();
      snapshots = [
        Success(sampleOccupancy()),
        Success(sampleOccupancy().copyWith(free: 2)),
      ];
      events.add(const RealtimeConnected());
      await settle();
      expect(snapshotCalls, 1);

      events.add(const RealtimeCountsChanged());
      await settle();

      expect(snapshotCalls, 2);
      expect(emitted.last.valueOrNull!.free, 2);
    });

    test(
      'si el estado inicial falló, la primera conexión lo pide de nuevo',
      () async {
        await subscription.cancel();
        snapshotCalls = 0;
        snapshots = [
          const Err(NetworkFailure()),
          Success(sampleOccupancy()),
        ];
        emitted = [];
        subscription = realtime.watch(lotId).listen(emitted.add);
        await settle();
        expect(emitted.single.failureOrNull, isA<NetworkFailure>());

        events.add(const RealtimeConnected());
        await settle();

        expect(emitted.last.isSuccess, isTrue);
      },
    );

    test('cancelar la suscripción cierra la conexión', () async {
      await settle();
      expect(events.hasListener, isTrue);

      await subscription.cancel();

      expect(events.hasListener, isFalse);
    });

    group('feed (el estado real de la conexión)', () {
      late List<OccupancyFeedEvent> feed;
      late StreamSubscription<OccupancyFeedEvent> feedSubscription;

      setUp(() async {
        await subscription.cancel();
        feed = [];
        feedSubscription = realtime.feed(lotId).listen(feed.add);
        await settle();
      });

      tearDown(() => feedSubscription.cancel());

      List<RealtimeLink> links() => [
        for (final event in feed.whereType<LinkChanged>()) event.link,
      ];

      test(
        'conecta, cae y reconecta: cada estado se avisa una sola vez',
        () async {
          expect(links(), [RealtimeLink.connecting]);

          events.add(const RealtimeConnected());
          await settle();
          events
            ..add(const RealtimeDisconnected())
            ..add(const RealtimeDisconnected());
          await settle();
          events.add(const RealtimeConnected());
          await settle();

          expect(links(), [
            RealtimeLink.connecting,
            RealtimeLink.live,
            RealtimeLink.reconnecting,
            RealtimeLink.live,
          ]);
        },
      );

      test('sigue entregando el estado completo y los cambios', () async {
        events
          ..add(const RealtimeConnected())
          ..add(
            change('e1', 1, 'OCCUPIED', t0.add(const Duration(seconds: 5))),
          );
        await settle();

        final received = feed.whereType<OccupancyReceived>().toList();
        expect(received, hasLength(2));
        expect(received.last.result.valueOrNull!.free, 0);
      });
    });
  });

  group('exponentialBackoff', () {
    test('1 s, 2 s, 4 s... con tope de 30 s', () {
      expect(
        [for (var i = 0; i < 8; i++) exponentialBackoff(i).inSeconds],
        [1, 2, 4, 8, 16, 30, 30, 30],
      );
    });
  });

  group('OccupancyWsDataSource (STOMP)', () {
    OccupancyWsDataSource build(
      FakeWebSocketConnector connector, {
      List<Duration>? delays,
      String? token = 'T1',
    }) => OccupancyWsDataSource(
      connector: connector,
      url: Uri.parse('wss://api.test/ws'),
      accessToken: () => token,
      logger: const NoopLogger(),
      delay: (duration) async {
        delays?.add(duration);
        await Future<void>.delayed(Duration.zero);
      },
    );

    const connected = 'CONNECTED\nversion:1.2\nheart-beat:0,0\n\n\u0000';

    String message(Map<String, Object?> body) =>
        'MESSAGE\ndestination:/topic/parking-lots/1/occupancy\n'
        'content-type:application/json\nsubscription:occupancy-1\n'
        'message-id:m-1\n\n${jsonEncode(body)}\u0000';

    // `OccupancyRealtimeMessage` del backend, campo por campo.
    final backendMessage = <String, Object?>{
      'parkingLotId': 1,
      'zoneId': 10,
      'zone': {
        'totalSpaces': 4,
        'freeCount': 2,
        'occupiedCount': 1,
        'unknownCount': 1,
      },
      'parkingLot': {
        'totalSpaces': 6,
        'freeCount': 3,
        'occupiedCount': 2,
        'unknownCount': 1,
      },
      'lowAvailability': false,
      'consolidatedAt': '2026-11-14T15:00:01Z',
      'spaces': [
        {
          'spaceId': 3,
          'status': 'FREE',
          'unknownReason': null,
          'statusSince': '2026-11-14T15:00:00Z',
        },
      ],
    };

    test('se conecta a /ws, manda el token en CONNECT y se suscribe al '
        'tópico del estacionamiento tras CONNECTED', () async {
      final channel = FakeWebSocketChannel();
      final connector = FakeWebSocketConnector([channel]);
      final events = <OccupancyRealtimeEvent>[];
      final sub = build(connector).connect(lotId).listen(events.add);
      await pumpEventQueue();

      expect(connector.uris.single, Uri.parse('wss://api.test/ws'));
      expect(connector.headers.single, isEmpty);
      final connect = channel.sent.single as String;
      expect(connect, startsWith('CONNECT\n'));
      expect(connect, contains('accept-version:1.2\n'));
      expect(connect, contains('Authorization:Bearer T1\n'));
      expect(connect, endsWith('\n\n\u0000'));
      expect(events, isEmpty);

      channel.emit(connected);
      await pumpEventQueue();

      final subscribe = channel.sent.last as String;
      expect(subscribe, startsWith('SUBSCRIBE\n'));
      expect(
        subscribe,
        contains('destination:/topic/parking-lots/1/occupancy\n'),
      );
      expect(events.single, isA<RealtimeConnected>());
      await sub.cancel();
    });

    test('sin token, CONNECT no lleva Authorization', () async {
      final channel = FakeWebSocketChannel();
      final sub = build(
        FakeWebSocketConnector([channel]),
        token: null,
      ).connect(lotId).listen((_) {});
      await pumpEventQueue();

      expect(channel.sent.single as String, isNot(contains('Authorization')));
      await sub.cancel();
    });

    test('cada MESSAGE con conteos avisa RealtimeCountsChanged; los '
        'ilegibles y los latidos se descartan sin cortar', () async {
      final channel = FakeWebSocketChannel();
      final events = <OccupancyRealtimeEvent>[];
      final sub = build(
        FakeWebSocketConnector([channel]),
      ).connect(lotId).listen(events.add);
      await pumpEventQueue();

      channel
        ..emit(connected)
        ..emit('\n')
        ..emit(message(backendMessage))
        ..emit('MESSAGE\ndestination:/x\n\nbasura\u0000')
        ..emit(message({'zoneId': 10}));
      await pumpEventQueue();

      expect(events.map((e) => e.runtimeType), [
        RealtimeConnected,
        RealtimeCountsChanged,
      ]);
      await sub.cancel();
    });

    test('un ERROR (token rechazado) corta, avisa Disconnected y reintenta '
        'con el token actual', () async {
      final first = FakeWebSocketChannel();
      final second = FakeWebSocketChannel();
      final delays = <Duration>[];
      final events = <OccupancyRealtimeEvent>[];
      final sub = build(
        FakeWebSocketConnector([first, second]),
        delays: delays,
      ).connect(lotId).listen(events.add);
      await pumpEventQueue();

      first.emit(
        'ERROR\nmessage:The access token is not valid.\n\n\u0000',
      );
      await pumpEventQueue();
      second.emit(connected);
      await pumpEventQueue();

      expect(first.isClosedByClient, isTrue);
      expect(events.map((e) => e.runtimeType), [
        RealtimeDisconnected,
        RealtimeConnected,
      ]);
      expect(delays, [const Duration(seconds: 1)]);
      expect(second.sent.first as String, contains('Authorization:Bearer T1'));
      await sub.cancel();
    });

    test(
      'la espera crece con los fallos y se reinicia tras conectar',
      () async {
        final delays = <Duration>[];
        final last = FakeWebSocketChannel();
        final connector = FakeWebSocketConnector([
          FakeWebSocketChannel(readyError: StateError('sin servidor')),
          FakeWebSocketChannel(readyError: StateError('sin servidor')),
          FakeWebSocketChannel(readyError: StateError('sin servidor')),
          last,
        ]);
        final events = <OccupancyRealtimeEvent>[];
        final sub = build(
          connector,
          delays: delays,
        ).connect(lotId).listen(events.add);

        await pumpEventQueue(times: 60);
        last.emit(connected);
        await pumpEventQueue();

        expect(delays, [
          const Duration(seconds: 1),
          const Duration(seconds: 2),
          const Duration(seconds: 4),
        ]);
        expect(events.whereType<RealtimeConnected>(), hasLength(1));
        await sub.cancel();
      },
    );

    test('cancelar cierra el canal y detiene los reintentos', () async {
      final channel = FakeWebSocketChannel();
      final delays = <Duration>[];
      final sub = build(
        FakeWebSocketConnector([channel]),
        delays: delays,
      ).connect(lotId).listen((_) {});
      await pumpEventQueue();
      channel.emit(connected);
      await pumpEventQueue();

      await sub.cancel();
      await channel.drop();
      await pumpEventQueue();

      expect(channel.isClosedByClient, isTrue);
      expect(delays, isEmpty);
    });
  });
}

class _Ds implements OccupancyRealtimeDataSource {
  _Ds(this._controller);

  final StreamController<OccupancyRealtimeEvent> _controller;

  @override
  Stream<OccupancyRealtimeEvent> connect(LotId lotId) => _controller.stream;
}

class _FakeReader implements OccupancyReader {
  _FakeReader(this._next);

  final Result<LotOccupancy> Function() _next;

  @override
  Future<Result<LotOccupancy>> read(LotId lotId) async => _next();
}
