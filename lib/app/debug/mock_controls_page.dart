import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_page.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/list_parking_lots.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Panel de depuración (`/debug/mocks`): los interruptores de [MockControls]
/// para probar cada estado desde el emulador sin tocar código.
///
/// **Solo existe en debug con mocks:** `createRouterFrom` no registra la ruta
/// y `bootstrap` no monta el acceso si no es así; una prueba lo comprueba.
///
/// Los mocks no pasan por el `AuthInterceptor`, así que dos botones recorren el
/// camino real con los casos de uso: "Expirar la sesión ahora" pide el refresh
/// (con el interruptor de sesión expirada, el servidor lo rechaza y la app
/// cierra la sesión) y "Llamar a un endpoint protegido" lista estacionamientos
/// para ver el efecto de los demás interruptores.
class MockControlsPage extends StatefulWidget {
  const MockControlsPage({
    required this.controls,
    required this.refreshSession,
    required this.listParkingLots,
    required this.resetData,
    super.key,
  });

  final MockControls controls;
  final RefreshSession refreshSession;
  final ListParkingLots listParkingLots;

  /// Vuelve a los datos de la semilla (`MockWorld.reset`).
  final VoidCallback resetData;

  @override
  State<MockControlsPage> createState() => _MockControlsPageState();
}

class _MockControlsPageState extends State<MockControlsPage> {
  String? _result;
  bool _busy = false;

  MockControls get _controls => widget.controls;

