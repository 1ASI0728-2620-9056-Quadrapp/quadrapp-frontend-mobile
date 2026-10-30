import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_day.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_language.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/datasources/notification_http_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/dto/notification_dtos.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/mappers/notifications_mapper.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/push/push_message_mapper.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/notification_repositories.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/registered_push_token_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/recording_logger.dart';
import 'support.dart';

void main() {
  late RecordingLogger logger;
  late NotificationsMapper mapper;

  setUp(() {
    logger = RecordingLogger();
    mapper = NotificationsMapper(logger);
  });

  AlertSubscriptionRepositoryImpl subscriptionsOn(FakeHttpAdapter adapter) =>
      AlertSubscriptionRepositoryImpl(
        remote: AlertSubscriptionHttpDataSource(dioWith(adapter)),
        mapper: mapper,
      );

  DeviceTokenRepositoryImpl devicesOn(FakeHttpAdapter adapter) =>
      DeviceTokenRepositoryImpl(DeviceTokenHttpDataSource(dioWith(adapter)));

  group('NotificationsMapper', () {
    test('caso feliz: suscripción con días ordenados y franja', () {
      final subscription = mapper.toSubscription(
        AlertSubscriptionDto.fromJson(subscriptionJson(days: [5, 1])),
      );

      expect(subscription.id, const AlertSubscriptionId(1));
      expect(subscription.lotId, const LotId(1));
      expect(subscription.days, [AlertDay.monday, AlertDay.friday]);
      expect(subscription.slot.from, time(7, 30));
      expect(subscription.slot.to, time(9, 0));
      expect(logger.messages, isEmpty);
    });

    test(
      'la lista trae las inactivas y omite las ilegibles',
      () {
        final list = mapper.toSubscriptions([
          for (final json in [
            subscriptionJson(),
            subscriptionJson(id: 2, active: false),
            subscriptionJson(id: 3, days: [0, 9]),
            subscriptionJson(id: 4, from: 'ocho'),
            subscriptionJson(id: 5, from: '09:00', to: '07:30'),
            subscriptionJson(id: 6, to: '10:15:00'),
          ])
            AlertSubscriptionDto.fromJson(json),
        ]);

        expect(list.map((s) => s.id.value), [1, 2, 6]);
        expect(list.map((s) => s.active), [true, false, true]);
        expect(logger.messages, hasLength(3));
      },
    );

    test(
      'el idioma viaja como en-US o es-419; un valor desconocido es inglés',
      () {
        expect(
          mapper
              .toPreferencesDto(
                samplePreferences.copyWith(language: AlertLanguage.es),
              )
              .locale,
          'es-419',
        );
        expect(
          mapper
              .toPreferencesDto(
                samplePreferences.copyWith(language: AlertLanguage.en),
              )
              .locale,
          'en-US',
        );
        expect(mapper.parseLanguage('es-419'), AlertLanguage.es);
        expect(logger.messages, isEmpty);

        expect(mapper.parseLanguage('fr-FR'), AlertLanguage.en);
        expect(logger.messages, hasLength(1));
      },
    );
  });

  group('repositorios', () {
    test('POST de la suscripción envía solo lotId, days, from y to', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(subscriptionJson(id: 7), status: 201),
      );

      final result = await subscriptionsOn(adapter).create(sampleDraft());

      expect(result.valueOrNull?.id, const AlertSubscriptionId(7));
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {
        'lotId': 1,
        'days': [1, 2, 3, 4, 5],
        'from': '07:30',
        'to': '09:00',
      });
    });

    test('un error de red es NetworkFailure', () async {
      final adapter = FakeHttpAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await subscriptionsOn(adapter).list();

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('409 del servidor trae los errores por campo', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({
          'status': 400,
          'title': 'Bad Request',
          'errors': {
            'slot': ['duplicate'],
          },
        }, status: 409),
      );

      final failure = (await subscriptionsOn(
        adapter,
      ).create(sampleDraft())).failureOrNull;

      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).errors, {
        'slot': ['duplicate'],
      });
    });

    test('PATCH activa o desactiva con solo { active }', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(subscriptionJson(id: 3, active: false)),
      );

      final result = await subscriptionsOn(
        adapter,
      ).setActive(const AlertSubscriptionId(3), active: false);

      expect(result.valueOrNull?.active, isFalse);
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.path, '/notification-subscriptions/3');
      expect(adapter.requests.single.data, {'active': false});
    });

    test(
      'reactivar una franja duplicada (409) trae el error por campo',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse({
            'status': 409,
            'title': 'Conflict',
            'errors': {
              'slot': ['duplicate'],
            },
          }, status: 409),
        );

        final failure = (await subscriptionsOn(
          adapter,
        ).setActive(const AlertSubscriptionId(3), active: true)).failureOrNull;

        expect(failure, isA<ValidationFailure>());
      },
    );

    test('la lista trae las franjas activas e inactivas', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse([
          subscriptionJson(),
          subscriptionJson(id: 2, active: false),
        ]),
      );

      final list = (await subscriptionsOn(adapter).list()).valueOrNull!;

      expect(list.map((s) => s.active), [true, false]);
    });

    test('dar de baja: 404 cuenta como éxito', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'status': 404, 'title': 'Not Found'}, status: 404),
      );

      final result = await subscriptionsOn(adapter).remove(
        const AlertSubscriptionId(3),
      );

      expect(result.isSuccess, isTrue);
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/notification-subscriptions/3');
    });

    test('una lista que no es un arreglo es ParseFailure', () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(<String, Object?>{'items': <Object?>[]}),
      );

      final result = await subscriptionsOn(adapter).list();

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test(
      'PUT de preferencias reemplaza todos los campos con el locale de la API',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse(preferencesJson(locale: 'en-US')),
        );
        final repository = NotificationPreferencesRepositoryImpl(
          remote: NotificationPreferencesHttpDataSource(dioWith(adapter)),
          mapper: mapper,
        );

        final result = await repository.save(
          samplePreferences.copyWith(language: AlertLanguage.en),
        );

        expect(adapter.requests.single.method, 'PUT');
        expect(adapter.requests.single.data, {
          'pushEnabled': true,
          'saturationAlerts': true,
          'lowArrivalAlerts': false,
          'staleDataAlerts': true,
          'eventAlerts': false,
          'locale': 'en-US',
        });
        expect(result.valueOrNull?.language, AlertLanguage.en);
      },
    );
  });

  group('tokens de dispositivo', () {
    test('POST /device-tokens envía token y platform ANDROID', () async {
      final adapter = FakeHttpAdapter((_) => emptyResponse(204));

      final result = await devicesOn(adapter).register(pushToken('abc:def'));

      expect(result.isSuccess, isTrue);
      expect(adapter.requests.single.data, {
        'token': 'abc:def',
        'platform': 'ANDROID',
      });
    });

    test(
      'baja: POST con el token en el cuerpo, nunca en la URL; 404 es éxito',
      () async {
        final adapter = FakeHttpAdapter(
          (_) =>
              jsonResponse({'status': 404, 'title': 'Not Found'}, status: 404),
        );

        final result = await devicesOn(
          adapter,
        ).unregister(pushToken('abc:def/1'));

        expect(result.isSuccess, isTrue);
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/device-tokens/unregister');
        expect(request.data, {'token': 'abc:def/1'});
        expect(request.uri.toString(), isNot(contains('abc')));
        expect(request.queryParameters, isEmpty);
      },
    );

    test(
      'baja: 204 es éxito y un error de red se devuelve como falla',
      () async {
        final ok = FakeHttpAdapter((_) => emptyResponse(204));
        expect((await devicesOn(ok).unregister(pushToken())).isSuccess, isTrue);

        final down = FakeHttpAdapter(
          (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
        expect(
          (await devicesOn(down).unregister(pushToken())).failureOrNull,
          isA<NetworkFailure>(),
        );
      },
    );

    test('el token registrado se guarda bajo user. y se borra', () async {
      final keyValues = InMemoryKeyValueStore();
      final store = RegisteredPushTokenStoreImpl(keyValues);

      await store.save(pushToken('guardado'));
      expect(await store.read(), pushToken('guardado'));

      // Es dato de usuario: el borrado por prefijo al cerrar sesión lo quita.
      await keyValues.removeByPrefix(StoreKeys.user);
      expect(await store.read(), isNull);
    });
  });

  group('PushMessageMapper', () {
    late PushMessageMapper pushMapper;

    setUp(() => pushMapper = PushMessageMapper(logger));

    test('caso feliz: lotId llega como texto', () {
      final message = pushMapper.fromData({
        'type': 'SATURATION',
        'lotId': '2',
      });

      expect(
        message,
        const PushMessage(type: PushMessageType.saturation, lotId: LotId(2)),
      );
      expect(
        pushMapper.fromData({'type': 'LOW_ARRIVAL', 'lotId': 3})?.type,
        PushMessageType.lowArrival,
      );
    });

    test('tipo desconocido o estacionamiento inválido se ignoran', () {
      for (final data in <Map<String, Object?>>[
        {'type': 'PROMO', 'lotId': '2'},
        {'type': 'SATURATION'},
        {'type': 'SATURATION', 'lotId': 'abc'},
        {'type': 'SATURATION', 'lotId': '0'},
        {},
      ]) {
        expect(pushMapper.fromData(data), isNull, reason: '$data');
      }
      expect(logger.messages, hasLength(5));
    });
  });
}
