import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/get_lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/get_parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/get_selected_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/list_parking_lots.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/resolve_selected_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/select_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_layout_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/parking_lot_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import 'support.dart';

class _MockLotReader extends Mock implements ParkingLotReader {}

class _MockLayoutReader extends Mock implements LotLayoutReader {}

class _MockSelectedLotStore extends Mock implements SelectedLotStore {}

void main() {
  setUpAll(() => registerFallbackValue(const LotId(0)));

  late _MockLotReader lots;
  late _MockSelectedLotStore store;

  setUp(() {
    lots = _MockLotReader();
    store = _MockSelectedLotStore();
  });

  group('casos de uso de lectura', () {
    test('ListParkingLots devuelve la lista (vacía = sin estacionamientos '
        'registrados)', () async {
      when(() => lots.list()).thenAnswer((_) async => const Success([]));

      final result = await ListParkingLots(lots)(const NoParams());

      expect(result, const Success<List<ParkingLot>>([]));
    });

    test('ListParkingLots propaga la falla', () async {
      when(() => lots.list()).thenAnswer(
        (_) async => const Err<List<ParkingLot>>(NetworkFailure()),
      );

      final result = await ListParkingLots(lots)(const NoParams());

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('GetParkingLot pide el estacionamiento por id', () async {
      when(() => lots.get(const LotId(1))).thenAnswer(
        (_) async => Success(lotEntity(1)),
      );

      final result = await GetParkingLot(lots)(const LotId(1));

      expect(result, Success(lotEntity(1)));
      verify(() => lots.get(const LotId(1))).called(1);
    });

    test('GetLotLayout pide la distribución por id', () async {
      final reader = _MockLayoutReader();
      when(() => reader.read(const LotId(1))).thenAnswer(
        (_) async => Success(sampleLayout()),
      );

      final result = await GetLotLayout(reader)(const LotId(1));

      expect(result, Success(sampleLayout()));
    });

    test(
      'GetLotLayout propaga NotFound (sin distribución publicada)',
      () async {
        final reader = _MockLayoutReader();
        when(() => reader.read(const LotId(3))).thenAnswer(
          (_) async => const Err<LotLayout>(NotFoundFailure()),
        );

        final result = await GetLotLayout(reader)(const LotId(3));

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );
  });

  group('SelectLot', () {
    test('guarda el estacionamiento elegido', () async {
      when(() => store.save(const LotId(2))).thenAnswer((_) async {});

      final result = await SelectLot(store)(const LotId(2));

      expect(result.isSuccess, isTrue);
      verify(() => store.save(const LotId(2))).called(1);
    });

    test('si el almacenamiento falla devuelve una Failure, no una '
        'excepción', () async {
      when(() => store.save(const LotId(2))).thenThrow(StateError('disco'));

      final result = await SelectLot(store)(const LotId(2));

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('GetSelectedLot', () {
    test('devuelve el estacionamiento elegido antes', () async {
      when(() => store.read()).thenAnswer((_) async => const LotId(2));

      final result = await GetSelectedLot(store)(const NoParams());

      expect(result.valueOrNull, const LotId(2));
    });

    test('sin elección devuelve null, y si el almacenamiento falla, una '
        'Failure', () async {
      when(() => store.read()).thenAnswer((_) async => null);
      expect(
        (await GetSelectedLot(store)(const NoParams())).valueOrNull,
        isNull,
      );

      when(() => store.read()).thenThrow(StateError('disco'));
      final failed = await GetSelectedLot(store)(const NoParams());
      expect(failed.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('ResolveSelectedLot', () {
    ResolveSelectedLot build() =>
        ResolveSelectedLot(reader: lots, store: store);

    void listReturns(List<ParkingLot> list) => when(
      () => lots.list(),
    ).thenAnswer((_) async => Success(list));

    test('devuelve el elegido antes si todavía existe', () async {
      listReturns([lotEntity(1), lotEntity(2)]);
      when(() => store.read()).thenAnswer((_) async => const LotId(2));

      final result = await build()(const NoParams());

      expect(result.valueOrNull, lotEntity(2));
      verifyNever(() => store.save(any()));
      verifyNever(() => store.clear());
    });

    test('con un solo estacionamiento lo elige automáticamente', () async {
      listReturns([lotEntity(5)]);
      when(() => store.read()).thenAnswer((_) async => null);
      when(() => store.save(const LotId(5))).thenAnswer((_) async {});

      final result = await build()(const NoParams());

      expect(result.valueOrNull, lotEntity(5));
      verify(() => store.save(const LotId(5))).called(1);
    });

    test('con un solo estacionamiento reemplaza un elegido que ya no '
        'existe', () async {
      listReturns([lotEntity(5)]);
      when(() => store.read()).thenAnswer((_) async => const LotId(9));
      when(() => store.save(const LotId(5))).thenAnswer((_) async {});

      final result = await build()(const NoParams());

      expect(result.valueOrNull, lotEntity(5));
    });

    test('con varios y ninguno elegido devuelve null: la pantalla muestra '
        '"Elegir estacionamiento"', () async {
      listReturns([lotEntity(1), lotEntity(2)]);
      when(() => store.read()).thenAnswer((_) async => null);

      final result = await build()(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
      verifyNever(() => store.save(any()));
    });

    test('con varios y un elegido que ya no existe, lo olvida y devuelve '
        'null', () async {
      listReturns([lotEntity(1), lotEntity(2)]);
      when(() => store.read()).thenAnswer((_) async => const LotId(9));
      when(() => store.clear()).thenAnswer((_) async {});

      final result = await build()(const NoParams());

      expect(result.valueOrNull, isNull);
      verify(() => store.clear()).called(1);
    });

    test('sin estacionamientos devuelve null', () async {
      listReturns(const []);
      when(() => store.read()).thenAnswer((_) async => null);

      final result = await build()(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('si no se puede listar, devuelve la falla y no toca el '
        'almacenamiento', () async {
      when(() => lots.list()).thenAnswer(
        (_) async => const Err<List<ParkingLot>>(UnauthorizedFailure()),
      );

      final result = await build()(const NoParams());

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      verifyZeroInteractions(store);
    });

    test('si el almacenamiento falla, devuelve una Failure', () async {
      listReturns([lotEntity(1)]);
      when(() => store.read()).thenThrow(StateError('disco'));

      final result = await build()(const NoParams());

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });
}
