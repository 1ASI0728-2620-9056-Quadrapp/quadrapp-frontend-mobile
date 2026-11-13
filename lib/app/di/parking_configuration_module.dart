import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/operations_module.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/parking_configuration/mock_parking_configuration_datasources.dart';
import 'package:quadrapp_mobile/composition/layout_editor/layout_editor_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/get_lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/get_parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/get_selected_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/layout_draft_usecases.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/list_parking_lots.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/resolve_selected_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/select_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_draft_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_publisher.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_layout_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/parking_lot_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/layout_publish_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/layout_draft_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/layout_draft_repositories.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/lot_layout_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/parking_lot_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/selected_lot_store_impl.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Crea el cubit de «Editar distribución»: el router lo crea al entrar a la
/// ruta y lo cierra al salir.
typedef CreateLayoutEditorCubit = LayoutEditorCubit Function();

/// Contexto `parking_configuration`: estacionamientos, distribución y el
/// estacionamiento elegido (US04, US05).
///
/// La caché del layout (`cache.`), el estacionamiento elegido y el borrador de
/// la distribución (`user.`) se
/// limpian al cerrar sesión por sus prefijos (`KeyValueResettable` en
/// `sign_out_module`).
void registerParkingConfigurationModule(GetIt locator, AppConfig config) {
  locator
    // --- infraestructura ---
    ..addLazy<ParkingLotRemoteDataSource>(
      () => config.useMocks
          ? MockParkingLotRemoteDataSource(locator<MockWorld>())
          : ParkingLotHttpDataSource(locator<Dio>()),
    )
    ..addLazy<LotLayoutRemoteDataSource>(
      () => config.useMocks
          ? MockLotLayoutRemoteDataSource(locator<MockWorld>())
          : LotLayoutHttpDataSource(locator<Dio>()),
    )
    ..addLazy<LotLayoutCacheDataSource>(
      () => LotLayoutCacheDataSource(locator<KeyValueStore>()),
    )
    ..addLazy<ParkingLotReader>(
      () => ParkingLotReaderImpl(remote: locator()),
    )
    ..addLazy<LotLayoutReader>(
      () => LotLayoutReaderImpl(remote: locator(), cache: locator()),
    )
    ..addLazy<SelectedLotStore>(
      () => SelectedLotStoreImpl(locator<KeyValueStore>()),
    )
    // --- borrador y publicación de la distribución (US17) ---
    ..addLazy<LayoutDraftMapper>(() => LayoutDraftMapper(locator<Logger>()))
    ..addLazy<LayoutDraftStore>(
      () => LayoutDraftStoreImpl(locator<KeyValueStore>(), locator()),
    )
    ..addLazy<LayoutPublishRemoteDataSource>(
      () => config.useMocks
          ? MockLayoutPublishDataSource(
              locator<MockWorld>(),
              mockCallerRole(locator),
            )
          : LayoutPublishHttpDataSource(locator<Dio>()),
    )
    ..addLazy<LayoutPublisher>(
      () => LayoutPublisherImpl(remote: locator(), mapper: locator()),
    )
    // --- casos de uso ---
    ..addLazy<ListParkingLots>(() => ListParkingLots(locator()))
    ..addLazy<GetParkingLot>(() => GetParkingLot(locator()))
    ..addLazy<GetLotLayout>(() => GetLotLayout(locator()))
    ..addLazy<SelectLot>(() => SelectLot(locator()))
    ..addLazy<GetLayoutDraft>(() => GetLayoutDraft(locator()))
    ..addLazy<SaveLayoutDraft>(() => SaveLayoutDraft(locator()))
    ..addLazy<DiscardLayoutDraft>(() => DiscardLayoutDraft(locator()))
    ..addLazy<PublishLayout>(
      () => PublishLayout(publisher: locator(), store: locator()),
    )
    ..addValue<CreateLayoutEditorCubit>(
      () => LayoutEditorCubit(
        getLotLayout: locator(),
        getDraft: locator(),
        saveDraft: locator(),
        discardDraft: locator(),
        publishLayout: locator(),
      ),
    )
    ..addLazy<GetSelectedLot>(() => GetSelectedLot(locator()))
    ..addLazy<ResolveSelectedLot>(
      () => ResolveSelectedLot(reader: locator(), store: locator()),
    );
}
