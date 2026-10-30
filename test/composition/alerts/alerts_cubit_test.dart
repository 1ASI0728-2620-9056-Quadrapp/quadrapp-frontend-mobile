// US23, US24, US33: Alertas y preferencias en cada estado.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_cubit.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_state.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import 'support.dart' as s;

class _MockGet extends Mock implements GetNotificationPreferences {}

class _MockSave extends Mock implements SaveNotificationPreferences {}

class _MockList extends Mock implements ListAlertSubscriptions {}

class _MockCreate extends Mock implements CreateAlertSubscription {}

class _MockSetActive extends Mock implements SetAlertSubscriptionActive {}

class _MockRemove extends Mock implements RemoveAlertSubscription {}

class _MockActivate extends Mock implements ActivateDeviceNotifications {}

void main() {
  late _MockGet getPreferences;
  late _MockSave savePreferences;
  late _MockList list;
  late _MockCreate create;
  late _MockSetActive setActive;
  late _MockRemove remove;
  late _MockActivate activate;
  late List<AlertsNotice> notices;
  late StreamSubscription<AlertsNotice> noticeSub;
  late AlertsCubit cubit;

  setUpAll(() {
    registerFallbackValue(s.preferences);
    registerFallbackValue(const NoParams());
    registerFallbackValue(const AlertSubscriptionId(1));
    registerFallbackValue(
      const SetAlertSubscriptionActiveParams(
        id: AlertSubscriptionId(1),
        active: true,
      ),
    );
    registerFallbackValue(
      CreateAlertSubscriptionParams(
        lotId: const LotId(1),
        days: const {1},
        from: s.time(8, 0),
        to: s.time(9, 0),
      ),
    );
  });

  setUp(() {
    getPreferences = _MockGet();
    savePreferences = _MockSave();
    list = _MockList();
    create = _MockCreate();
    setActive = _MockSetActive();
    remove = _MockRemove();
    activate = _MockActivate();
    when(
      () => getPreferences(any()),
    ).thenAnswer((_) async => const Success(s.preferences));
    when(
      () => list(any()),
    ).thenAnswer((_) async => Success(s.sampleSubscriptions()));
    when(() => savePreferences(any())).thenAnswer(
      (invocation) async => Success(
        invocation.positionalArguments.single as NotificationPreferences,
      ),
    );
    when(
      () => activate(any()),
    ).thenAnswer((_) async => const Success(DeviceActivation.registered));
    cubit = AlertsCubit(
      getPreferences: getPreferences,
      savePreferences: savePreferences,
      listSubscriptions: list,
      createSubscription: create,
      setActive: setActive,
      removeSubscription: remove,
      activateDevice: activate,
    );
    notices = [];
    noticeSub = cubit.notices.listen(notices.add);
  });

  tearDown(() async {
    await noticeSub.cancel();
    await cubit.close();
  });

  AlertsOverview dataOf() => switch (cubit.state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    final other => fail('se esperaba contenido y hay $other'),
  };

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('carga', () {
    test('trae las preferencias y las franjas, activas e inactivas', () async {
      await cubit.load();

      expect(cubit.state, isA<ViewData<AlertsOverview>>());
      expect(dataOf().preferences, s.preferences);
      expect(dataOf().subscriptions?.map((e) => e.active), [true, true, false]);
    });

    test('sin las preferencias: parcial, con las franjas', () async {
      when(
        () => getPreferences(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      final state = cubit.state as ViewPartial<AlertsOverview>;
      expect(state.missing, {'preferences'});
      expect(state.data.subscriptions, isNotNull);
    });

    test('sin las franjas: parcial, con las preferencias', () async {
      when(
        () => list(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect((cubit.state as ViewPartial<AlertsOverview>).missing, {
        'subscriptions',
      });
    });

    test(
      'si falla todo, error recuperable; al reintentar se recupera',
      () async {
        when(
          () => getPreferences(any()),
        ).thenAnswer((_) async => const Err(NetworkFailure()));
        when(
          () => list(any()),
        ).thenAnswer((_) async => const Err(NetworkFailure()));

        await cubit.load();
        expect(cubit.state, isA<ViewError<AlertsOverview>>());

        when(
          () => getPreferences(any()),
        ).thenAnswer((_) async => const Success(s.preferences));
        when(
          () => list(any()),
        ).thenAnswer((_) async => Success(s.sampleSubscriptions()));
        await cubit.load();

        expect(cubit.state, isA<ViewData<AlertsOverview>>());
      },
    );

    test('al recargar conserva lo que ya se veía', () async {
      await cubit.load();
      final before = dataOf();

      final states = <ViewState<AlertsOverview>>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.refresh();
      await sub.cancel();

      expect((states.first as ViewLoading<AlertsOverview>).previous, before);
    });
  });

  group('preferencias (US24)', () {
    setUp(() async => cubit.load());

    test('el interruptor cambia al instante y se guarda', () async {
      final saved = Completer<Result<NotificationPreferences>>();
      when(() => savePreferences(any())).thenAnswer((_) => saved.future);

      unawaited(cubit.setPreference(AlertPreference.events, value: true));
      await settle();

      // Aún sin respuesta del servidor, ya se ve encendido.
      expect(dataOf().preferences?.eventAlerts, isTrue);
      saved.complete(
        Success(s.preferences.copyWith(eventAlerts: true)),
      );
      await settle();
      await settle();

      final sent =
          verify(() => savePreferences(captureAny())).captured.single
              as NotificationPreferences;
      expect(sent.eventAlerts, isTrue);
      // Solo cambió esa alerta: lo demás sigue igual.
      expect(sent.saturationAlerts, s.preferences.saturationAlerts);
      expect(sent.language, s.preferences.language);
    });

    test('si el servidor no lo guarda, vuelve a lo guardado y avisa', () async {
      when(
        () => savePreferences(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.setPreference(AlertPreference.lowArrival, value: true);
      await settle();
      await settle();

      expect(dataOf().preferences?.lowArrivalAlerts, isFalse);
      await settle();
      expect(notices, [AlertsNotice.saveFailed]);
    });

    test(
      'dos cambios seguidos se guardan de uno en uno, con lo último',
      () async {
        final first = Completer<Result<NotificationPreferences>>();
        var calls = 0;
        when(() => savePreferences(any())).thenAnswer((invocation) {
          calls++;
          final sent =
              invocation.positionalArguments.single as NotificationPreferences;
          return calls == 1 ? first.future : Future.value(Success(sent));
        });

        unawaited(cubit.setPreference(AlertPreference.events, value: true));
        await settle();
        unawaited(cubit.setPreference(AlertPreference.staleData, value: false));
        await settle();
        expect(calls, 1);

        first.complete(Success(s.preferences.copyWith(eventAlerts: true)));
        await settle();
        await settle();
        await settle();

        expect(calls, 2);
        final last =
            verify(() => savePreferences(captureAny())).captured.last
                as NotificationPreferences;
        expect(last.eventAlerts, isTrue);
        expect(last.staleDataAlerts, isFalse);
        expect(dataOf().preferences?.staleDataAlerts, isFalse);
        expect(dataOf().preferences?.eventAlerts, isTrue);
      },
    );

    test('un valor igual no guarda nada', () async {
      await cubit.setPreference(AlertPreference.saturation, value: true);

      verifyNever(() => savePreferences(any()));
    });
  });

  group('interruptor general', () {
    setUp(() async {
      when(() => getPreferences(any())).thenAnswer(
        (_) async => Success(s.preferences.copyWith(pushEnabled: false)),
      );
      await cubit.load();
    });

    test('activar pide el permiso, registra el teléfono y guarda', () async {
      await cubit.setPushEnabled(enabled: true);
      await settle();

      verify(() => activate(any())).called(1);
      expect(dataOf().preferences?.pushEnabled, isTrue);
      await settle();
      expect(notices, isEmpty);
    });

    test('si el conductor niega el permiso, no cambia y se explica', () async {
      when(
        () => activate(any()),
      ).thenAnswer(
        (_) async => const Success(DeviceActivation.permissionDenied),
      );

      await cubit.setPushEnabled(enabled: true);

      expect(dataOf().preferences?.pushEnabled, isFalse);
      await settle();
      expect(notices, [AlertsNotice.permissionDenied]);
      verifyNever(() => savePreferences(any()));
    });

    test('con el permiso bloqueado se explica cómo activarlo', () async {
      when(() => activate(any())).thenAnswer(
        (_) async => const Success(DeviceActivation.permissionBlocked),
      );

      await cubit.setPushEnabled(enabled: true);

      await settle();
      expect(notices, [AlertsNotice.permissionBlocked]);
    });

    test('sin token o sin red al registrar, avisa y no cambia', () async {
      when(
        () => activate(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.setPushEnabled(enabled: true);

      expect(dataOf().preferences?.pushEnabled, isFalse);
      await settle();
      expect(notices, [AlertsNotice.activationFailed]);
    });

    test(
      'desactivar solo guarda: no pide ningún permiso (US24 esc. 2)',
      () async {
        await cubit.load();
        when(
          () => getPreferences(any()),
        ).thenAnswer((_) async => const Success(s.preferences));
        await cubit.load();

        await cubit.setPushEnabled(enabled: false);
        await settle();

        verifyNever(() => activate(any()));
        expect(dataOf().preferences?.pushEnabled, isFalse);
      },
    );
  });

  group('franjas (US33)', () {
    setUp(() async => cubit.load());

    CreateAlertSubscriptionParams params() => CreateAlertSubscriptionParams(
      lotId: const LotId(1),
      days: const {1, 3},
      from: s.time(17, 0),
      to: s.time(18, 0),
    );

    for (final (activation, notice) in [
      (DeviceActivation.registered, AlertsNotice.created),
      (DeviceActivation.permissionDenied, AlertsNotice.createdDenied),
      (DeviceActivation.permissionBlocked, AlertsNotice.createdBlocked),
      (DeviceActivation.registrationFailed, AlertsNotice.createdNoDevice),
    ]) {
      test('crear agrega la franja y avisa del permiso: $activation', () async {
        final created = s.subscription(id: 9);
        when(() => create(any())).thenAnswer(
          (_) async => Success(
            CreatedAlertSubscription(subscription: created, device: activation),
          ),
        );

        final result = await cubit.createSubscription(params());

        expect(result.isSuccess, isTrue);
        expect(dataOf().subscriptions?.last, created);
        expect(dataOf().subscriptions, hasLength(4));
        await settle();
        expect(notices, [notice]);
      });
    }

    test(
      'si no se puede crear, devuelve el error y no cambia la lista',
      () async {
        when(() => create(any())).thenAnswer(
          (_) async => const Err(
            ValidationFailure('x', {
              'slot': ['duplicate'],
            }),
          ),
        );

        final result = await cubit.createSubscription(params());

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(dataOf().subscriptions, hasLength(3));
        await settle();
        expect(notices, isEmpty);
      },
    );

    test('pausar una franja la conserva y las demás no cambian', () async {
      final first = s.sampleSubscriptions().first;
      when(() => setActive(any())).thenAnswer(
        (_) async => Success(first.copyWith(active: false)),
      );

      await cubit.setSubscriptionActive(first, active: false);

      final all = dataOf().subscriptions!;
      expect(all, hasLength(3));
      expect(all.first.active, isFalse);
      expect(all[1], s.sampleSubscriptions()[1]);
    });

    test('si el servidor no la cambia, vuelve atrás y avisa', () async {
      final first = s.sampleSubscriptions().first;
      when(
        () => setActive(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.setSubscriptionActive(first, active: false);

      expect(dataOf().subscriptions?.first.active, isTrue);
      await settle();
      expect(notices, [AlertsNotice.slotFailed]);
    });

    test(
      'reactivar una franja repetida (409) vuelve atrás y lo dice',
      () async {
        final paused = s.sampleSubscriptions().last;
        when(() => setActive(any())).thenAnswer(
          (_) async => const Err(
            ValidationFailure('x', {
              'slot': ['duplicate'],
            }),
          ),
        );

        await cubit.setSubscriptionActive(paused, active: true);

        expect(dataOf().subscriptions?.last.active, isFalse);
        await settle();
        expect(notices, [AlertsNotice.slotDuplicate]);
      },
    );

    test('eliminar quita solo esa franja y avisa', () async {
      when(
        () => remove(any()),
      ).thenAnswer((_) async => const Success<void>(null));

      await cubit.removeSubscription(s.sampleSubscriptions().first);

      expect(dataOf().subscriptions?.map((e) => e.id.value), [2, 3]);
      await settle();
      expect(notices, [AlertsNotice.deleted]);
    });

    test('si no se pudo eliminar, la franja sigue y se avisa', () async {
      when(
        () => remove(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.removeSubscription(s.sampleSubscriptions().first);

      expect(dataOf().subscriptions, hasLength(3));
      await settle();
      expect(notices, [AlertsNotice.deleteFailed]);
    });
  });
}
