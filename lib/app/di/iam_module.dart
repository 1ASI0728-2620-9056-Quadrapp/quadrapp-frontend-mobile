import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/iam/mock_auth_datasource.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/session/session_token_source.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/expire_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/request_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/restore_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_in_with_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_out_usecases.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/watch_session_expiry.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_events.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/auth_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/auth_repository_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/in_memory_access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/stream_session_events.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Contexto `iam`: sesión con OTP, refresh compartido y expiración (US01–US03).
///
/// `SessionStoreImpl` y `InMemoryAccessTokenHolder` guardan datos del usuario:
/// se registran también con su tipo concreto para que `sign_out_module` los
/// incluya en la lista de `Resettable`.
void registerIamModule(GetIt locator, AppConfig config) {
  locator
    // --- infraestructura ---
    ..addLazy<AuthRemoteDataSource>(
      () => config.useMocks
          ? MockAuthRemoteDataSource(locator<MockWorld>())
          : AuthHttpDataSource(locator<Dio>()),
    )
    ..addLazy<IamMapper>(() => IamMapper(locator<Logger>()))
    ..addLazy<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addLazy<SessionStoreImpl>(
      () => SessionStoreImpl(
        values: locator<KeyValueStore>(),
        secrets: locator<SecureStore>(),
        mapper: locator(),
      ),
    )
    ..addLazy<SessionStore>(() => locator<SessionStoreImpl>())
    ..addLazy<InMemoryAccessTokenHolder>(InMemoryAccessTokenHolder.new)
    ..addLazy<AccessTokenHolder>(() => locator<InMemoryAccessTokenHolder>())
    ..addLazy<StreamSessionEvents>(
      StreamSessionEvents.new,
      dispose: (events) => events.dispose(),
    )
    ..addLazy<SessionEvents>(() => locator<StreamSessionEvents>())
    // --- casos de uso ---
    ..addLazy<RequestOtp>(() => RequestOtp(locator()))
    ..addLazy<SignInWithOtp>(
      () => SignInWithOtp(
        auth: locator(),
        sessions: locator(),
        accessToken: locator(),
      ),
    )
    ..addLazy<RestoreSession>(() => RestoreSession(locator()))
    ..addLazy<ExpireSession>(
      () => ExpireSession(
        sessions: locator(),
        accessToken: locator(),
        events: locator(),
      ),
    )
    // Un solo `RefreshSession`: comparte el refresh en curso entre llamadas.
    ..addLazy<RefreshSession>(
      () => RefreshSession(
        auth: locator(),
        sessions: locator(),
        accessToken: locator(),
        expire: locator(),
      ),
    )
    ..addLazy<RevokeSession>(
      () => RevokeSession(auth: locator(), sessions: locator()),
    )
    ..addLazy<ClearSession>(
      () => ClearSession(sessions: locator(), accessToken: locator()),
    )
    ..addLazy<WatchSessionExpiry>(() => WatchSessionExpiry(locator()))
    // --- puente con el AuthInterceptor de core ---
    ..addLazy<SessionTokenSource>(
      () => SessionTokenSource(accessToken: locator(), refresh: locator()),
    );
}
