// US04: la sede que ve el conductor (elegida, recordada, sola si es única).
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

class _MockList extends Mock implements ListParkingLots {}

class _MockGetSelected extends Mock implements GetSelectedLot {}

class _MockSelect extends Mock implements SelectLot {}

ParkingLot _lot(int id, String name, {int layoutVersion = 3}) => ParkingLot(
  id: LotId(id),
  name: name,
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
);

void main() {
  late _MockList list;
  late _MockGetSelected getSelected;
  late _MockSelect select;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const LotId(1));
  });

  setUp(() {
    list = _MockList();
    getSelected = _MockGetSelected();
    select = _MockSelect();
    when(() => getSelected(any())).thenAnswer((_) async => const Success(null));
    when(() => select(any())).thenAnswer((_) async => const Success(null));
  });

  SedeCubit cubit() => SedeCubit(
    listParkingLots: list,
    getSelectedLot: getSelected,
    selectLot: select,
  );

  void listReturns(List<ParkingLot> lots) =>
      when(() => list(any())).thenAnswer((_) async => Success(lots));

  final monterrico = _lot(1, 'Monterrico');
  final villa = _lot(4, 'Villa');

  group('SedeCubit', () {
    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'con varias sedes y ninguna elegida, la lista llega sin sede elegida',
      setUp: () => listReturns([monterrico, villa]),
      build: cubit,
      act: (c) => c.load(),
      expect: () => [
        const ViewLoading<SedeSelection>(),
        ViewData(SedeSelection(lots: [monterrico, villa])),
      ],
      verify: (_) => verifyNever(() => select(any())),
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'la sede recordada llega elegida',
      setUp: () {
        listReturns([monterrico, villa]);
        when(
          () => getSelected(any()),
        ).thenAnswer((_) async => const Success(LotId(4)));
      },
      build: cubit,
      act: (c) => c.load(),
      verify: (c) {
        final data = (c.state as ViewData<SedeSelection>).data;
        expect(data.selected, villa);
      },
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'una sede recordada que ya no existe se trata como sin elegir',
      setUp: () {
        listReturns([monterrico, villa]);
        when(
          () => getSelected(any()),
        ).thenAnswer((_) async => const Success(LotId(99)));
      },
      build: cubit,
      act: (c) => c.load(),
      verify: (c) {
        final data = (c.state as ViewData<SedeSelection>).data;
        expect(data.hasSelection, isFalse);
      },
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'con una sola sede, se elige sola y se recuerda',
      setUp: () => listReturns([monterrico]),
      build: cubit,
      act: (c) => c.load(),
      verify: (c) {
        final data = (c.state as ViewData<SedeSelection>).data;
        expect(data.selected, monterrico);
        verify(() => select(const LotId(1))).called(1);
      },
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'sin sedes: vacío',
      setUp: () => listReturns(const []),
      build: cubit,
      act: (c) => c.load(),
      expect: () => [
        const ViewLoading<SedeSelection>(),
        const ViewEmpty<SedeSelection>(),
      ],
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'si falla la lista: error con su causa',
      setUp: () => when(
        () => list(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure())),
      build: cubit,
      act: (c) => c.load(),
      expect: () => [
        const ViewLoading<SedeSelection>(),
        const ViewError<SedeSelection>(NetworkFailure()),
      ],
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'elegir guarda la sede y la deja elegida; una repetida o inexistente '
      'no hace nada',
      setUp: () => listReturns([monterrico, villa]),
      build: cubit,
      act: (c) async {
        await c.load();
        await c.select(const LotId(4));
        await c.select(const LotId(4));
        await c.select(const LotId(99));
      },
      verify: (c) {
        final data = (c.state as ViewData<SedeSelection>).data;
        expect(data.selected, villa);
        verify(() => select(const LotId(4))).called(1);
        verifyNever(() => select(const LotId(99)));
      },
    );

    blocTest<SedeCubit, ViewState<SedeSelection>>(
      'si no se puede guardar, la sede igual queda elegida',
      setUp: () {
        listReturns([monterrico, villa]);
        when(
          () => select(any()),
        ).thenAnswer((_) async => const Err(UnknownFailure()));
      },
      build: cubit,
      act: (c) async {
        await c.load();
        await c.select(const LotId(1));
      },
      verify: (c) {
        final data = (c.state as ViewData<SedeSelection>).data;
        expect(data.selected, monterrico);
      },
    );
  });
}
