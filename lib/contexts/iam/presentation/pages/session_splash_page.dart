// US01 (esc. 6)
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Lo que se ve mientras se lee la sesión guardada al abrir la app: un
/// skeleton, no un spinner de pantalla completa. No ofrece acciones: la
/// lectura es local y termina en milisegundos.
class SessionSplashPage extends StatelessWidget {
  const SessionSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(QaSpacing.xl),
          child: QaLoadingRegion(
            semanticLabel: l10n.iam_restoring,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QaSkeleton(width: 160, height: 32),
                SizedBox(height: QaSpacing.lg),
                QaSkeleton.line(),
                SizedBox(height: QaSpacing.sm),
                QaSkeleton.line(width: 220),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
