// US01 (esc. 1, 4, 5), US03 (esc. 1, 2), TS01 (esc. 1, 2)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/widgets/auth_failure_text.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// `/login`: el correo institucional.
///
/// Cinco estados (docs/05): formulario vacío o con datos, enviando (botón con
/// progreso), error con su salida (el foco pasa al mensaje), bloqueado por 429
/// con cuenta regresiva en el botón, y éxito (navega a `/login/verify`).
///
/// Con [sessionExpired] (`?reason=expired`) muestra el aviso de sesión vencida
/// (US03); [onNoticeShown] avisa una vez que el aviso ya se mostró.
///
/// Debajo del botón, la nota de privacidad (solo se comparten los minutos de
/// llegada, nunca la ubicación) y, al pie, la línea legal, que abre el resumen
/// de términos y privacidad ([onOpenLegal]).
class LoginPage extends StatefulWidget {
  const LoginPage({
    this.sessionExpired = false,
    this.onNoticeShown,
    this.onOpenLegal,
    super.key,
  });

  final bool sessionExpired;
  final VoidCallback? onNoticeShown;

  /// Abre el resumen de términos y privacidad; sin él, la línea legal es solo
  /// texto.
  final VoidCallback? onOpenLegal;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _time = AppTimeFormatter();

  final TextEditingController _email = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChanged);
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onNoticeShown?.call(),
      );
    }
  }

  /// Al salir del campo se valida el formato (docs/05, regla 5).
  void _onFocusChanged() {
    if (!_emailFocus.hasFocus && mounted) {
      context.read<LoginCubit>().emailEditingFinished(_email.text);
    }
  }

  @override
  void dispose() {
    _emailFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<LoginCubit>();

    final theme = Theme.of(context);
    final muted = context.qaColors.onSurfaceMuted;

    return QaAuthScaffold(
      heading: l10n.iam_loginTitle,
      footer: _LegalLine(onTap: widget.onOpenLegal),
      children: [
        Text(
          l10n.iam_loginSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: QaSpacing.xl),
        BlocBuilder<LoginCubit, ViewState<LoginForm>>(
          builder: (context, state) {
            final loading = state is ViewLoading<LoginForm>;
            final form = switch (state) {
              ViewData(:final data) => data,
              ViewPartial(:final data) => data,
              ViewInitial() ||
              ViewEmpty() ||
              ViewLoading() ||
              ViewError() => const LoginForm(),
            };
            final blockedFor = form.blockedFor;

            // Un solo aviso a la vez, entre el campo y el botón: el error
            // del servidor o de la red tiene prioridad sobre el de sesión
            // vencida (US03).
            final notice =
                switch (state) {
                  ViewPartial() => QaBanner(
                    kind: QaBannerKind.error,
                    message: l10n.iam_rateLimited,
                    requestFocus: true,
                  ),
                  ViewError(:final failure) => _errorBanner(
                    l10n,
                    failure,
                    retry: () => cubit.submit(_email.text),
                  ),
                  ViewInitial() ||
                  ViewEmpty() ||
                  ViewLoading() ||
                  ViewData() => null,
                } ??
                (widget.sessionExpired
                    ? QaBanner(
                        kind: QaBannerKind.stale,
                        message: l10n.iam_sessionExpired,
                        requestFocus: true,
                      )
                    : null);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QaTextField(
                  label: l10n.iam_emailLabel,
                  hint: l10n.iam_emailHint,
                  helperText: l10n.iam_emailHelper,
                  controller: _email,
                  focusNode: _emailFocus,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  errorText: switch (form.emailError) {
                    EmailFieldError.empty => l10n.iam_emailErrorEmpty,
                    EmailFieldError.invalid => l10n.iam_emailErrorInvalid,
                    null => null,
                  },
                  onChanged: (_) => cubit.emailChanged(),
                  onSubmitted: cubit.submit,
                ),
                QaBannerSlot(banner: notice),
                const SizedBox(height: QaSpacing.xl),
                QaButton(
                  label: blockedFor == null
                      ? l10n.iam_sendCode
                      : l10n.iam_sendCodeIn(_time.formatCountdown(blockedFor)),
                  loadingLabel: l10n.iam_sendingCode,
                  isLoading: loading,
                  trailingIcon: blockedFor == null
                      ? Icons.arrow_forward_rounded
                      : null,
                  expand: true,
                  onPressed: blockedFor == null
                      ? () => cubit.submit(_email.text)
                      : null,
                ),
                const SizedBox(height: QaSpacing.lg),
                QaBanner(
                  kind: QaBannerKind.info,
                  icon: Icons.verified_user_outlined,
                  message: l10n.iam_privacyMinutes,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  QaBanner _errorBanner(
    AppLocalizations l10n,
    Failure failure, {
    required VoidCallback retry,
  }) {
    final text = loginFailureText(l10n, failure);
    return QaBanner(
      kind: QaBannerKind.error,
      message: text.message,
      requestFocus: true,
      actionLabel: text.canRetry ? l10n.iam_retry : null,
      onAction: text.canRetry ? retry : null,
    );
  }
}

/// «Al continuar aceptas los Términos y la Política de privacidad.»: una sola
/// línea, un solo objetivo táctil de 48 dp (los dos enlaces llevan al mismo
/// resumen) con las dos palabras subrayadas.
class _LegalLine extends StatelessWidget {
  const _LegalLine({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = context.qaColors.onSurfaceMuted;
    final base = theme.textTheme.bodySmall?.copyWith(color: muted);
    final link = base?.copyWith(
      color: context.qaColors.primary,
      decoration: TextDecoration.underline,
    );
    // El texto de cada idioma decide dónde van los dos enlaces.
    const termsKey = '\u0001';
    const privacyKey = '\u0002';
    final template = l10n.iam_legalIntro(termsKey, privacyKey);
    final spans = <InlineSpan>[];
    var rest = template;
    while (rest.isNotEmpty) {
      final t = rest.indexOf(termsKey);
      final p = rest.indexOf(privacyKey);
      final next = [t, p]
          .where((i) => i >= 0)
          .fold<int>(
            -1,
            (min, i) => min < 0 || i < min ? i : min,
          );
      if (next < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (next > 0) spans.add(TextSpan(text: rest.substring(0, next)));
      final isTerms = next == t;
      spans.add(
        TextSpan(
          text: isTerms ? l10n.iam_legalTerms : l10n.iam_legalPrivacy,
          style: onTap == null ? base : link,
        ),
      );
      rest = rest.substring(next + 1);
    }
    final text = Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: TextAlign.center,
    );
    if (onTap == null) return text;
    final spoken = l10n.iam_legalIntro(
      l10n.iam_legalTerms,
      l10n.iam_legalPrivacy,
    );
    return Semantics(
      container: true,
      button: true,
      label: spoken,
      hint: l10n.iam_legalOpen,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: QaRadii.controlRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: QaSpacing.minTapTarget),
          child: Center(child: text),
        ),
      ),
    );
  }
}