  Future<void> _run(
    Future<String> Function(AppLocalizations l10n) action,
  ) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final text = await action(l10n);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = text;
    });
  }

  Future<String> _expireNow(AppLocalizations l10n) async {
    final result = await widget.refreshSession(const NoParams());
    return switch (result) {
      Success() => l10n.debug_resultRefreshed,
      Err(:final failure) => l10n.debug_resultFailure(
        failure.runtimeType.toString(),
      ),
    };
  }

  Future<String> _probe(AppLocalizations l10n) async {
    final result = await widget.listParkingLots(const NoParams());
    return switch (result) {
      Success(:final value) => l10n.debug_resultOk(value.length),
      Err(:final failure) => l10n.debug_resultFailure(
        failure.runtimeType.toString(),
      ),
    };
  }

  Future<String> _reset(AppLocalizations l10n) async {
    widget.resetData();
    return l10n.debug_resultReset;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget toggle({
      required String title,
      required String help,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => SwitchListTile(
      title: Text(title),
      subtitle: Text(help),
      value: value,
      onChanged: (next) => setState(() => onChanged(next)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.debug_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QaSpacing.lg),
          children: [
            Text(l10n.debug_credentials, style: theme.textTheme.bodyMedium),
            const SizedBox(height: QaSpacing.sm),
            toggle(
              title: l10n.debug_forceNetworkError,
              help: l10n.debug_forceNetworkErrorHelp,
              value: _controls.forceNetworkError,
              onChanged: (value) => _controls.forceNetworkError = value,
            ),
            toggle(
              title: l10n.debug_realtimeOutage,
              help: l10n.debug_realtimeOutageHelp,
              value: _controls.realtimeOutage.value,
              onChanged: (value) => _controls.realtimeOutage.value = value,
            ),
            const SizedBox(height: QaSpacing.sm),
            _LocationPermissionPicker(
              value: _controls.locationPermission,
              onChanged: (value) => setState(() {
                _controls.locationPermission = value;
                _controls.locationPromptDenials = 0;
              }),
            ),
            toggle(
              title: l10n.debug_denyLocationPrompt,
              help: l10n.debug_denyLocationPromptHelp,
              value: _controls.denyLocationPrompt,
              onChanged: (value) => _controls.denyLocationPrompt = value,
            ),
            toggle(
              title: l10n.debug_simulateTrip,
              help: l10n.debug_simulateTripHelp,
              value: _controls.simulateTrip,
              onChanged: (value) => _controls.simulateTrip = value,
            ),
            toggle(
              title: l10n.debug_heavyTraffic,
              help: l10n.debug_heavyTrafficHelp,
              value: _controls.heavyTraffic,
              onChanged: (value) => _controls.heavyTraffic = value,
            ),
            toggle(
              title: l10n.debug_routesOutage,
              help: l10n.debug_routesOutageHelp,
              value: _controls.routesOutage,
              onChanged: (value) => _controls.routesOutage = value,
            ),
            toggle(
              title: l10n.debug_force401,
              help: l10n.debug_force401Help,
              value: _controls.force401,
              onChanged: (value) => _controls.force401 = value,
            ),
            toggle(
              title: l10n.debug_force429,
              help: l10n.debug_force429Help,
              value: _controls.force429,
              onChanged: (value) => _controls.force429 = value,
            ),
            toggle(
              title: l10n.debug_sessionExpired,
              help: l10n.debug_sessionExpiredHelp,
              value: _controls.sessionExpired,
              onChanged: (value) => _controls.sessionExpired = value,
            ),
            toggle(
              title: l10n.debug_forceConsole403,
              help: l10n.debug_forceConsole403Help,
              value: _controls.forceConsole403,
              onChanged: (value) => _controls.forceConsole403 = value,
            ),
            toggle(
              title: l10n.debug_forceConsolePartial,
              help: l10n.debug_forceConsolePartialHelp,
              value: _controls.forceConsolePartial,
              onChanged: (value) => _controls.forceConsolePartial = value,
            ),
            toggle(
              title: l10n.debug_forceDeviceRegisterFailure,
              help: l10n.debug_forceDeviceRegisterFailureHelp,
              value: _controls.forceDeviceRegisterFailure,
              onChanged: (value) =>
                  _controls.forceDeviceRegisterFailure = value,
            ),
            const SizedBox(height: QaSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                l10n.debug_actions,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: QaSpacing.sm),
            QaButton(
              label: l10n.debug_expireNow,
              variant: QaButtonVariant.tonal,
              expand: true,
              isLoading: _busy,
              onPressed: () => _run(_expireNow),
            ),
            const SizedBox(height: QaSpacing.sm),
            QaButton(
              label: l10n.debug_probe,
              variant: QaButtonVariant.tonal,
              expand: true,
              isLoading: _busy,
              onPressed: () => _run(_probe),
            ),
            const SizedBox(height: QaSpacing.sm),
            QaButton(
              label: l10n.debug_resetData,
              variant: QaButtonVariant.tonal,
              expand: true,
              isLoading: _busy,
              onPressed: () => _run(_reset),
            ),
            if (_result != null) ...[
              const SizedBox(height: QaSpacing.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${l10n.debug_resultLabel}: $_result',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: QaSpacing.lg),
            QaButton(
              label: l10n.gallery_open,
              variant: QaButtonVariant.text,
              expand: true,
              onPressed: () => context.push(galleryPath),
            ),
          ],
        ),
      ),
    );
  }
}

/// El permiso de ubicación del teléfono simulado: cuatro estados para probar el
/// ETA automático, la explicación previa y el modo manual.
class _LocationPermissionPicker extends StatelessWidget {
  const _LocationPermissionPicker({
    required this.value,
    required this.onChanged,
  });

  final LocationPermissionStatus value;
  final ValueChanged<LocationPermissionStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String label(LocationPermissionStatus status) => switch (status) {
      LocationPermissionStatus.granted => l10n.debug_locationGranted,
      LocationPermissionStatus.denied => l10n.debug_locationDenied,
      LocationPermissionStatus.deniedForever =>
        l10n.debug_locationDeniedForever,
      LocationPermissionStatus.serviceDisabled => l10n.debug_locationOff,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.debug_locationPermission,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: QaSpacing.sm),
          Wrap(
            spacing: QaSpacing.sm,
            runSpacing: QaSpacing.sm,
            children: [
              for (final status in LocationPermissionStatus.values)
                ChoiceChip(
                  label: Text(label(status)),
                  selected: value == status,
                  onSelected: (_) => onChanged(status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
