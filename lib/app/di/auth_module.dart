import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/auth_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_cubit.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';

/// Crea el cubit de `/login`. Cada pantalla tiene el suyo (nunca se comparte
/// entre rutas): el router lo crea con lo que solo él sabe, adónde ir.
typedef CreateLoginCubit =
    LoginCubit Function(void Function(OtpChallenge challenge) onCodeSent);

/// Crea el cubit de `/login/verify` para el código pedido.
typedef CreateVerifyCodeCubit =
    VerifyCodeCubit Function(
      OtpChallenge challenge,
      void Function(Session session) onSignedIn,
    );

/// Crea el cubit del cierre de sesión de `/lots`.
typedef CreateSignOutCubit = SignOutCubit Function(void Function() onSignedOut);

/// Presentación del acceso: el estado de sesión de la app (un solo
/// `AuthCubit`, lo lee el router) y las fábricas de los cubits de cada
/// pantalla.
///
/// Los cubits de pantalla **no** son singletons: cada ruta crea el suyo y lo
/// cierra al salir (docs/04, "Patrón de presentación"). `get_it` no sale de
/// `app/di`: el router recibe estas fábricas por parámetro.
void registerAuthModule(GetIt locator) {
  locator
    ..addLazy<Countdown>(() => Countdown(locator<Clock>()))
    ..addLazy<AuthCubit>(
      () => AuthCubit(restoreSession: locator()),
      dispose: (cubit) => cubit.close(),
    )
    ..addValue<CreateLoginCubit>(
      (onCodeSent) => LoginCubit(
        requestOtp: locator(),
        countdown: locator(),
        onCodeSent: onCodeSent,
      ),
    )
    ..addValue<CreateVerifyCodeCubit>(
      (challenge, onSignedIn) => VerifyCodeCubit(
        challenge: challenge,
        signIn: locator(),
        requestOtp: locator(),
        clock: locator<Clock>(),
        countdown: locator(),
        onSignedIn: onSignedIn,
      ),
    )
    ..addValue<CreateSignOutCubit>(
      (onSignedOut) =>
          SignOutCubit(signOut: locator(), onSignedOut: onSignedOut),
    );
}
