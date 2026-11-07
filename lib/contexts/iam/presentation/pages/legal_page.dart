// US01 (el aviso legal del acceso), US28 (términos y privacidad)
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// `/legal`: un resumen corto de qué datos trata Quadrapp y cuáles nunca recibe
/// (la ubicación del conductor no sale del teléfono: solo viajan los minutos
/// de llegada). Se abre desde la línea legal del acceso y desde la cuenta, con
/// o sin sesión.
///
/// **No es el texto legal:** dice, en una nota al final, que los Términos y la
/// Política de privacidad completos se publican en el sitio web (US28). Solo
/// afirma lo que la app hace de verdad (docs/01 y las reglas de dominio).
class LegalPage extends StatelessWidget {
  const LegalPage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;

    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.only(top: QaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: QaSpacing.sm),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );

    return QaTabPage(
      title: l10n.legal_title,
      onBack: onBack,
      backLabel: l10n.common_back,
      children: [
        Text(
          l10n.legal_intro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
        section(l10n.legal_receiveTitle, l10n.legal_receiveBody),
        section(l10n.legal_neverTitle, l10n.legal_neverBody),
        section(l10n.legal_signOutTitle, l10n.legal_signOutBody),
        const SizedBox(height: QaSpacing.xl),
        QaBanner(
          kind: QaBannerKind.note,
          icon: Icons.info_outline_rounded,
          message: l10n.legal_note,
        ),
      ],
    );
  }
}
