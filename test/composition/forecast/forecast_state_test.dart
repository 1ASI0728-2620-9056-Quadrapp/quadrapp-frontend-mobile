// US09, US10, US11, US12: los horizontes de Predicción según el reloj.
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';

import '../../helpers/fake_clock.dart';
import 'support.dart';

void main() {
  group('ForecastOverview.rows', () {
    test(
      'los cuatro horizontes vigentes traen su pronóstico y su asesoría',
      () {
        final rows = overview().rows(FakeClock());

        expect([for (final row in rows) row.horizon], ForecastHorizon.values);
        expect(
          rows.every((r) => r.status == ForecastRowStatus.available),
          isTrue,
        );
        expect(rows.first.currentAdvice?.category, ArrivalCategory.high);
        expect(rows.last.currentAdvice?.category, ArrivalCategory.low);
      },
    );

    test('un horizonte sin pronóstico falta, aunque llegue su asesoría', () {
      final rows = overview(
        lotForecasts: forecasts(missing: {ForecastHorizon.min30}),
      ).rows(FakeClock());

      expect(rows[1].status, ForecastRowStatus.missing);
      // La asesoría de ese horizonte se calcularía con otro pronóstico: no se
      // presenta como el de este horizonte.
      expect(rows[1].currentAdvice, isNull);
      expect(rows[1].confidence, isNull);
    });

    test('un pronóstico vencido no se presenta como actual (US10 esc. 3)', () {
      final clock = FakeClock();
      final data = overview(
        lotForecasts: forecasts(
          overrides: {
            ForecastHorizon.min15: forecast(
              ForecastHorizon.min15,
              validFor: const Duration(minutes: 5),
            ),
          },
        ),
      );

      expect(data.rows(clock).first.status, ForecastRowStatus.available);

      // El tiempo pasa con la pantalla abierta (reloj monótono).
      clock.advance(const Duration(minutes: 6));
      final row = data.rows(clock).first;
      expect(row.status, ForecastRowStatus.expired);
      expect(row.currentAdvice, isNull);
      expect(row.confidence, isNull);
      expect(row.isLowConfidence, isFalse);
      // Los demás siguen vigentes.
      expect(data.rows(clock)[1].status, ForecastRowStatus.available);
    });

    test('la hora del teléfono no vence un pronóstico', () {
      final clock = FakeClock()..wallClock = DateTime.utc(2030);

      expect(
        overview().rows(clock).every((r) => r.isCurrent),
        isTrue,
      );
    });

    test('sin el detalle, cada horizonte sale de su asesoría', () {
      final rows = overview(
        withForecasts: false,
        lotAdvices: advices(missing: {ForecastHorizon.min60}),
      ).rows(FakeClock());

      expect(rows.take(3).every((r) => r.isCurrent), isTrue);
      expect(rows.last.status, ForecastRowStatus.missing);
      expect(rows.first.forecast, isNull);
    });

    test('«Tu llegada» y la hora de cada horizonte salen de lo generado', () {
      final first = overview().rows(FakeClock()).first;

      expect(first.generatedAt, t0.subtract(const Duration(minutes: 2)));
      expect(first.targetAt, t0.add(const Duration(minutes: 13)));
    });

    test('la antigüedad crece con el reloj monótono', () {
      final clock = FakeClock();
      final first = overview().rows(clock).first;

      expect(first.age(clock), const Duration(minutes: 2));
      clock.advance(const Duration(seconds: 30));
      expect(first.age(clock), const Duration(minutes: 2, seconds: 30));
    });
  });

  group('confianza', () {
    test('la contingencia se marca aunque la confianza no sea baja', () {
      final fallback = forecast(
        ForecastHorizon.min15,
        method: ForecastMethod.fallback,
      );
      final row = ForecastRow(
        horizon: ForecastHorizon.min15,
        status: ForecastRowStatus.available,
        forecast: fallback,
        advice: advice(ForecastHorizon.min15),
      );

      expect(row.isFallback, isTrue);
      expect(row.isLowConfidence, isTrue);
    });

    test('la confianza baja de un horizonte lejano no es contingencia', () {
      final row = ForecastRow(
        horizon: ForecastHorizon.min60,
        status: ForecastRowStatus.available,
        forecast: forecast(
          ForecastHorizon.min60,
          confidence: 0.38,
          level: ConfidenceLevel.low,
        ),
      );

      expect(row.isFallback, isFalse);
      expect(row.isLowConfidence, isTrue);
      expect(row.confidence?.level, ConfidenceLevel.low);
    });
  });

  group('ForecastOverview', () {
    test('sin pronósticos ni asesoría no hay nada que mostrar', () {
      final empty = overview(
        lotForecasts: const LotForecasts([]),
        lotAdvices: advices(missing: ForecastHorizon.values.toSet()),
      );

      expect(empty.hasNothing, isTrue);
      expect(overview().hasNothing, isFalse);
    });

    test('la sede sin distribución publicada no tiene información', () {
      expect(
        overview(parkingLot: lot(layoutVersion: 0)).hasNoData,
        isTrue,
      );
    });
  });
}
