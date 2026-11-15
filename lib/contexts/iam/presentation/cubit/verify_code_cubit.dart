// US01 (esc. 2, 3), US03 (esc. 3), TS01 (esc. 3, 4)
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/request_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_in_with_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_state.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// `/login/verify`: verifica el código de un solo uso y permite reenviarlo.
///
/// - Un código con vigencia vencida (según el reloj monótono) no se manda al
///   servidor: se trata igual que un 401 ("pide uno nuevo", US01 esc. 3).
/// - 401 (incorrecto, vencido o con intentos agotados), red y otras causas
///   salen como `ViewError(failure)`; el formulario se conserva en `previous`.
/// - "Reenviar código" tiene una cuenta regresiva (`resendCooldown` tras cada
///   envío; en un 429, el `retryAfter` del servidor).
/// - `onSignedIn` recibe la sesión nueva (cualquier rol; US01 esc. 2).
class VerifyCodeCubit extends Cubit<ViewState<VerifyForm>> {
  VerifyCodeCubit({
    required OtpChallenge challenge,
    required this._signIn,
    required this._requestOtp,
    required this._clock,
    required this._countdown,
    required this._onSignedIn,
  }) : _challenge = challenge,
       _form = VerifyForm(
         email: challenge.email,
         resendBlockedFor: resendCooldown,
       ),
       super(
         ViewData(
           VerifyForm(
             email: challenge.email,
             resendBlockedFor: resendCooldown,
           ),
         ),
       ) {
    _startCooldown(resendCooldown);
  }

  /// Espera entre un envío del código y el siguiente. Es una decisión de
  /// interfaz (evitar toques repetidos), no una regla del servidor.
  static const Duration resendCooldown = Duration(seconds: 30);

  /// Espera si el servidor responde 429 sin `retryAfter`.
  static const Duration defaultRetryAfter = Duration(seconds: 60);

  OtpChallenge _challenge;
  final SignInWithOtp _signIn;
  final RequestOtp _requestOtp;
  final Clock _clock;
  final Countdown _countdown;
  final void Function(Session session) _onSignedIn;

  /// El formulario actual: sigue siendo el mismo mientras se verifica o tras
  /// un error.
  VerifyForm _form;

  StreamSubscription<Duration>? _cooldownTimer;

  /// El usuario escribe: quita el error y el aviso de "código reenviado".
  void codeChanged() {
    final hadNotice = _form.notice == VerifyNotice.resent;
    if (hadNotice) _form = _form.copyWith(clearNotice: true);
    if (state is ViewError || hadNotice) emit(ViewData(_form));
  }

  /// Verifica el código escrito. Sin efecto mientras ya se está verificando.
  Future<void> submit(String rawCode) async {
    if (state is ViewLoading || _form.resending) return;
    if (_challenge.isExpired(_clock)) {
      emit(ViewError(const UnauthorizedFailure(), previous: _form));
      return;
    }

    _form = _form.copyWith(clearNotice: true);
    emit(ViewLoading(previous: _form));
    final result = await _signIn(
      SignInWithOtpParams(email: _challenge.email.value, code: rawCode),
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(ViewData(_form));
        _onSignedIn(value);
      case Err(:final failure):
        emit(ViewError(failure, previous: _form));
    }
  }

  /// Pide un código nuevo para el mismo correo.
  Future<void> resend() async {
    if (!_form.canResend || state is ViewLoading) return;
    _form = _form.copyWith(resending: true, clearNotice: true);
    emit(ViewData(_form));

    final result = await _requestOtp(_challenge.email.value);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        _challenge = value;
        _form = _form.copyWith(resending: false, notice: VerifyNotice.resent);
        _startCooldown(resendCooldown);
      case Err(failure: RateLimitedFailure(:final retryAfter)):
        final wait = retryAfter ?? defaultRetryAfter;
        _form = _form.copyWith(
          resending: false,
          notice: VerifyNotice.resendRateLimited,
        );
        _startCooldown(wait);
      case Err(failure: NetworkFailure()):
        _form = _form.copyWith(
          resending: false,
          notice: VerifyNotice.resendNetworkError,
        );
      case Err():
        _form = _form.copyWith(
          resending: false,
          notice: VerifyNotice.resendFailed,
        );
    }
    emit(ViewData(_form));
  }

  void _startCooldown(Duration duration) {
    _form = _form.copyWith(resendBlockedFor: duration);
    unawaited(_cooldownTimer?.cancel());
    _cooldownTimer = _countdown.run(duration).listen((remaining) {
      if (isClosed || remaining == _form.resendBlockedFor) return;
      _form = _form.copyWith(resendBlockedFor: remaining);
      emit(switch (state) {
        ViewLoading() => ViewLoading(previous: _form),
        ViewError(:final failure) => ViewError(failure, previous: _form),
        _ => ViewData(_form),
      });
    });
  }

  @override
  Future<void> close() {
    unawaited(_cooldownTimer?.cancel());
    return super.close();
  }
}
