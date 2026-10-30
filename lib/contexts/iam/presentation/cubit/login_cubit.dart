// US01 (esc. 1, 4, 5), TS01 (esc. 1, 2)
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/request_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_state.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// `/login`: pide el código de un solo uso para un correo.
///
/// - Valida el formato **al salir del campo** (y antes de enviar); un correo
///   inválido no llega al servidor.
/// - 403 (correo sin institución habilitada), 400, red caída y 5xx salen como
///   `ViewError(failure)`; la pantalla elige el texto según el tipo.
/// - 429: `ViewPartial` con una cuenta regresiva a partir de `retryAfter`; el
///   botón queda bloqueado hasta que llega a cero.
/// - `onCodeSent` lleva a `/login/verify` con el código pedido.
class LoginCubit extends Cubit<ViewState<LoginForm>> {
  LoginCubit({
    required this._requestOtp,
    required this._countdown,
    required this._onCodeSent,
  }) : super(const ViewData(LoginForm()));

  /// Espera si el servidor responde 429 sin `retryAfter`.
  static const Duration defaultRetryAfter = Duration(seconds: 60);

  final RequestOtp _requestOtp;
  final Countdown _countdown;
  final void Function(OtpChallenge challenge) _onCodeSent;

  StreamSubscription<Duration>? _blockTimer;

  bool get _isBusy => state is ViewLoading || state is ViewPartial;

  /// El campo perdió el foco: valida el formato.
  void emailEditingFinished(String raw) {
    if (_isBusy) return;
    emit(ViewData(LoginForm(emailError: _validate(raw))));
  }

  /// El usuario escribe: quita el error de formato o del servidor para poder
  /// reintentar. No toca un bloqueo por 429 ni una petición en curso.
  void emailChanged() {
    final current = state;
    final hasError =
        current is ViewError ||
        (current is ViewData<LoginForm> && current.data.emailError != null);
    if (hasError) emit(const ViewData(LoginForm()));
  }

  /// Pide el código. Sin efecto mientras hay una petición o un bloqueo.
  Future<void> submit(String raw) async {
    if (_isBusy) return;
    final error = _validate(raw);
    if (error != null) {
      emit(ViewData(LoginForm(emailError: error)));
      return;
    }

    emit(const ViewLoading());
    final result = await _requestOtp(raw);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(const ViewData(LoginForm()));
        _onCodeSent(value);
      case Err(failure: RateLimitedFailure(:final retryAfter)):
        _block(retryAfter ?? defaultRetryAfter);
      case Err(:final failure):
        emit(ViewError(failure));
    }
  }

  EmailFieldError? _validate(String raw) {
    if (raw.trim().isEmpty) return EmailFieldError.empty;
    return EmailAddress.create(raw).isSuccess ? null : EmailFieldError.invalid;
  }

  void _block(Duration duration) {
    unawaited(_blockTimer?.cancel());
    _blockTimer = _countdown.run(duration).listen((remaining) {
      if (isClosed) return;
      emit(
        remaining == Duration.zero
            ? const ViewData(LoginForm())
            : ViewPartial(LoginForm(blockedFor: remaining)),
      );
    });
  }

  @override
  Future<void> close() {
    unawaited(_blockTimer?.cancel());
    return super.close();
  }
}
