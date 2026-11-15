import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/router/app_router.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Acceso al panel de depuración (`/debug/mocks`) sobre todas las pantallas,
/// también antes de iniciar sesión. Solo existe en debug con mocks:
/// `QuadrappApp` no lo monta si `showDebugEntry` es `false`, y `bootstrap` lo
/// apaga en release.
class DebugEntry extends StatelessWidget {
  const DebugEntry({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        PositionedDirectional(
          top: 0,
          end: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(QaSpacing.xs),
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  button: true,
                  label: l10n.debug_open,
                  child: InkResponse(
                    onTap: () => router.push(debugMocksPath),
                    radius: QaSpacing.minTapTarget / 2,
                    child: SizedBox.square(
                      dimension: QaSpacing.minTapTarget,
                      child: Icon(
                        Icons.bug_report_outlined,
                        color: context.qaColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
