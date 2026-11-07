// US13 (mapa de la llegada)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// El mapa de Google incrustado como `<iframe>` (`output=embed`, sin clave)
/// dentro de un WebView.
///
/// - Con [interactive] se puede mover y acercar; si no, es una vista previa
///   que deja pasar los toques a la tarjeta que la contiene.
/// - Solo carga la página del mapa: los enlaces de dentro («Ver mapa más
///   grande») no sacan al usuario de la app.
/// - Sin conexión, o donde no hay WebView (pruebas), muestra un aviso en su
///   lugar, sin errores técnicos.
class EmbeddedMap extends StatefulWidget {
  const EmbeddedMap({
    required this.uri,
    required this.semanticLabel,
    this.interactive = false,
    super.key,
  });

  final Uri uri;
  final String semanticLabel;
  final bool interactive;

  @override
  State<EmbeddedMap> createState() => _EmbeddedMapState();
}

class _EmbeddedMapState extends State<EmbeddedMap> {
  WebViewController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) return;
    final controller = WebViewController();
    _controller = controller;
    unawaited(_configure(controller));
  }

  Future<void> _configure(WebViewController controller) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.transparent);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        // La página propia se carga como `about:blank`; el iframe va en un
        // marco interno. Cualquier otra navegación del marco principal (un
        // enlace del mapa) se bloquea.
        onNavigationRequest: (request) =>
            !request.isMainFrame || request.url.startsWith('about:')
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        onWebResourceError: (error) {
          if ((error.isForMainFrame ?? false) && mounted) {
            setState(() => _failed = true);
          }
        },
      ),
    );
    await _load();
  }

  @override
  void didUpdateWidget(EmbeddedMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _failed = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async => _controller?.loadHtmlString(_page(widget.uri));

  static String _page(Uri uri) {
    final src = const HtmlEscape(HtmlEscapeMode.attribute).convert('$uri');
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
html, body { margin: 0; height: 100%; overflow: hidden; }
iframe { border: 0; width: 100%; height: 100%; }
</style>
</head>
<body>
<iframe src="$src" allowfullscreen
  referrerpolicy="no-referrer-when-downgrade"></iframe>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || _failed) {
      return _MapUnavailable(semanticLabel: widget.semanticLabel);
    }
    final map = WebViewWidget(
      controller: controller,
      gestureRecognizers: widget.interactive
          ? const {
              Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
            }
          : const {},
    );
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: widget.interactive ? map : IgnorePointer(child: map),
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(QaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.map_outlined,
                  size: 32,
                  color: colors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: QaSpacing.sm),
              Text(
                l10n.map_unavailable,
                textAlign: TextAlign.center,
                semanticsLabel: '$semanticLabel. ${l10n.map_unavailable}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
