import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/session/pending_removal_retrier.dart';
import 'package:quadrapp_mobile/app/session/session_expiry_coordinator.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/in_memory_access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/core/session/key_value_resettable.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Cierre de sesión (US02, US03): la lista única de lo que se limpia, el caso
/// de uso `SignOut` y lo que lo dispara o lo reintenta.
///
/// **Esta es la única lista de `Resettable`.** Todo lo que guarde datos de un
/// usuario debe estar aquí o bajo un prefijo cubierto por
/// `KeyValueResettable`; la prueba `resettable_stores_test.dart` falla si no.
/// Quedan fuera, a propósito, solo dos cosas bajo `device.`: el idioma y la
/// baja pendiente del token push (`device.pendingPushTokenRemoval`).
void registerSignOutModule(GetIt locator) {
  locator
    ..addLazy<ResettableRegistry>(
      () => ResettableRegistry()
        // `user.` (estacionamiento elegido, token push registrado, usuario) y
        // `cache.` (layout y última ocupación): cualquier clave nueva bajo
        // esos prefijos se limpia sin tocar código.
        ..register(
          KeyValueResettable(locator<KeyValueStore>(), [
            StoreKeys.user,
            StoreKeys.cache,
          ]),
        )
        // Refresh token (almacén seguro) y usuario guardado.
        ..register(locator<SessionStoreImpl>())
        // Access token (solo en memoria).
        ..register(locator<InMemoryAccessTokenHolder>()),
    )
    ..addLazy<SignOut>(
      () => SignOut(
        getPushToken: locator(),
        removePushToken: locator(),
        revokeSession: locator(),
        clearSession: locator(),
        resettables: locator(),
      ),
    )
    // Reintenta la baja pendiente del token push al arrancar y al volver a
    // primer plano (`startAppServices`).
    ..addLazy<PendingRemovalRetrier>(
      () => PendingRemovalRetrier(locator()),
      dispose: (retrier) => retrier.dispose(),
    )
    // Sesión expirada → `SignOut(sessionExpired)`; el router la escucha.
    ..addLazy<SessionExpiryCoordinator>(
      () => SessionExpiryCoordinator(
        watchExpiry: locator(),
        signOut: locator(),
      ),
      dispose: (coordinator) => coordinator.dispose(),
    );
}
