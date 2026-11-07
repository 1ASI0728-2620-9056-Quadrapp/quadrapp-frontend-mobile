import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/debug/debug_entry.dart';
import 'package:quadrapp_mobile/app/l10n/locale_resolution.dart';
import 'package:quadrapp_mobile/app/theme/app_theme.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Raíz de la aplicación: `MaterialApp.router` con tema (claro y oscuro,
/// según el sistema) e i18n.
///
/// [locale] es la preferencia guardada del usuario (fase 6); sin ella, la app
/// se muestra en inglés sin importar el idioma del teléfono.
///
/// Con [showDebugEntry] (solo debug con mocks) agrega, sobre todas las
/// pantallas, el acceso al panel de depuración.
class QuadrappApp extends StatelessWidget {
  const QuadrappApp({
    required this.router,
    this.locale,
    this.showDebugEntry = false,
    super.key,
  });

  final GoRouter router;
  final Locale? locale;
  final bool showDebugEntry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).common_appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: resolveLocale(locale),
      builder: showDebugEntry
          ? (context, child) =>
                DebugEntry(router: router, child: child ?? const SizedBox())
          : null,
    );
  }
}
