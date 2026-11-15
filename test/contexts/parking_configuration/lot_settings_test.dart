// US19, US29: la configuración propia del estacionamiento.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_settings_writer.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_settings_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_settings_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/lot_settings_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/lot_settings_writer_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

import '../../helpers/recording_logger.dart';

class _MockWriter extends Mock implements LotSettingsWriter {}

class _FakeRemote implements LotSettingsRemoteDataSource {
  Future<LotSettingsDto> Function(LotSettingsDto) handler = (dto) async => dto;
  LotSettingsDto? sent;

  @override
  Future<LotSettingsDto> update(LotId lotId, LotSettingsDto settings) {
    sent = settings;
    return handler(settings);
  }
}

LotTime _t(int hour, [int minute = 0]) => LotTime.of(hour, minute)!;

LotSettings _settings({
  LotTime? opensAt,
  LotTime? closesAt,
  int pct = 85,
}) =>
    (LotSettings.create(
              opensAt: opensAt,
              closesAt: closesAt,
              saturationThresholdPct: pct,
            )
            as Success<LotSettings>)
        .value;

void main() {
  group('LotTime', () {
    test('lee HH:mm y HH:mm:ss (un TIME de PostgreSQL)', () {
      expect(LotTime.parse('08:00'), _t(8));
      expect(LotTime.parse('16:30:00'), _t(16, 30));
      expect(_t(7, 5).hhmm, '07:05');
    });

    test('una hora ilegible o fuera de rango es null', () {
      for (final raw in [null, '', '8', '24:00', '12:60', 'ab:cd']) {
        expect(LotTime.parse(raw), isNull, reason: '$raw');
      }
    });
  });

  group('LotSettings (reglas de dominio)', () {
    test('un horario completo con cierre después de la apertura es válido', () {
      final result = LotSettings.create(
        opensAt: _t(8),
        closesAt: _t(16),
        saturationThresholdPct: 85,
      );

      expect(result, isA<Success<LotSettings>>());
      expect((result as Success<LotSettings>).value.hasSchedule, isTrue);
    });

    test('sin horario también es válido (opens_at es opcional)', () {
      final settings = _settings();

      expect(settings.hasSchedule, isFalse);
    });

    test('apertura sin cierre: horario incompleto', () {
      expect(
        LotSettings.validate(
          opensAt: _t(8),
          closesAt: null,
          saturationThresholdPct: 85,
        ),
        {LotSettingsError.scheduleIncomplete},
      );
    });

    test('el cierre debe ser posterior a la apertura (ni igual ni antes)', () {
      for (final closes in [_t(8), _t(7, 59)]) {
        final result = LotSettings.create(
          opensAt: _t(8),
          closesAt: closes,
          saturationThresholdPct: 85,
        );

        expect(result, isA<Err<LotSettings>>());
        final failure = (result as Err<LotSettings>).failure;
        expect(
          (failure as ValidationFailure).errors['closesAt'],
          ['closesBeforeOpens'],
        );
      }
    });

    test('la alerta de ocupación va de 1 a 100 %', () {
      for (final pct in [0, 101]) {
        expect(
          LotSettings.validate(
            opensAt: null,
            closesAt: null,
            saturationThresholdPct: pct,
          ),
          {LotSettingsError.thresholdOutOfRange},
          reason: '$pct',
        );
      }
      expect(_settings(pct: 1).saturationThresholdPct, 1);
      expect(_settings(pct: 100).saturationThresholdPct, 100);
    });

    test('tolerant: lo inválido del servidor queda sin horario y en rango', () {
      final read = LotSettings.tolerant(
        opensAt: _t(18),
        closesAt: _t(8),
        saturationThresholdPct: 140,
      );

      expect(read.adjusted, isTrue);
      expect(read.settings.hasSchedule, isFalse);
      expect(read.settings.saturationThresholdPct, 100);
    });
  });

  group('UpdateLotSettings', () {
    late _MockWriter writer;

    setUpAll(() => registerFallbackValue(_settings()));

    setUp(() => writer = _MockWriter());

    test(
      'guarda con el escritor y devuelve lo que quedó en el servidor',
      () async {
        final sent = _settings(opensAt: _t(7), closesAt: _t(22), pct: 80);
        when(
          () => writer.update(const LotId(1), sent),
        ).thenAnswer((_) async => Success(sent));

        final result = await UpdateLotSettings(writer)((
          lotId: const LotId(1),
          settings: sent,
        ));

        expect(result, Success(sent));
        verify(() => writer.update(const LotId(1), sent)).called(1);
      },
    );

    test('el 403 del servidor llega como ForbiddenFailure', () async {
      when(
        () => writer.update(any(), any()),
      ).thenAnswer((_) async => const Err(ForbiddenFailure()));

      final result = await UpdateLotSettings(writer)((
        lotId: const LotId(1),
        settings: _settings(),
      ));

      expect(result, const Err<LotSettings>(ForbiddenFailure()));
    });
  });

  group('LotSettingsWriterImpl', () {
    late _FakeRemote remote;
    late RecordingLogger logger;
    late LotSettingsWriterImpl writerImpl;

    setUp(() {
      remote = _FakeRemote();
      logger = RecordingLogger();
      writerImpl = LotSettingsWriterImpl(
        remote: remote,
        mapper: LotSettingsMapper(logger),
      );
    });

    test('caso feliz: envía HH:mm y lee la respuesta', () async {
      final result = await writerImpl.update(
        const LotId(1),
        _settings(opensAt: _t(8), closesAt: _t(16)),
      );

      expect(remote.sent?.toJson(), {
        'opensAt': '08:00',
        'closesAt': '16:00',
        'saturationThresholdPct': 85,
      });
      expect(
        result,
        Success(_settings(opensAt: _t(8), closesAt: _t(16))),
      );
    });

    test('sin red: NetworkFailure', () async {
      remote.handler = (_) async =>
          throw mockDioError(DioExceptionType.connectionError);

      final result = await writerImpl.update(const LotId(1), _settings());

      expect((result as Err<LotSettings>).failure, isA<NetworkFailure>());
    });

    test(
      'una hora ilegible del servidor no rompe: sin horario y un aviso',
      () async {
        remote.handler = (_) async => const LotSettingsDto(
          opensAt: '8 am',
          closesAt: '16:00',
          saturationThresholdPct: 85,
        );

        final result = await writerImpl.update(const LotId(1), _settings());

        expect((result as Success<LotSettings>).value.hasSchedule, isFalse);
        expect(logger.messages, hasLength(1));
      },
    );
  });
}
