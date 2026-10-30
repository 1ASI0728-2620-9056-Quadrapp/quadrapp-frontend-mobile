// US01 (esc. 3, 5), TS01
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El texto de un error y si tiene sentido ofrecer "Reintentar" (una falla
/// transitoria sí; un 403 o un código incorrecto no se arreglan reintentando
/// lo mismo).
typedef AuthFailureText = ({String message, bool canRetry});

/// Texto de un error al pedir el código (`/login`). Nunca usa
/// `failure.message`: elige el texto por el tipo de falla.
AuthFailureText loginFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      ForbiddenFailure() => (message: l10n.iam_errorForbidden, canRetry: false),
      ValidationFailure() => (
        message: l10n.iam_errorEmailFormat,
        canRetry: false,
      ),
      NetworkFailure() => (message: l10n.iam_errorNetwork, canRetry: true),
      _ => (message: l10n.iam_errorGeneric, canRetry: true),
    };

/// Texto de un error al verificar el código (`/login/verify`).
AuthFailureText verifyFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      UnauthorizedFailure() => (
        message: l10n.iam_errorCodeInvalid,
        canRetry: false,
      ),
      ValidationFailure() => (
        message: l10n.iam_errorCodeIncomplete,
        canRetry: false,
      ),
      NetworkFailure() => (message: l10n.iam_errorNetwork, canRetry: true),
      _ => (message: l10n.iam_errorGeneric, canRetry: true),
    };
