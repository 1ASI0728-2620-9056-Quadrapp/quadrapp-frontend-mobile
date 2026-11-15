// US01 (esc. 2, 3), US03 (esc. 3), TS01 (esc. 3, 4)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/widgets/auth_failure_text.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/widgets/masked_email.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// `/login/verify`: el código de un solo uso.
///
/// Cinco estados (docs/05): el campo del código, verificando (campos
/// bloqueados y botón con progreso), error con su salida (el foco pasa al
/// mensaje), "Reenviar código" con su cuenta regresiva, y éxito (el router
/// lleva a `/lots`).
///
/// Muestra a qué correo se envió (con la parte local oculta) y por cuánto
/// tiempo es válido ([validity]); [onChangeEmail] (la flecha de volver) vuelve
/// a `/login` para corregirlo. Al pie, un aviso: si la conexión se corta, el
/// código se conserva para reintentar.
class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({
    required this.validity,
    required this.onChangeEmail,
    super.key,
  });

  final Duration validity;
  final VoidCallback onChangeEmail;

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  static const _time = AppTimeFormatter();

  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Tras un error, deja el código seleccionado: lo siguiente que se escriba
  /// lo reemplaza entero.
  void _selectCode() => _code.selection = TextSelection(
    baseOffset: 0,
    extentOffset: _code.text.length,
  );

  VerifyForm? _formOf(ViewState<VerifyForm> state) => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    ViewInitial() || ViewEmpty() => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<VerifyCodeCubit>();

    return BlocListener<VerifyCodeCubit, ViewState<VerifyForm>>(
      listenWhen: (previous, current) {
        if (current is ViewError<VerifyForm> && previous != current) {
          return true;
        }
        final before = _formOf(previous)?.notice;
        return before != VerifyNotice.resent &&
            _formOf(current)?.notice == VerifyNotice.resent;
      },
      listener: (context, state) {
        if (state is ViewError<VerifyForm>) {
          _selectCode();
        } else {
          // Llegó un código nuevo: el anterior ya no sirve.
          _code.clear();
        }
      },
      child: BlocBuilder<VerifyCodeCubit, ViewState<VerifyForm>>(
        builder: (context, state) {
          final form = _formOf(state);
          return QaAuthScaffold(
            heading: l10n.iam_verifyHeading,
            topBarTitle: l10n.iam_verifyTitle,
            icon: Icons.mark_email_read_outlined,
            onBack: widget.onChangeEmail,
            backLabel: l10n.common_back,
            children: [
              if (form == null)
                QaLoadingRegion(
                  semanticLabel: l10n.iam_restoring,
                  child: const QaSkeleton.line(),
                )
              else
                _content(context, l10n, cubit, state, form),
            ],
          );
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    VerifyCodeCubit cubit,
    ViewState<VerifyForm> state,
    VerifyForm form,
  ) {
    final theme = Theme.of(context);
    final verifying = state is ViewLoading<VerifyForm>;
    final busy = verifying || form.resending;

    final banner = switch (state) {
      ViewError(:final failure) => _failureBanner(l10n, cubit, failure),
      ViewData(:final data) => _noticeBanner(l10n, data.notice),
      ViewInitial() || ViewEmpty() || ViewLoading() || ViewPartial() => null,
    };
    final muted = context.qaColors.onSurfaceMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sentTo(
          l10n,
          form.email.value,
          theme.textTheme.bodyLarge?.copyWith(color: muted),
          theme.textTheme.titleSmall?.copyWith(
            color: context.qaColors.onSurface,
          ),
        ),
        const SizedBox(height: QaSpacing.sm),
        Text(
          l10n.iam_verifyValidity(widget.validity.inMinutes),
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: QaSpacing.xl),
        QaOtpField(
          semanticLabel: l10n.iam_otpLabel,
          controller: _code,
          autofocus: true,
          enabled: !busy,
          isError: state is ViewError<VerifyForm>,
          onChanged: (value) {
            if (value.isNotEmpty) cubit.codeChanged();
          },
          onCompleted: cubit.submit,
        ),
        QaBannerSlot(banner: banner),
        const SizedBox(height: QaSpacing.xl),
        QaButton(
          label: l10n.iam_verifyAction,
          loadingLabel: l10n.iam_verifying,
          isLoading: verifying,
          expand: true,
          onPressed: busy ? null : () => cubit.submit(_code.text),
        ),
        const SizedBox(height: QaSpacing.sm),
        // «Reenviar código en 00:34»: un botón de texto centrado, de 48 dp.
        QaButton(
          label: form.resending
              ? l10n.iam_resending
              : form.resendBlockedFor == Duration.zero
              ? l10n.iam_resend
              : l10n.iam_resendIn(_time.formatCountdown(form.resendBlockedFor)),
          variant: QaButtonVariant.text,
          expand: true,
          onPressed: form.canResend && !verifying ? cubit.resend : null,
        ),
        const SizedBox(height: QaSpacing.lg),
        QaBanner(
          kind: QaBannerKind.offline,
          message: l10n.iam_verifyOfflineTip,
        ),
      ],
    );
  }

  /// «We sent a 6-digit code to **c•••@upc.edu.pe**.»: el correo con la parte
  /// local oculta y en semibold, ubicado donde lo ponga el texto de cada
  /// idioma. El lector de pantalla dice «c seguido de caracteres ocultos, en
  /// upc.edu.pe» en vez de leer los puntos.
  Widget _sentTo(
    AppLocalizations l10n,
    String email,
    TextStyle? style,
    TextStyle? strong,
  ) {
    final masked = maskEmail(email);
    final text = l10n.iam_verifySentTo(masked);
    final hint = emailHint(email);
    final spoken = l10n.iam_verifySentTo(
      l10n.iam_maskedSpoken(hint.first, hint.domain),
    );
    final at = text.indexOf(masked);
    final child = at < 0
        ? Text(text, style: style)
        : Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: text.substring(0, at)),
                TextSpan(text: masked, style: strong),
                TextSpan(text: text.substring(at + masked.length)),
              ],
            ),
          );
    return Semantics(label: spoken, excludeSemantics: true, child: child);
  }

  QaBanner _failureBanner(
    AppLocalizations l10n,
    VerifyCodeCubit cubit,
    Failure failure,
  ) {
    final text = verifyFailureText(l10n, failure);
    return QaBanner(
      kind: QaBannerKind.error,
      message: text.message,
      requestFocus: true,
      actionLabel: text.canRetry ? l10n.iam_retry : null,
      onAction: text.canRetry ? () => cubit.submit(_code.text) : null,
    );
  }

  QaBanner? _noticeBanner(AppLocalizations l10n, VerifyNotice? notice) =>
      switch (notice) {
        null => null,
        VerifyNotice.resent => QaBanner(
          kind: QaBannerKind.info,
          message: l10n.iam_noticeResent,
          requestFocus: true,
        ),
        VerifyNotice.resendNetworkError => QaBanner(
          kind: QaBannerKind.error,
          message: l10n.iam_noticeResendNetwork,
          requestFocus: true,
        ),
        VerifyNotice.resendRateLimited => QaBanner(
          kind: QaBannerKind.error,
          message: l10n.iam_rateLimited,
          requestFocus: true,
        ),
        VerifyNotice.resendFailed => QaBanner(
          kind: QaBannerKind.error,
          message: l10n.iam_noticeResendFailed,
          requestFocus: true,
        ),
      };
}
